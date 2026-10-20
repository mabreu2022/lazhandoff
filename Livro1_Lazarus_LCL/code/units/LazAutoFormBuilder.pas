{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 18: Construção do Componente Gerador de Cadastros (TAutoFormBuilder)
  Componente: TLazAutoFormBuilder
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Contêiner gerador algorítmico de formulários de cadastro CRUD.
             Lê o esquema do TDataSet, instancia dinamicamente Labels e
             controles DB-Aware correspondentes, distribui em grid responsivo
             e persiste os componentes gerados na árvore LFM da IDE.
==============================================================================}
unit LazAutoFormBuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Forms,
  StdCtrls,
  ExtCtrls,
  DBCtrls,
  DB,
  LazFieldSchemaInspector,
  LazDBBasicControls,
  LazDBLookupTagBox;

type
  { Posicionamento semântico do rótulo (Label) em relação ao controle }
  TLazLabelPosition = (lpAbove, lpLeft);

  {============================================================================
    Classe: TLazAutoFormBuilder
    Contêiner visual para geração determinística de telas de cadastro
  ============================================================================}
  TLazAutoFormBuilder = class(TScrollBox)
  private
    FDataSource: TDataSource;
    FColumnsCount: Integer;
    FHorizontalSpacing: Integer;
    FVerticalSpacing: Integer;
    FLabelPosition: TLazLabelPosition;
    FShowRequiredAsterisk: Boolean;
    FGeneratedControls: TList;

    procedure SetDataSource(const AValue: TDataSource);
    procedure SetColumnsCount(const AValue: Integer);
    function GetOwnerForm: TCustomForm;
    function SanitizeComponentName(const ABase: string): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos principais do motor de geração }
    procedure GenerateFormLayout;
    procedure ClearGeneratedControls;
    function GeneratedCount: Integer;
  published
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property ColumnsCount: Integer read FColumnsCount write SetColumnsCount default 2;
    property HorizontalSpacing: Integer read FHorizontalSpacing write FHorizontalSpacing default 16;
    property VerticalSpacing: Integer read FVerticalSpacing write FVerticalSpacing default 12;
    property LabelPosition: TLazLabelPosition read FLabelPosition write FLabelPosition default lpAbove;
    property ShowRequiredAsterisk: Boolean read FShowRequiredAsterisk write FShowRequiredAsterisk default True;

    { Propriedades herdadas publicadas }
    property Align;
    property Anchors;
    property AutoScroll default True;
    property BorderSpacing;
    property BorderStyle default bsSingle;
    property Color default clWindow;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property TabOrder;
    property TabStop;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazAutoFormBuilder]);
end;

{ TLazAutoFormBuilder }

constructor TLazAutoFormBuilder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoScroll := True;
  BorderStyle := bsSingle;
  Color := clWindow;
  FColumnsCount := 2;
  FHorizontalSpacing := 16;
  FVerticalSpacing := 12;
  FLabelPosition := lpAbove;
  FShowRequiredAsterisk := True;
  FGeneratedControls := TList.Create;
  Width := 560;
  Height := 420;
end;

destructor TLazAutoFormBuilder.Destroy;
begin
  ClearGeneratedControls;
  FreeAndNil(FGeneratedControls);
  inherited Destroy;
end;

procedure TLazAutoFormBuilder.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDataSource) then
    FDataSource := nil;
end;

procedure TLazAutoFormBuilder.SetDataSource(const AValue: TDataSource);
begin
  if FDataSource <> AValue then
  begin
    FDataSource := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
  end;
end;

procedure TLazAutoFormBuilder.SetColumnsCount(const AValue: Integer);
begin
  if (AValue >= 1) and (AValue <= 4) and (FColumnsCount <> AValue) then
    FColumnsCount := AValue;
end;

function TLazAutoFormBuilder.GetOwnerForm: TCustomForm;
begin
  Result := GetParentForm(Self);
  if (Result = nil) and (Owner is TCustomForm) then
    Result := TCustomForm(Owner);
end;

function TLazAutoFormBuilder.SanitizeComponentName(const ABase: string): string;
var
  i: Integer;
  Candidate: string;
begin
  Candidate := '';
  for i := 1 to Length(ABase) do
  begin
    if ABase[i] in ['a'..'z', 'A'..'Z', '0'..'9', '_'] then
      Candidate := Candidate + ABase[i];
  end;

  if (Candidate <> '') and (Candidate[1] in ['0'..'9']) then
    Candidate := 'Fld_' + Candidate;

  Result := Candidate;
end;

function FindUniqueName(AOwner: TComponent; const ABaseName: string): string;
var
  Idx: Integer;
begin
  Result := ABaseName;
  if AOwner = nil then Exit;
  Idx := 1;
  while AOwner.FindComponent(Result) <> nil do
  begin
    Inc(Idx);
    Result := Format('%s_%d', [ABaseName, Idx]);
  end;
end;

procedure TLazAutoFormBuilder.ClearGeneratedControls;
var
  i: Integer;
  Obj: TObject;
begin
  for i := FGeneratedControls.Count - 1 downto 0 do
  begin
    Obj := TObject(FGeneratedControls[i]);
    if Obj is TComponent then
      TComponent(Obj).Free;
  end;
  FGeneratedControls.Clear;
end;

function TLazAutoFormBuilder.GeneratedCount: Integer;
begin
  Result := FGeneratedControls.Count;
end;

