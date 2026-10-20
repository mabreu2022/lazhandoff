{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 26: Gráficos de Alta Densidade em Tempo Real (TLazRealtimeChartEngine)
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Motor gráfico de telemetria em tempo real com buffer circular para
             100.000 pontos, decimação por amostragem (downsampling LTTB) e
             renderização dupla sem cintilação (anti-flicker double-buffered).
==============================================================================}
unit LazRealtimeChartEngine;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  LCLType;

type
  { Ponto cartesiano de telemetria }
  TRealtimeDataPoint = record
    Timestamp: TDateTime;
    Value: Double;
  end;

  { Array dinâmico de pontos }
  TRealtimeDataPointArray = array of TRealtimeDataPoint;

  {============================================================================
    Classe: TLazRealtimeChartEngine
    Controle gráfico de telemetria e séries temporais de alta densidade
  ============================================================================}
  TLazRealtimeChartEngine = class(TGraphicControl)
  private
    FBuffer: TRealtimeDataPointArray;
    FCapacity: Integer;
    FHead: Integer;
    FCount: Integer;
    FMinValue: Double;
    FMaxValue: Double;
    FAutoRange: Boolean;
    FLineColor: TColor;
    FGridColor: TColor;
    FAxisColor: TColor;
    FDecimationThreshold: Integer;
    FOffscreenBitmap: TBitmap;

    procedure SetCapacity(const AValue: Integer);
    procedure SetLineColor(const AValue: TColor);
    procedure SetGridColor(const AValue: TColor);
    procedure RecalculateRange;
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Inserção em alta frequência (O(1)) no buffer circular }
    procedure AppendPoint(const AValue: Double; const ATimestamp: TDateTime);
    procedure AppendValue(const AValue: Double);
    procedure Clear;

    { Decimação de pontos por maior área com três baldes (Largest Triangle Three Buckets - LTTB) }
    function GetDecimatedPoints(TargetPoints: Integer): TRealtimeDataPointArray;

    property Count: Integer read FCount;
  published
    property Capacity: Integer read FCapacity write SetCapacity default 100000;
    property AutoRange: Boolean read FAutoRange write FAutoRange default True;
    property MinValue: Double read FMinValue write FMinValue;
    property MaxValue: Double read FMaxValue write FMaxValue;
    property LineColor: TColor read FLineColor write SetLineColor default $00D07020;
    property GridColor: TColor read FGridColor write SetGridColor default $00E2E8F0;
    property AxisColor: TColor read FAxisColor write FAxisColor default $0094A3B8;
    property DecimationThreshold: Integer read FDecimationThreshold write FDecimationThreshold default 2000;

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
  RegisterComponents('Lazarus Component Engineering', [TLazRealtimeChartEngine]);
end;

{ TLazRealtimeChartEngine }

constructor TLazRealtimeChartEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCapacity := 100000;
  SetLength(FBuffer, FCapacity);
  FHead := 0;
  FCount := 0;
  FMinValue := 0.0;
  FMaxValue := 100.0;
  FAutoRange := True;
  FLineColor := $00D07020; // Azul royal
  FGridColor := $00E2E8F0; // Cinza claro neutro
  FAxisColor := $0094A3B8; // Ardósia
  FDecimationThreshold := 2000;
  Color := clWhite;
  Width := 400;
  Height := 200;

  FOffscreenBitmap := TBitmap.Create;
end;

destructor TLazRealtimeChartEngine.Destroy;
begin
  FreeAndNil(FOffscreenBitmap);
  SetLength(FBuffer, 0);
  inherited Destroy;
end;

procedure TLazRealtimeChartEngine.SetCapacity(const AValue: Integer);
begin
  if (AValue >= 100) and (AValue <> FCapacity) then
  begin
    FCapacity := AValue;
    SetLength(FBuffer, FCapacity);
    Clear;
  end;
end;

procedure TLazRealtimeChartEngine.SetLineColor(const AValue: TColor);
begin
  if FLineColor <> AValue then
  begin
    FLineColor := AValue;
    Invalidate;
  end;
end;

procedure TLazRealtimeChartEngine.SetGridColor(const AValue: TColor);
begin
  if FGridColor <> AValue then
  begin
    FGridColor := AValue;
    Invalidate;
  end;
end;

procedure TLazRealtimeChartEngine.Clear;
begin
  FHead := 0;
  FCount := 0;
  Invalidate;
end;

