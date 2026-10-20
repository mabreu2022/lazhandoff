{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 29: Visualizador de Mapas de Calor (TDlpMatrixHeatmap)
  Componente: TDlpMatrixHeatmap
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / Windows 64-bit)
  Descrição: Controle visual VCL para renderização de matrizes bidimensionais com
             interpolação de gradientes térmicos contínuos (Heatmaps), seleção
             interativa de células, cálculo dinâmico de mínimos e máximos e
             exibição de valores numéricos formatados.
==============================================================================}
unit DlpMatrixHeatmap;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  Vcl.Controls,
  Vcl.Graphics,
  Winapi.Windows;

type
  { Matriz dinâmica 2D de números de ponto flutuante }
  TDlpDoubleMatrix = TArray<TArray<Double>>;

  { Assinatura do evento de clique sobre uma célula do Heatmap }
  TDlpOnCellClickEvent = procedure(Sender: TObject; ARow, ACol: Integer;
    AValue: Double) of object;

  {============================================================================
    Componente: TDlpMatrixHeatmap
    Renderizador matricial de calor com suporte a gradientes térmicos contínuos
  ============================================================================}
  TDlpMatrixHeatmap = class(TCustomControl)
  private
    FData: TDlpDoubleMatrix;
    FRowCount: Integer;
    FColCount: Integer;
    FMinValue: Double;
    FMaxValue: Double;
    FMinColor: TColor;
    FMaxColor: TColor;
    FShowValues: Boolean;
    FSelectedRow: Integer;
    FSelectedCol: Integer;
    FOnCellClick: TDlpOnCellClickEvent;

    procedure SetRowCount(const AValue: Integer);
    procedure SetColCount(const AValue: Integer);
    procedure SetMinColor(const AValue: TColor);
    procedure SetMaxColor(const AValue: TColor);
    procedure SetShowValues(const AValue: Boolean);
    function InterpolateColor(AValue: Double): TColor;
    procedure RecalculateLimits;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetMatrixSize(ARows, ACols: Integer);
    procedure SetValue(ARow, ACol: Integer; const AValue: Double);
    function GetValue(ARow, ACol: Integer): Double;
    procedure PopulateRandom(MinVal, MaxVal: Double);

    property Value[ARow, ACol: Integer]: Double read GetValue write SetValue;
  published
    property RowCount: Integer read FRowCount write SetRowCount default 6;
    property ColCount: Integer read FColCount write SetColCount default 8;
    property MinColor: TColor read FMinColor write SetMinColor default $0080FF00; { Verde-azulado }
    property MaxColor: TColor read FMaxColor write SetMaxColor default $002020FF; { Vermelho quente }
    property ShowValues: Boolean read FShowValues write SetShowValues default True;
    property SelectedRow: Integer read FSelectedRow;
    property SelectedCol: Integer read FSelectedCol;

    { Propriedades herdadas da VCL }
    property Align;
    property Anchors;
    property Color default $00FFFFFF;
    property Font;
    property Visible;
    property OnClick;
    property OnCellClick: TDlpOnCellClickEvent read FOnCellClick write FOnCellClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpMatrixHeatmap]);
end;

{ TDlpMatrixHeatmap }

constructor TDlpMatrixHeatmap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks, csOpaque];
  Width := 400;
  Height := 280;
  Color := clWhite;

  FRowCount := 6;
  FColCount := 8;
  FMinColor := $00E0E080; { Azul claro frio }
  FMaxColor := $002030E0; { Vermelho escuro quente }
  FShowValues := True;
  FSelectedRow := -1;
  FSelectedCol := -1;
  FMinValue := 0.0;
  FMaxValue := 100.0;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := clBlack;

  SetMatrixSize(FRowCount, FColCount);
  PopulateRandom(10.0, 95.0);
end;

destructor TDlpMatrixHeatmap.Destroy;
begin
  SetLength(FData, 0);
  inherited Destroy;
end;

procedure TDlpMatrixHeatmap.SetMatrixSize(ARows, ACols: Integer);
var
  R: Integer;
begin
  if (ARows <= 0) or (ACols <= 0) then Exit;

  FRowCount := ARows;
  FColCount := ACols;
  SetLength(FData, FRowCount);
  for R := 0 to FRowCount - 1 do
    SetLength(FData[R], FColCount);

  RecalculateLimits;
  Invalidate;
end;

procedure TDlpMatrixHeatmap.SetValue(ARow, ACol: Integer; const AValue: Double);
begin
  if (ARow >= 0) and (ARow < FRowCount) and (ACol >= 0) and (ACol < FColCount) then
  begin
    FData[ARow, ACol] := AValue;
    RecalculateLimits;
    Invalidate;
  end;
end;

function TDlpMatrixHeatmap.GetValue(ARow, ACol: Integer): Double;
begin
  if (ARow >= 0) and (ARow < FRowCount) and (ACol >= 0) and (ACol < FColCount) then
    Result := FData[ARow, ACol]
  else
    Result := 0.0;
end;

procedure TDlpMatrixHeatmap.PopulateRandom(MinVal, MaxVal: Double);
var
  R, C: Integer;
begin
  for R := 0 to FRowCount - 1 do
    for C := 0 to FColCount - 1 do
      FData[R, C] := MinVal + Random * (MaxVal - MinVal);

  RecalculateLimits;
  Invalidate;
