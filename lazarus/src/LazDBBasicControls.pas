{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 14: Controles DB-Aware Básicos de Exibição e Edição
  Unidade: LazDBBasicControls (TLazDBBadgeLabel e TLazDBNumberEdit)
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Implementação de dois controles DB-Aware de alto padrão:
             1. TLazDBBadgeLabel: Rótulo de status com formatação condicional.
             2. TLazDBNumberEdit: Editor numérico/monetário alinhado à direita,
                com máscara dinâmica e entrada automática em modo dsEdit.
==============================================================================}
unit LazDBBasicControls;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  StdCtrls,
  Forms,
  DB,
  DBCtrls,
  LCLType,
  LCLIntf;

type
  {============================================================================
    Controle 1: TLazDBBadgeLabel (Exibição Condicional de Status)
  ============================================================================}
  TLazDBBadgeLabel = class(TGraphicControl)
  private
    FDataLink: TFieldDataLink;
    FActiveColor: TColor;
    FInactiveColor: TColor;
    FWarningColor: TColor;
    FDefaultColor: TColor;
    FBorderRadius: Integer;

    function GetDataSource: TDataSource;
    procedure SetDataSource(const AValue: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const AValue: string);
    function GetField: TField;

    procedure DataChange(Sender: TObject);
    function ResolveBadgeColor(const AText: string): TColor;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property BorderRadius: Integer read FBorderRadius write FBorderRadius default 6;
    property ActiveColor: TColor read FActiveColor write FActiveColor default $0000C853;
    property InactiveColor: TColor read FInactiveColor write FInactiveColor default $00555555;
    property WarningColor: TColor read FWarningColor write FWarningColor default $0000A5FF;
    property DefaultColor: TColor read FDefaultColor write FDefaultColor default $002A2A2A;

    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property ParentFont;
    property Visible;
    property OnClick;
  end;

  {============================================================================
    Controle 2: TLazDBNumberEdit (Edição Numérica e Monetária DB-Aware)
  ============================================================================}
  TLazDBNumberEdit = class(TCustomEdit)
  private
    FDataLink: TFieldDataLink;
    FDecimals: Integer;
    FCurrencySymbol: string;
    FFocusedState: Boolean;

    function GetDataSource: TDataSource;
    procedure SetDataSource(const AValue: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const AValue: string);
    function GetField: TField;

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure ActiveChange(Sender: TObject);
    procedure FormatDisplay;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property Decimals: Integer read FDecimals write FDecimals default 2;
    property CurrencySymbol: string read FCurrencySymbol write FCurrencySymbol;

    property Align;
    property Alignment default taRightJustify;
    property Anchors;
    property AutoSelect;
    property Color;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property PopupMenu;
    property ReadOnly;
    property TabOrder;
    property TabStop default True;
    property Visible;

    property OnChange;
    property OnClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazDBBadgeLabel, TLazDBNumberEdit]);
end;

{ TLazDBBadgeLabel }

constructor TLazDBBadgeLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 100;
  Height := 28;
  FBorderRadius := 6;
  FActiveColor := $0000C853;   // Verde vibrante
  FInactiveColor := $00555555; // Cinza
  FWarningColor := $0000A5FF;  // Laranja / Amber
  FDefaultColor := $002A2A2A;  // Escuro

  Font.Name := 'Segoe UI';
  Font.Size := 8;
  Font.Style := [fsBold];
  Font.Color := clWhite;

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := @DataChange;
end;

destructor TLazDBBadgeLabel.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TLazDBBadgeLabel.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TLazDBBadgeLabel.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if Assigned(AValue) then
      AValue.FreeNotification(Self);
  end;
end;

function TLazDBBadgeLabel.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TLazDBBadgeLabel.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

function TLazDBBadgeLabel.GetField: TField;
begin
  Result := FDataLink.Field;
end;

procedure TLazDBBadgeLabel.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TLazDBBadgeLabel.DataChange(Sender: TObject);
begin
  Invalidate;
end;

function TLazDBBadgeLabel.ResolveBadgeColor(const AText: string): TColor;
var
  UpperStr: string;
begin
  UpperStr := UpperCase(Trim(AText));
  if (UpperStr = 'ATIVO') or (UpperStr = 'A') or (UpperStr = 'PAGO') or
     (UpperStr = 'CONCLUIDO') or (UpperStr = 'TRUE') or (UpperStr = '1') then
    Result := FActiveColor
  else if (UpperStr = 'INATIVO') or (UpperStr = 'I') or (UpperStr = 'CANCELADO') or
          (UpperStr = 'BLOQUEADO') or (UpperStr = 'FALSE') or (UpperStr = '0') then
    Result := FInactiveColor
  else if (UpperStr = 'PENDENTE') or (UpperStr = 'ALERTA') or (UpperStr = 'AGUARDANDO') then
    Result := FWarningColor
  else
    Result := FDefaultColor;