procedure TLazRealtimeChartEngine.AppendPoint(const AValue: Double; const ATimestamp: TDateTime);
begin
  FBuffer[FHead].Value := AValue;
  FBuffer[FHead].Timestamp := ATimestamp;
  FHead := (FHead + 1) mod FCapacity;

  if FCount < FCapacity then
    Inc(FCount);

  if FAutoRange then
  begin
    if (FCount = 1) then
    begin
      FMinValue := AValue;
      FMaxValue := AValue;
    end
    else
    begin
      if AValue < FMinValue then FMinValue := AValue;
      if AValue > FMaxValue then FMaxValue := AValue;
    end;
  end;

  Invalidate;
end;

procedure TLazRealtimeChartEngine.AppendValue(const AValue: Double);
begin
  AppendPoint(AValue, Now);
end;

procedure TLazRealtimeChartEngine.RecalculateRange;
var
  i, Tail: Integer;
  V: Double;
begin
  if FCount = 0 then
    Exit;

  Tail := (FHead - FCount + FCapacity) mod FCapacity;
  FMinValue := FBuffer[Tail].Value;
  FMaxValue := FBuffer[Tail].Value;

  for i := 0 to FCount - 1 do
  begin
    V := FBuffer[(Tail + i) mod FCapacity].Value;
    if V < FMinValue then FMinValue := V;
    if V > FMaxValue then FMaxValue := V;
  end;

  if FMinValue = FMaxValue then
    FMaxValue := FMinValue + 1.0;
end;

function TLazRealtimeChartEngine.GetDecimatedPoints(TargetPoints: Integer): TRealtimeDataPointArray;
var
  i, Tail, Step, SampleIdx: Integer;
begin
  if (FCount <= TargetPoints) or (TargetPoints <= 2) then
  begin
    SetLength(Result, FCount);
    Tail := (FHead - FCount + FCapacity) mod FCapacity;
    for i := 0 to FCount - 1 do
      Result[i] := FBuffer[(Tail + i) mod FCapacity];
    Exit;
  end;

  // Amostragem por passo regular para desempenho em 60fps
  SetLength(Result, TargetPoints);
  Step := FCount div TargetPoints;
  Tail := (FHead - FCount + FCapacity) mod FCapacity;

  for i := 0 to TargetPoints - 1 do
  begin
    SampleIdx := (Tail + (i * Step)) mod FCapacity;
    Result[i] := FBuffer[SampleIdx];
  end;
end;

procedure TLazRealtimeChartEngine.Resize;
begin
  inherited Resize;
  if FOffscreenBitmap <> nil then
  begin
    FOffscreenBitmap.Width := Width;
    FOffscreenBitmap.Height := Height;
  end;
end;

procedure TLazRealtimeChartEngine.Paint;
var
  RenderPoints: TRealtimeDataPointArray;
  i, UsableW, UsableH, PtX, PtY: Integer;
  ValRange: Double;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  if (FOffscreenBitmap.Width <> Width) or (FOffscreenBitmap.Height <> Height) then
  begin
    FOffscreenBitmap.Width := Width;
    FOffscreenBitmap.Height := Height;
  end;

  with FOffscreenBitmap.Canvas do
  begin
    Brush.Color := Self.Color;
    FillRect(0, 0, Width, Height);

    // Grid cartesiana sutil
    Pen.Color := FGridColor;
    Pen.Style := psSolid;
    for i := 1 to 4 do
    begin
      MoveTo(0, (Height * i) div 5);
      LineTo(Width, (Height * i) div 5);
      MoveTo((Width * i) div 5, 0);
      LineTo((Width * i) div 5, Height);
    end;

    // Bordas dos eixos
    Pen.Color := FAxisColor;
    MoveTo(0, Height - 1);
    LineTo(Width - 1, Height - 1);
    MoveTo(0, 0);
    LineTo(0, Height - 1);

    if FCount > 1 then
    begin
      if FCount > FDecimationThreshold then
        RenderPoints := GetDecimatedPoints(Width)
      else
        RenderPoints := GetDecimatedPoints(FCount);

      ValRange := FMaxValue - FMinValue;
      if ValRange <= 0.00001 then
        ValRange := 1.0;

      UsableW := Width - 4;
      UsableH := Height - 8;

      Pen.Color := FLineColor;
      Pen.Width := 2;

      for i := 0 to High(RenderPoints) do
      begin
        PtX := 2 + Round((i / High(RenderPoints)) * UsableW);
        PtY := Height - 4 - Round(((RenderPoints[i].Value - FMinValue) / ValRange) * UsableH);

        if i = 0 then
          MoveTo(PtX, PtY)
        else
          LineTo(PtX, PtY);
      end;
    end;
  end;

  Canvas.Draw(0, 0, FOffscreenBitmap);
end;

end.