end;

procedure TDlpMatrixHeatmap.RecalculateLimits;
var
  R, C: Integer;
  V: Double;
begin
  if (FRowCount = 0) or (FColCount = 0) then Exit;

  FMinValue := FData[0, 0];
  FMaxValue := FData[0, 0];

  for R := 0 to FRowCount - 1 do
    for C := 0 to FColCount - 1 do
    begin
      V := FData[R, C];
      if V < FMinValue then FMinValue := V;
      if V > FMaxValue then FMaxValue := V;
    end;

  if SameValue(FMinValue, FMaxValue) then
    FMaxValue := FMinValue + 1.0;
end;

function TDlpMatrixHeatmap.InterpolateColor(AValue: Double): TColor;
var
  Ratio: Double;
  R1, G1, B1: Byte;
  R2, G2, B2: Byte;
  R, G, B: Byte;
begin
  if FMaxValue <= FMinValue then
    Ratio := 0.0
  else
    Ratio := EnsureRange((AValue - FMinValue) / (FMaxValue - FMinValue), 0.0, 1.0);

  R1 := GetRValue(FMinColor);
  G1 := GetGValue(FMinColor);
  B1 := GetBValue(FMinColor);

  R2 := GetRValue(FMaxColor);
  G2 := GetGValue(FMaxColor);
  B2 := GetBValue(FMaxColor);

  R := Round(R1 + Ratio * (R2 - R1));
  G := Round(G1 + Ratio * (G2 - G1));
  B := Round(B1 + Ratio * (B2 - B1));

  Result := RGB(R, G, B);
end;

procedure TDlpMatrixHeatmap.SetRowCount(const AValue: Integer);
begin
  if (AValue > 0) and (AValue <> FRowCount) then
    SetMatrixSize(AValue, FColCount);
end;

procedure TDlpMatrixHeatmap.SetColCount(const AValue: Integer);
begin
  if (AValue > 0) and (AValue <> FColCount) then
    SetMatrixSize(FRowCount, AValue);
end;

procedure TDlpMatrixHeatmap.SetMinColor(const AValue: TColor);
begin
  if FMinColor <> AValue then
  begin
    FMinColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpMatrixHeatmap.SetMaxColor(const AValue: TColor);
begin
  if FMaxColor <> AValue then
  begin
    FMaxColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpMatrixHeatmap.SetShowValues(const AValue: Boolean);
begin
  if FShowValues <> AValue then
  begin
    FShowValues := AValue;
    Invalidate;
  end;
end;

procedure TDlpMatrixHeatmap.Paint;
var
  CellW, CellH: Single;
  R, C: Integer;
  CellRect: TRect;
  ValStr: string;
  V: Double;
  Brightness: Double;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if (FRowCount = 0) or (FColCount = 0) then Exit;

  CellW := Width / FColCount;
  CellH := Height / FRowCount;

  for R := 0 to FRowCount - 1 do
    for C := 0 to FColCount - 1 do
    begin
      CellRect.Left := Round(C * CellW);
      CellRect.Top := Round(R * CellH);
      CellRect.Right := Round((C + 1) * CellW);
      CellRect.Bottom := Round((R + 1) * CellH);

      V := FData[R, C];
      Canvas.Brush.Color := InterpolateColor(V);
      Canvas.Pen.Color := clWhite;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(CellRect);

      { Destaque para célula selecionada }
      if (R = FSelectedRow) and (C = FSelectedCol) then
      begin
        Canvas.Pen.Color := clBlack;
        Canvas.Pen.Width := 2;
        Canvas.Polyline([
          Point(CellRect.Left + 1, CellRect.Top + 1),
          Point(CellRect.Right - 1, CellRect.Top + 1),
          Point(CellRect.Right - 1, CellRect.Bottom - 1),
          Point(CellRect.Left + 1, CellRect.Bottom - 1),
          Point(CellRect.Left + 1, CellRect.Top + 1)
        ]);
      end;

      if FShowValues then
      begin
        ValStr := FormatFloat('0.0', V);
        Canvas.Brush.Style := bsClear;

        { Escolha da cor do texto por contraste com luminância da célula }
        Brightness := (GetRValue(Canvas.Brush.Color) * 0.299) +
                      (GetGValue(Canvas.Brush.Color) * 0.587) +
                      (GetBValue(Canvas.Brush.Color) * 0.114);

        if Brightness > 140 then
          Canvas.Font.Color := clBlack
        else
          Canvas.Font.Color := clWhite;

        DrawText(Canvas.Handle, PChar(ValStr), Length(ValStr), CellRect,
          DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
    end;
end;

procedure TDlpMatrixHeatmap.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CellW, CellH: Single;
  R, C: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if (Button = mbLeft) and (FRowCount > 0) and (FColCount > 0) then
  begin
    CellW := Width / FColCount;
    CellH := Height / FRowCount;

    C := Trunc(X / CellW);
    R := Trunc(Y / CellH);

    if (R >= 0) and (R < FRowCount) and (C >= 0) and (C < FColCount) then
    begin
      FSelectedRow := R;
      FSelectedCol := C;
      Invalidate;

      if Assigned(FOnCellClick) then
        FOnCellClick(Self, R, C, FData[R, C]);
    end;
  end;
end;

end.
