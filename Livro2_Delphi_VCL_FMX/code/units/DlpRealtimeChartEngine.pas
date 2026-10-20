{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 26: Gráficos de Alta Densidade em Tempo Real (TDlpRealtimeChartEngine)
  Componente: TDlpRealtimeChartEngine
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL
  Descrição: Motor gráfico de alta performance para séries temporais e telemetria
             com buffer circular de 100.000 amostras, decimação adaptativa e
             renderização suave em 60 FPS com double-buffering.
==============================================================================}
unit DlpRealtimeChartEngine;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics;

type
  /// <summary>
  /// Ponto discreto no espaço de telemetria.
  /// </summary>
  TDlpRealtimePoint = record
    Timestamp: TDateTime;
    Value: Double;
  end;

  /// <summary>
  /// Coleção dinâmica de pontos de telemetria.
  /// </summary>
  TDlpRealtimePointArray = TArray<TDlpRealtimePoint>;

  /// <summary>
  /// Motor de renderização gráfica em tempo real para séries temporais de alta densidade.
  /// </summary>
  TDlpRealtimeChartEngine = class(TGraphicControl)
  private
    FBuffer: TDlpRealtimePointArray;
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
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Insere uma nova amostra no buffer circular em complexidade O(1).
    /// </summary>
    procedure AppendPoint(const AValue: Double; const ATimestamp: TDateTime);

    /// <summary>
    /// Insere uma amostra com timestamp automático do momento atual.
    /// </summary>
    procedure AppendValue(const AValue: Double);

    /// <summary>
    /// Reinicia a série temporal e limpa o buffer.
    /// </summary>
    procedure Clear;

    /// <summary>
    /// Retorna conjunto decimado de pontos para desenho responsivo.
    /// </summary>
    function GetDecimatedPoints(TargetPoints: Integer): TDlpRealtimePointArray;

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
  RegisterComponents('Delphi Component Engineering', [TDlpRealtimeChartEngine]);
end;

{ TDlpRealtimeChartEngine }

constructor TDlpRealtimeChartEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCapacity := 100000;
  SetLength(FBuffer, FCapacity);
  FHead := 0;
  FCount := 0;
  FMinValue := 0.0;
  FMaxValue := 100.0;
  FAutoRange := True;
  FLineColor := $00D07020;
  FGridColor := $00E2E8F0;
  FAxisColor := $0094A3B8;
  FDecimationThreshold := 2000;
  Color := clWhite;
  Width := 400;
  Height := 200;

  FOffscreenBitmap := TBitmap.Create;
end;

destructor TDlpRealtimeChartEngine.Destroy;
begin
  FreeAndNil(FOffscreenBitmap);
  SetLength(FBuffer, 0);
  inherited Destroy;
end;

procedure TDlpRealtimeChartEngine.SetCapacity(const AValue: Integer);
begin
  if (AValue >= 100) and (AValue <> FCapacity) then
  begin
    FCapacity := AValue;
    SetLength(FBuffer, FCapacity);
    Clear;
  end;
end;

procedure TDlpRealtimeChartEngine.SetLineColor(const AValue: TColor);
begin
  if FLineColor <> AValue then
  begin
    FLineColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpRealtimeChartEngine.SetGridColor(const AValue: TColor);
begin
  if FGridColor <> AValue then
  begin
    FGridColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpRealtimeChartEngine.Clear;
begin
  FHead := 0;
  FCount := 0;
  Invalidate;
end;

procedure TDlpRealtimeChartEngine.AppendPoint(const AValue: Double; const ATimestamp: TDateTime);
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

procedure TDlpRealtimeChartEngine.AppendValue(const AValue: Double);
begin
  AppendPoint(AValue, Now);
end;

function TDlpRealtimeChartEngine.GetDecimatedPoints(TargetPoints: Integer): TDlpRealtimePointArray;
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

  SetLength(Result, TargetPoints);
  Step := FCount div TargetPoints;
  Tail := (FHead - FCount + FCapacity) mod FCapacity;

  for i := 0 to TargetPoints - 1 do
  begin
    SampleIdx := (Tail + (i * Step)) mod FCapacity;
    Result[i] := FBuffer[SampleIdx];
  end;
end;

procedure TDlpRealtimeChartEngine.Resize;
begin
  inherited Resize;
  if FOffscreenBitmap <> nil then
  begin
    FOffscreenBitmap.Width := Width;
    FOffscreenBitmap.Height := Height;
  end;
end;

procedure TDlpRealtimeChartEngine.Paint;
var
  RenderPoints: TDlpRealtimePointArray;
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
    FillRect(Rect(0, 0, Width, Height));

    Pen.Color := FGridColor;
    Pen.Style := psSolid;
    for i := 1 to 4 do
    begin
      MoveTo(0, (Height * i) div 5);
      LineTo(Width, (Height * i) div 5);
      MoveTo((Width * i) div 5, 0);
      LineTo((Width * i) div 5, Height);
    end;

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