end;

procedure TLazDBBadgeLabel.Paint;
var
  DisplayText: string;
  BadgeColor: TColor;
  R: TRect;
begin
  R := ClientRect;

  if Assigned(FDataLink.Field) then
    DisplayText := FDataLink.Field.DisplayText
  else if csDesigning in ComponentState then
    DisplayText := DataField
  else
    DisplayText := 'INATIVO';

  if DisplayText = '' then
    DisplayText := '-';

  BadgeColor := ResolveBadgeColor(DisplayText);

  { Desenho do Badge com cantos arredondados }
  Canvas.Brush.Color := BadgeColor;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := BadgeColor;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, FBorderRadius, FBorderRadius);

  { Texto Centralizado }
  Canvas.Font.Assign(Self.Font);
  Canvas.Brush.Style := bsClear;
  LCLIntf.DrawText(Canvas.Handle, PChar(DisplayText), Length(DisplayText),
    R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

{ TLazDBNumberEdit }

constructor TLazDBNumberEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Alignment := taRightJustify;
  FDecimals := 2;
  FCurrencySymbol := 'R$ ';
  FFocusedState := False;

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := @DataChange;
  FDataLink.OnUpdateData := @UpdateData;
  FDataLink.OnActiveChange := @ActiveChange;
end;

destructor TLazDBNumberEdit.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TLazDBNumberEdit.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TLazDBNumberEdit.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if Assigned(AValue) then
      AValue.FreeNotification(Self);
  end;
end;

function TLazDBNumberEdit.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TLazDBNumberEdit.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

function TLazDBNumberEdit.GetField: TField;
begin
  Result := FDataLink.Field;
end;

procedure TLazDBNumberEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TLazDBNumberEdit.FormatDisplay;
var
  Val: Double;
begin
  if Assigned(FDataLink.Field) and not FDataLink.Field.IsNull then
  begin
    Val := FDataLink.Field.AsFloat;
    if FFocusedState then
      Text := Format('%.*f', [FDecimals, Val])
    else
      Text := FCurrencySymbol + Format('%.*n', [FDecimals, Val]);
  end
  else
    Text := '';
end;

procedure TLazDBNumberEdit.DataChange(Sender: TObject);
begin
  FormatDisplay;
end;

procedure TLazDBNumberEdit.UpdateData(Sender: TObject);
var
  CleanText: string;
  Val: Double;
begin
  if Assigned(FDataLink.Field) then
  begin
    CleanText := Trim(StringReplace(StringReplace(Text, FCurrencySymbol, '', [rfReplaceAll]), ' ', '', [rfReplaceAll]));
    if CleanText = '' then
      FDataLink.Field.Clear
    else
    begin
      Val := StrToFloatDef(CleanText, 0.0);
      FDataLink.Field.AsFloat := Val;
    end;
  end;
end;

procedure TLazDBNumberEdit.ActiveChange(Sender: TObject);
begin
  Enabled := Assigned(FDataLink.DataSet) and FDataLink.DataSet.Active;
  FormatDisplay;
end;

procedure TLazDBNumberEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  { Transiciona o dataset para modo de edição imediatamente se o usuário teclar }
  if (Key in [VK_DELETE, VK_BACK]) and not ReadOnly then
    FDataLink.Edit;
end;

procedure TLazDBNumberEdit.KeyPress(var Key: Char);
begin
  { Permite apenas dígitos numéricos, ponto/vírgula decimal e teclas de controle }
  if not (Key in ['0'..'9', ',', '.', #8, #13, #27]) then
  begin
    Key := #0;
    Exit;
  end;

  if (Key in ['0'..'9', ',', '.']) and not ReadOnly then
  begin
    { Força o DataSet para o modo dsEdit antes do caractere ser aceito }
    if not FDataLink.Editing then
      FDataLink.Edit;

    FDataLink.Modified;
  end;

  inherited KeyPress(Key);
end;

procedure TLazDBNumberEdit.DoEnter;
begin
  FFocusedState := True;
  FormatDisplay;
  SelectAll;
  inherited DoEnter;
end;

procedure TLazDBNumberEdit.DoExit;
begin
  try
    if FDataLink.Editing then
      FDataLink.UpdateRecord;
  except
    SetFocus;
    raise;
  end;
  FFocusedState := False;
  FormatDisplay;
  inherited DoExit;
end;

end.
