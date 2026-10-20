{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 18: Construção do Componente Gerador de Cadastros (TAutoFormBuilder)
  Componente: TDlpAutoFormBuilder
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL
  Descrição: Contêiner avançado para geração algorítmica de telas CRUD na VCL.
             Inspeciona metadados de TDataSet/FireDAC, distribui labels e controles
             em grid responsivo e efetua o registro de persistência no DFM.
==============================================================================}
unit DlpAutoFormBuilder;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.DBCtrls,
  Data.DB,
  DlpFieldSchemaInspector,
  DlpDBBasicControls,
  DlpDBLookupTagBox;

type
  /// <summary>
  /// Posicionamento do rótulo textual em relação ao controle de edição.
  /// </summary>
  TDlpLabelPosition = (lpAbove, lpLeft);

  /// <summary>
  /// Contêiner de formulário gerador de interfaces CRUD automáticas baseadas em dados.
  /// </summary>
  TDlpAutoFormBuilder = class(TScrollBox)
  private
    FDataSource: TDataSource;
    FColumnsCount: Integer;
    FHorizontalSpacing: Integer;
    FVerticalSpacing: Integer;
    FLabelPosition: TDlpLabelPosition;
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

    /// <summary>
    /// Materializa todos os componentes visuais correspondentes ao esquema do dataset.
    /// </summary>
    procedure GenerateFormLayout;

    /// <summary>
    /// Destrói e limpa todos os componentes gerados previamente.
    /// </summary>
    procedure ClearGeneratedControls;

    /// <summary>
    /// Quantidade de controles instanciados pelo gerador.
    /// </summary>
    function GeneratedCount: Integer;
  published
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property ColumnsCount: Integer read FColumnsCount write SetColumnsCount default 2;
    property HorizontalSpacing: Integer read FHorizontalSpacing write FHorizontalSpacing default 16;
    property VerticalSpacing: Integer read FVerticalSpacing write FVerticalSpacing default 12;
    property LabelPosition: TDlpLabelPosition read FLabelPosition write FLabelPosition default lpAbove;
    property ShowRequiredAsterisk: Boolean read FShowRequiredAsterisk write FShowRequiredAsterisk default True;

    { Propriedades herdadas publicadas para integração visual }
    property Align;
    property Anchors;
    property AutoScroll default True;
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
  RegisterComponents('Delphi Component Engineering', [TDlpAutoFormBuilder]);
end;

{ TDlpAutoFormBuilder }

constructor TDlpAutoFormBuilder.Create(AOwner: TComponent);
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

destructor TDlpAutoFormBuilder.Destroy;
begin
  ClearGeneratedControls;
  FreeAndNil(FGeneratedControls);
  inherited Destroy;
end;

procedure TDlpAutoFormBuilder.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDataSource) then
    FDataSource := nil;
end;

procedure TDlpAutoFormBuilder.SetDataSource(const AValue: TDataSource);
begin
  if FDataSource <> AValue then
  begin
    FDataSource := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
  end;
end;

procedure TDlpAutoFormBuilder.SetColumnsCount(const AValue: Integer);
begin
  if (AValue >= 1) and (AValue <= 4) and (FColumnsCount <> AValue) then
    FColumnsCount := AValue;
end;

function TDlpAutoFormBuilder.GetOwnerForm: TCustomForm;
begin
  Result := GetParentForm(Self);
  if (Result = nil) and (Owner is TCustomForm) then
    Result := TCustomForm(Owner);
end;

function TDlpAutoFormBuilder.SanitizeComponentName(const ABase: string): string;
var
  i: Integer;
  Candidate: string;
begin
  Candidate := '';
  for i := 1 to Length(ABase) do
  begin
    if CharInSet(ABase[i], ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      Candidate := Candidate + ABase[i];
  end;

  if (Candidate <> '') and CharInSet(Candidate[1], ['0'..'9']) then
    Candidate := 'Fld_' + Candidate;

  Result := Candidate;
end;

procedure TDlpAutoFormBuilder.ClearGeneratedControls;
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

function TDlpAutoFormBuilder.GeneratedCount: Integer;
begin
  Result := FGeneratedControls.Count;
end;

procedure TDlpAutoFormBuilder.GenerateFormLayout;
var
  Inspector: TDlpFieldSchemaInspector;
  Schemas: TDlpFieldSchemaArray;
  TargetForm: TCustomForm;
  i, ColIndex, RowTop, CurLeft, UsableWidth, ColWidth: Integer;
  CtrlLabel: TLabel;
  NewEdit: TDBEdit;
  NewNumEdit: TDlpDBNumberEdit;
  NewCheck: TDBCheckBox;
  NewMemo: TDBMemo;
  LabelHeight, CtrlHeight: Integer;
  SanitizedName: string;
  EffectiveOwner: TComponent;
begin
  if (FDataSource = nil) or (FDataSource.DataSet = nil) then
    raise Exception.Create('TDlpAutoFormBuilder: DataSource ou DataSet não configurado.');

  TargetForm := GetOwnerForm;
  if TargetForm <> nil then
    EffectiveOwner := TargetForm
  else
    EffectiveOwner := Self;

  ClearGeneratedControls;

  Inspector := TDlpFieldSchemaInspector.Create(nil);
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

      // Criação da TLabel descritiva
      CtrlLabel := TLabel.Create(EffectiveOwner);
      CtrlLabel.Parent := Self;
      CtrlLabel.Left := CurLeft;
      CtrlLabel.Top := RowTop;
      CtrlLabel.Caption := Schemas[i].DisplayLabel;
      if Schemas[i].Required and FShowRequiredAsterisk then
        CtrlLabel.Caption := CtrlLabel.Caption + ' *';

      if EffectiveOwner <> nil then
        CtrlLabel.Name := EffectiveOwner.FindUniqueName('lbl' + SanitizedName);

      FGeneratedControls.Add(CtrlLabel);

      CtrlHeight := 24;
      case Schemas[i].RecommendedControl of
        ckNumberEdit:
        begin
          NewNumEdit := TDlpDBNumberEdit.Create(EffectiveOwner);
          NewNumEdit.Parent := Self;
          NewNumEdit.Left := CurLeft;
          NewNumEdit.Top := RowTop + LabelHeight + 2;
          NewNumEdit.Width := ColWidth;
          NewNumEdit.DataSource := FDataSource;
          NewNumEdit.DataField := Schemas[i].FieldName;

          if EffectiveOwner <> nil then
            NewNumEdit.Name := EffectiveOwner.FindUniqueName('edt' + SanitizedName);

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
            NewCheck.Name := EffectiveOwner.FindUniqueName('chk' + SanitizedName);

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
            NewMemo.Name := EffectiveOwner.FindUniqueName('mem' + SanitizedName);

          FGeneratedControls.Add(NewMemo);
        end;

        else
        begin
          NewEdit := TDBEdit.Create(EffectiveOwner);
          NewEdit.Parent := Self;
          NewEdit.Left := CurLeft;
          NewEdit.Top := RowTop + LabelHeight + 2;
          NewEdit.Width := ColWidth;
          NewEdit.DataSource := FDataSource;
          NewEdit.DataField := Schemas[i].FieldName;

          if EffectiveOwner <> nil then
            NewEdit.Name := EffectiveOwner.FindUniqueName('edt' + SanitizedName);

          FGeneratedControls.Add(NewEdit);
        end;
      end;

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
