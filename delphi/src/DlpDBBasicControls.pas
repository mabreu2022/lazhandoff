{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 14: Controles DB-Aware Básicos de Exibição e Edição
  Unidade: DlpDBBasicControls (TDlpDBBadgeLabel e TDlpDBNumberEdit)
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Implementação de dois controles DB-Aware essenciais para Delphi 12:
             1. TDlpDBBadgeLabel: Pílula visual de status com estilização dinâmica.
             2. TDlpDBNumberEdit: Caixa de edição monetária e decimal com
                máscara adaptativa e transição imediata para modo dsEdit.
==============================================================================}
unit DlpDBBasicControls;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.Forms,
  Data.DB,
  Vcl.DBCtrls;

type
  {============================================================================
    Controle 1: TDlpDBBadgeLabel (Visualização Condicional de Status)
  ============================================================================}
  TDlpDBBadgeLabel = class(TGraphicControl)
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
    Controle 2: TDlpDBNumberEdit (Edição Monetária DB-Aware)
  ============================================================================}
  TDlpDBNumberEdit = class(TCustomEdit)
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
    property DoubleBuffered default True;
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
  RegisterComponents('Engenharia Delphi 12', [TDlpDBBadgeLabel, TDlpDBNumberEdit]);
end;

{ TDlpDBBadgeLabel }

constructor TDlpDBBadgeLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 110;
  Height := 28;
  FBorderRadius := 6;
  FActiveColor := $0000C853;
  FInactiveColor := $00555555;
  FWarningColor := $0000A5FF;
  FDefaultColor := $002A2A2A;

  Font.Name := 'Segoe UI';
  Font.Size := 8;
  Font.Style := [fsBold];
  Font.Color := clWhite;

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
end;

destructor TDlpDBBadgeLabel.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TDlpDBBadgeLabel.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDlpDBBadgeLabel.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if Assigned(AValue) then
      AValue.FreeNotification(Self);
  end;
end;

function TDlpDBBadgeLabel.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TDlpDBBadgeLabel.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

function TDlpDBBadgeLabel.GetField: TField;
begin
  Result := FDataLink.Field;
end;

procedure TDlpDBBadgeLabel.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TDlpDBBadgeLabel.DataChange(Sender: TObject);
begin
  Invalidate;
end;

function TDlpDBBadgeLabel.ResolveBadgeColor(const AText: string): TColor;
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

procedure TDlpDBBadgeLabel.Paint;
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

  Canvas.Brush.Color := BadgeColor;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := BadgeColor;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, FBorderRadius, FBorderRadius);

  Canvas.Font.Assign(Self.Font);
  Canvas.Brush.Style := bsClear;
  Winapi.Windows.DrawText(Canvas.Handle, PChar(DisplayText), Length(DisplayText),
    R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

{ TDlpDBNumberEdit }

constructor TDlpDBNumberEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Alignment := taRightJustify;
  DoubleBuffered := True;
  FDecimals := 2;
  FCurrencySymbol := 'R$ ';
  FFocusedState := False;

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;
  FDataLink.OnActiveChange := ActiveChange;
end;

destructor TDlpDBNumberEdit.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TDlpDBNumberEdit.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDlpDBNumberEdit.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if Assigned(AValue) then
      AValue.FreeNotification(Self);
  end;
end;

function TDlpDBNumberEdit.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TDlpDBNumberEdit.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

function TDlpDBNumberEdit.GetField: TField;
begin
  Result := FDataLink.Field;
end;

procedure TDlpDBNumberEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TDlpDBNumberEdit.FormatDisplay;
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

procedure TDlpDBNumberEdit.DataChange(Sender: TObject);
begin
  FormatDisplay;
end;

procedure TDlpDBNumberEdit.UpdateData(Sender: TObject);
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

procedure TDlpDBNumberEdit.ActiveChange(Sender: TObject);
begin
  Enabled := Assigned(FDataLink.DataSet) and FDataLink.DataSet.Active;
  FormatDisplay;
end;

procedure TDlpDBNumberEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key in [VK_DELETE, VK_BACK]) and not ReadOnly then
    FDataLink.Edit;
end;

procedure TDlpDBNumberEdit.KeyPress(var Key: Char);
begin
  if not (CharInSet(Key, ['0'..'9', ',', '.', #8, #13, #27])) then
  begin
    Key := #0;
    Exit;
  end;

  if (CharInSet(Key, ['0'..'9', ',', '.'])) and not ReadOnly then
  begin
    if not FDataLink.Editing then
      FDataLink.Edit;

    FDataLink.Modified;
  end;

  inherited KeyPress(Key);
end;

procedure TDlpDBNumberEdit.DoEnter;
begin
  FFocusedState := True;
  FormatDisplay;
  SelectAll;
  inherited DoEnter;
end;

procedure TDlpDBNumberEdit.DoExit;
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