procedure TLazAutoFormBuilder.GenerateFormLayout;
var
  Inspector: TLazFieldSchemaInspector;
  Schemas: TLazFieldSchemaArray;
  TargetForm: TCustomForm;
  i, ColIndex, RowTop, CurLeft, UsableWidth, ColWidth: Integer;
  CtrlLabel: TLabel;
  NewEdit: TDBEdit;
  NewNumEdit: TLazDBNumberEdit;
  NewCheck: TDBCheckBox;
  NewMemo: TDBMemo;
  LabelHeight, CtrlHeight: Integer;
  SanitizedName: string;
  EffectiveOwner: TComponent;
begin
  if (FDataSource = nil) or (FDataSource.DataSet = nil) then
    raise Exception.Create('TLazAutoFormBuilder: DataSource ou DataSet não configurado.');

  TargetForm := GetOwnerForm;
  if TargetForm <> nil then
    EffectiveOwner := TargetForm
  else
    EffectiveOwner := Self;

  ClearGeneratedControls;

  Inspector := TLazFieldSchemaInspector.Create(nil);
  try
    Inspector.DataSet := FDataSource.DataSet;
    Schemas := Inspector.InspectSchema;
  finally
    Inspector.Free;
  end;

  if Length(Schemas) = 0 then
    Exit;

  LabelHeight := 18;
  ColIndex := 0;
  RowTop := FVerticalSpacing;
  UsableWidth := ClientWidth - (FHorizontalSpacing * (FColumnsCount + 1));
  if UsableWidth < 200 then
    UsableWidth := 200;
  ColWidth := UsableWidth div FColumnsCount;

  DisableAlign;
  try
    for i := 0 to High(Schemas) do
    begin
      CurLeft := FHorizontalSpacing + (ColIndex * (ColWidth + FHorizontalSpacing));
      SanitizedName := SanitizeComponentName(Schemas[i].FieldName);

      // Criação e posicionamento da TLabel descritiva
      CtrlLabel := TLabel.Create(EffectiveOwner);
      CtrlLabel.Parent := Self;
      CtrlLabel.Left := CurLeft;
      CtrlLabel.Top := RowTop;
      CtrlLabel.Caption := Schemas[i].DisplayLabel;
      if Schemas[i].Required and FShowRequiredAsterisk then
        CtrlLabel.Caption := CtrlLabel.Caption + ' *';

      if EffectiveOwner <> nil then
        CtrlLabel.Name := FindUniqueName(EffectiveOwner, 'lbl' + SanitizedName);

      FGeneratedControls.Add(CtrlLabel);

      // Determinação da altura do controle e instanciação específica
      CtrlHeight := 24;
      case Schemas[i].RecommendedControl of
        ckNumberEdit:
        begin
          NewNumEdit := TLazDBNumberEdit.Create(EffectiveOwner);
          NewNumEdit.Parent := Self;
          NewNumEdit.Left := CurLeft;
          NewNumEdit.Top := RowTop + LabelHeight + 2;
          NewNumEdit.Width := ColWidth;
          NewNumEdit.DataSource := FDataSource;
          NewNumEdit.DataField := Schemas[i].FieldName;

          if EffectiveOwner <> nil then
            NewNumEdit.Name := FindUniqueName(EffectiveOwner, 'edt' + SanitizedName);

          FGeneratedControls.Add(NewNumEdit);
        end;

        ckCheckBox:
        begin
          NewCheck := TDBCheckBox.Create(EffectiveOwner);
          NewCheck.Parent := Self;
          NewCheck.Left := CurLeft;
          NewCheck.Top := RowTop + LabelHeight + 2;
          NewCheck.Width := ColWidth;
          NewCheck.Caption := Schemas[i].DisplayLabel;
          NewCheck.DataSource := FDataSource;
          NewCheck.DataField := Schemas[i].FieldName;
          NewCheck.ValueChecked := 'True';
          NewCheck.ValueUnchecked := 'False';

          if EffectiveOwner <> nil then
            NewCheck.Name := FindUniqueName(EffectiveOwner, 'chk' + SanitizedName);

          FGeneratedControls.Add(NewCheck);
        end;

        ckMemo:
        begin
          CtrlHeight := 64;
          NewMemo := TDBMemo.Create(EffectiveOwner);
          NewMemo.Parent := Self;
          NewMemo.Left := CurLeft;
          NewMemo.Top := RowTop + LabelHeight + 2;
          NewMemo.Width := ColWidth;
          NewMemo.Height := CtrlHeight;
          NewMemo.DataSource := FDataSource;
          NewMemo.DataField := Schemas[i].FieldName;
          NewMemo.ScrollBars := ssVertical;

          if EffectiveOwner <> nil then
            NewMemo.Name := FindUniqueName(EffectiveOwner, 'mem' + SanitizedName);

          FGeneratedControls.Add(NewMemo);
        end;

        else
        begin
          // ckTextEdit, ckDatePicker e outros controles padrão
          NewEdit := TDBEdit.Create(EffectiveOwner);
          NewEdit.Parent := Self;
          NewEdit.Left := CurLeft;
          NewEdit.Top := RowTop + LabelHeight + 2;
          NewEdit.Width := ColWidth;
          NewEdit.DataSource := FDataSource;
          NewEdit.DataField := Schemas[i].FieldName;

          if EffectiveOwner <> nil then
            NewEdit.Name := FindUniqueName(EffectiveOwner, 'edt' + SanitizedName);

          FGeneratedControls.Add(NewEdit);
        end;
      end;

      // Avança a coluna ou quebra a linha
      Inc(ColIndex);
      if ColIndex >= FColumnsCount then
      begin
        ColIndex := 0;
        Inc(RowTop, LabelHeight + CtrlHeight + FVerticalSpacing);
      end;
    end;
  finally
    EnableAlign;
  end;
end;

end.
