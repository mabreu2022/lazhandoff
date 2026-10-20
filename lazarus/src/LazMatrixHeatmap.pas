{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 29: Visualizador de Mapas de Calor (TLazMatrixHeatmap)
  Componente: TLazMatrixHeatmap
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Controle visual para exibição de matrizes bidimensionais com interpolação
             de gradientes térmicos contínuos (Heatmaps), ideal para correlação
             de dados, análise de tráfego e telemetria espacial.
==============================================================================}
unit LazMatrixHeatmap;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  LCLType;

type
  { Matriz dinâmica 2D de ponto flutuante }
  TDoubleMatrix = array of array of Double;

  { Evento de clique em uma célula do Heatmap }
  TOnCellClickEvent = procedure(Sender: TObject; ARow, ACol: Integer;
    AValue: Double) of object;

  {============================================================================
    Classe: TLazMatrixHeatmap
    Mapa de calor matricial bidimensional com gradiente térmico adaptativo
  ============================================================================}
  TLazMatrixHeatmap = class(TCustomControl)
  private
    FData: TDoubleMatrix;
    FRowCount: Integer;
    FColCount: Integer;
    FMinValue: Double;
    FMaxValue: Double;
    FMinColor: TColor;
    FMaxColor: TColor;
    FShowValues: Boolean;
    FSelectedRow: Integer;
    FSelectedCol: Integer;
    FOnCellClick: TOnCellClickEvent;

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

    procedure SetMatrixSize(ARows, ACols: Integer);
    procedure SetValue(ARow, ACol: Integer; const AValue: Double);
    function GetValue(ARow, ACol: Integer): Double;
    procedure PopulateRandom(MinVal, MaxVal: Double);

    property Value[ARow, ACol: Integer]: Double read GetValue write SetValue;
  published
    property RowCount: Integer read FRowCount write SetRowCount default 6;
    property ColCount: Integer read FColCount write SetColCount default 8;
    property MinColor: TColor read FMinColor write SetMinColor default $00D07020; // Azul frio
    property MaxColor: TColor read FMaxColor write SetMaxColor default $002A2AE0; // Vermelho quente
    property ShowValues: Boolean read FShowValues write SetShowValues default True;
    property OnCellClick: TOnCellClickEvent read FOnCellClick write FOnCellClick;

    property Align;
    property Anchors;
    property Color default clWhite;
    property Enabled;
    property Font;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazMatrixHeatmap]);
end;

{ TLazMatrixHeatmap }

constructor TLazMatrixHeatmap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csCaptureMouse, csClickEvents, csOpaque, csDoubleClicks];
  Width := 360;
  Height := 240;
  Color := clWhite;
  FMinColor := $00D07020; // Azul
  FMaxColor := $002A2AE0; // Vermelho
  FShowValues := True;
  FSelectedRow := -1;
  FSelectedCol := -1;

  SetMatrixSize(6, 8);
  PopulateRandom(10.0, 100.0);
end;

procedure TLazMatrixHeatmap.SetMatrixSize(ARows, ACols: Integer);
var
  r, c: Integer;
begin
  if (ARows <= 0) or (ACols <= 0) then
    Exit;

  FRowCount := ARows;
  FColCount := ACols;
  SetLength(FData, FRowCount, FColCount);

  for r := 0 to FRowCount - 1 do
    for c := 0 to FColCount - 1 do
      FData[r, c] := 0.0;

  RecalculateLimits;
  Invalidate;
end;

procedure TLazMatrixHeatmap.SetRowCount(const AValue: Integer);
begin
  if (AValue > 0) and (AValue <> FRowCount) then
    SetMatrixSize(AValue, FColCount);
end;

procedure TLazMatrixHeatmap.SetColCount(const AValue: Integer);
begin
  if (AValue > 0) and (AValue <> FColCount) then
    SetMatrixSize(FRowCount, AValue);
end;

procedure TLazMatrixHeatmap.SetMinColor(const AValue: TColor);
begin
  if FMinColor <> AValue then
  begin
    FMinColor := AValue;
    Invalidate;
  end;
end;

procedure TLazMatrixHeatmap.SetMaxColor(const AValue: TColor);
begin
  if FMaxColor <> AValue then
  begin
    FMaxColor := AValue;
    Invalidate;
  end;
end;

procedure TLazMatrixHeatmap.SetShowValues(const AValue: Boolean);
begin
  if FShowValues <> AValue then
  begin
    FShowValues := AValue;
    Invalidate;
  end;
end;

procedure TLazMatrixHeatmap.SetValue(ARow, ACol: Integer; const AValue: Double);
begin
  if (ARow >= 0) and (ARow < FRowCount) and (ACol >= 0) and (ACol < FColCount) then
  begin
    FData[ARow, ACol] := AValue;
    RecalculateLimits;
    Invalidate;
  end;
end;

function TLazMatrixHeatmap.GetValue(ARow, ACol: Integer): Double;
begin
  if (ARow >= 0) and (ARow < FRowCount) and (ACol >= 0) and (ACol < FColCount) then
    Result := FData[ARow, ACol]
  else
    Result := 0.0;
end;

procedure TLazMatrixHeatmap.RecalculateLimits;
var
  r, c: Integer;
begin
  if (FRowCount = 0) or (FColCount = 0) then
    Exit;

  FMinValue := FData[0, 0];
  FMaxValue := FData[0, 0];

  for r := 0 to FRowCount - 1 do
  begin
    for c := 0 to FColCount - 1 do
    begin
      if FData[r, c] < FMinValue then FMinValue := FData[r, c];
      if FData[r, c] > FMaxValue then FMaxValue := FData[r, c];
    end;
  end;

  if FMinValue = FMaxValue then
    FMaxValue := FMinValue + 1.0;
end;

procedure TLazMatrixHeatmap.PopulateRandom(MinVal, MaxVal: Double);
var
  r, c: Integer;
begin
  for r := 0 to FRowCount - 1 do
    for c := 0 to FColCount - 1 do
      FData[r, c] := MinVal + (Random * (MaxVal - MinVal));

  RecalculateLimits;
  Invalidate;
end;

function TLazMatrixHeatmap.InterpolateColor(AValue: Double): TColor;
var
  T: Double;
  R1, G1, B1, R2, G2, B2: Byte;
  R, G, B: Byte;
begin
  if FMaxValue <= FMinValue then
    Exit(FMinColor);

  T := (AValue - FMinValue) / (FMaxValue - FMinValue);
  if T < 0.0 then T := 0.0;
  if T > 1.0 then T := 1.0;

  R1 := Red(FMinColor);
  G1 := Green(FMinColor);
  B1 := Blue(FMinColor);

  R2 := Red(FMaxColor);
  G2 := Green(FMaxColor);
  B2 := Blue(FMaxColor);

  R := Round(R1 + T * (R2 - R1));
  G := Round(G1 + T * (G2 - G1));
  B := Round(B1 + T * (B2 - B1));

  Result := RGBToColor(R, G, B);
end;

procedure TLazMatrixHeatmap.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CellW, CellH, c, r: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if (FColCount > 0) and (FRowCount > 0) then
  begin
    CellW := Width div FColCount;
    CellH := Height div FRowCount;

    c := X div CellW;
    r := Y div CellH;

    if (r >= 0) and (r < FRowCount) and (c >= 0) and (c < FColCount) then
    begin
      FSelectedRow := r;
      FSelectedCol := c;
      if Assigned(FOnCellClick) then
        FOnCellClick(Self, r, c, FData[r, c]);
      Invalidate;
    end;
  end;
end;

procedure TLazMatrixHeatmap.Paint;
var
  r, c, CellW, CellH, X1, Y1, X2, Y2: Integer;
  ValStr: string;
begin
  Canvas.Font.Assign(Self.Font);
  Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(0, 0, Width, Height);

  if (FRowCount = 0) or (FColCount = 0) then
    Exit;

  CellW := Width div FColCount;
  CellH := Height div FRowCount;

  for r := 0 to FRowCount - 1 do
  begin
    for c := 0 to FColCount - 1 do
    begin
      X1 := c * CellW;
      Y1 := r * CellH;
      X2 := X1 + CellW;
      Y2 := Y1 + CellH;

      Canvas.Brush.Color := InterpolateColor(FData[r, c]);
      if (r = FSelectedRow) and (c = FSelectedCol) then
      begin
        Canvas.Pen.Color := clHighlight;
        Canvas.Pen.Width := 3;
      end
      else
      begin
        Canvas.Pen.Color := $00FFFFFF;
        Canvas.Pen.Width := 1;
      end;

      Canvas.Rectangle(X1, Y1, X2, Y2);

      if FShowValues and (CellW > 28) and (CellH > 16) then
      begin
        Canvas.Brush.Style := bsClear;
        Canvas.Font.Size := 7;
        Canvas.Font.Color := clWhite;
        ValStr := Format('%.1f', [FData[r, c]]);
        Canvas.TextOut(X1 + (CellW - Canvas.TextWidth(ValStr)) div 2,
                       Y1 + (CellH - Canvas.TextHeight(ValStr)) div 2, ValStr);
      end;
    end;
  end;
end;

end.
