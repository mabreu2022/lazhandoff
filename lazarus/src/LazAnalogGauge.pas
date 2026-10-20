{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 09: Controles Visuais Leves (TGraphicControl)
  Componente: TLazAnalogGauge
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Indicador visual analógico (VU Meter / Dial Gauge) construído sobre
             TGraphicControl, demonstrando renderização matemática trigonométrica,
             eliminação de flickering via Double Buffering com TBitmap em memória
             e zonas configuráveis de alerta (Normal, Atenção e Crítico).
==============================================================================}
unit LazAnalogGauge;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Math;

type
  { Evento disparado quando o valor ultrapassa a zona de alerta }
  TOnGaugeThresholdCrossed = procedure(Sender: TObject; ACurrentValue: Double;
    IsCritical: Boolean) of object;

  {============================================================================
    Classe: TLazAnalogGauge
    Controle gráfico leve sem handle nativo (Windowless)
  ============================================================================}
  TLazAnalogGauge = class(TGraphicControl)
  private
    FValue: Double;
    FMinValue: Double;
    FMaxValue: Double;
    FWarningThreshold: Double;
    FCriticalThreshold: Double;
    FGaugeTitle: string;
    FUnitLabel: string;
    FMajorTickStep: Double;

    { Cores dos elementos }
    FDialColor: TColor;
    FNeedleColor: TColor;
    FNormalColor: TColor;
    FWarningColor: TColor;
    FCriticalColor: TColor;
    FOnThresholdCrossed: TOnGaugeThresholdCrossed;

    procedure SetValue(const AValue: Double);
    procedure SetMinValue(const AValue: Double);
    procedure SetMaxValue(const AValue: Double);
    procedure SetWarningThreshold(const AValue: Double);
    procedure SetCriticalThreshold(const AValue: Double);
    procedure SetGaugeTitle(const AValue: string);
    procedure SetUnitLabel(const AValue: string);
    procedure SetMajorTickStep(const AValue: Double);
    procedure SetDialColor(const AValue: TColor);
    procedure SetNeedleColor(const AValue: TColor);
    procedure SetNormalColor(const AValue: TColor);
    procedure SetWarningColor(const AValue: TColor);
    procedure SetCriticalColor(const AValue: TColor);

    function ValueToAngle(AVal: Double): Double;
    procedure RenderGaugeToCanvas(ACanvas: TCanvas; const ARect: TRect);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: Double read FValue write SetValue;
    property MinValue: Double read FMinValue write SetMinValue;
    property MaxValue: Double read FMaxValue write SetMaxValue;
    property WarningThreshold: Double read FWarningThreshold write SetWarningThreshold;
    property CriticalThreshold: Double read FCriticalThreshold write SetCriticalThreshold;
    property GaugeTitle: string read FGaugeTitle write SetGaugeTitle;
    property UnitLabel: string read FUnitLabel write SetUnitLabel;
    property MajorTickStep: Double read FMajorTickStep write SetMajorTickStep;

    property DialColor: TColor read FDialColor write SetDialColor default $001A1A1A;
    property NeedleColor: TColor read FNeedleColor write SetNeedleColor default $0000A5FF;
    property NormalColor: TColor read FNormalColor write SetNormalColor default $0000C853;
    property WarningColor: TColor read FWarningColor write SetWarningColor default $0000D7FF;
    property CriticalColor: TColor read FCriticalColor write SetCriticalColor default $002929D5;

    { Propriedades herdadas publicadas de TGraphicControl }
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    { Eventos }
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnThresholdCrossed: TOnGaugeThresholdCrossed read FOnThresholdCrossed write FOnThresholdCrossed;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazAnalogGauge]);
end;

{ TLazAnalogGauge }

constructor TLazAnalogGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 180;
  FMinValue := 0.0;
  FMaxValue := 100.0;
  FValue := 25.0;
  FWarningThreshold := 70.0;
  FCriticalThreshold := 90.0;
  FMajorTickStep := 20.0;
  FGaugeTitle := 'PRESSÃO';
  FUnitLabel := 'BAR';

  FDialColor := $001A1A1A;
  FNeedleColor := $0000A5FF;
  FNormalColor := $0000C853;
  FWarningColor := $0000D7FF;
  FCriticalColor := $002929D5;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00E0E0E0;
end;

procedure TLazAnalogGauge.SetValue(const AValue: Double);
var
  ClampedVal: Double;
begin
  ClampedVal := EnsureRange(AValue, FMinValue, FMaxValue);
  if FValue <> ClampedVal then
  begin
    FValue := ClampedVal;
    Invalidate;

    if Assigned(FOnThresholdCrossed) then
    begin
      if FValue >= FCriticalThreshold then
        FOnThresholdCrossed(Self, FValue, True)
      else if FValue >= FWarningThreshold then
        FOnThresholdCrossed(Self, FValue, False);
    end;
  end;
end;

procedure TLazAnalogGauge.SetMinValue(const AValue: Double);
begin
  if (FMinValue <> AValue) and (AValue < FMaxValue) then
  begin
    FMinValue := AValue;
    SetValue(FValue);
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetMaxValue(const AValue: Double);
begin
  if (FMaxValue <> AValue) and (AValue > FMinValue) then
  begin
    FMaxValue := AValue;
    SetValue(FValue);
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetWarningThreshold(const AValue: Double);
begin
  if FWarningThreshold <> AValue then
  begin
    FWarningThreshold := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetCriticalThreshold(const AValue: Double);
begin
  if FCriticalThreshold <> AValue then
  begin
    FCriticalThreshold := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetGaugeTitle(const AValue: string);
begin
  if FGaugeTitle <> AValue then
  begin
    FGaugeTitle := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetUnitLabel(const AValue: string);
begin
  if FUnitLabel <> AValue then
  begin
    FUnitLabel := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetMajorTickStep(const AValue: Double);
begin
  if (FMajorTickStep <> AValue) and (AValue > 0) then
  begin
    FMajorTickStep := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetDialColor(const AValue: TColor);
begin
  if FDialColor <> AValue then
  begin
    FDialColor := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetNeedleColor(const AValue: TColor);
begin
  if FNeedleColor <> AValue then
  begin
    FNeedleColor := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetNormalColor(const AValue: TColor);
begin
  if FNormalColor <> AValue then
  begin
    FNormalColor := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetWarningColor(const AValue: TColor);
begin
  if FWarningColor <> AValue then
  begin
    FWarningColor := AValue;
    Invalidate;
  end;
end;

procedure TLazAnalogGauge.SetCriticalColor(const AValue: TColor);
begin
  if FCriticalColor <> AValue then
  begin
    FCriticalColor := AValue;
    Invalidate;
  end;
end;

function TLazAnalogGauge.ValueToAngle(AVal: Double): Double;
var
  Fraction: Double;
begin
  { Mapeia MinValue..MaxValue para 225 graus até -45 graus (arco de 270 graus) }
  Fraction := (AVal - FMinValue) / (FMaxValue - FMinValue);
  Result := 225.0 - (Fraction * 270.0);
end;

procedure TLazAnalogGauge.RenderGaugeToCanvas(ACanvas: TCanvas; const ARect: TRect);
var
  CenterX, CenterY, Radius, InnerRadius: Integer;
  AngleRad, AngleDeg: Double;
  NeedleLength: Integer;
  Nx, Ny, Px, Py: Integer;
  CurrentTickVal: Double;
  TickAngleRad: Double;
  Tx1, Ty1, Tx2, Ty2: Integer;
  ValStr, TitleStr: string;
  ZoneAngle: Double;
  ArcR: TRect;
begin
  CenterX := ARect.Left + (ARect.Width div 2);
  CenterY := ARect.Top + (ARect.Height div 2) + 10;
  Radius := Min(ARect.Width, ARect.Height) div 2 - 16;
  InnerRadius := Radius - 12;
  NeedleLength := Radius - 20;

  { 1. Fundo do Mostrador }
  ACanvas.Brush.Color := FDialColor;
  ACanvas.Pen.Color := $00333333;
  ACanvas.Pen.Width := 2;
  ACanvas.Ellipse(CenterX - Radius - 8, CenterY - Radius - 8,
                  CenterX + Radius + 8, CenterY + Radius + 8);

  { 2. Faixa Colorida de Zonas (Normal, Warning, Critical) }
  ACanvas.Pen.Width := 4;
  CurrentTickVal := FMinValue;
  while CurrentTickVal <= FMaxValue do
  begin
    AngleDeg := ValueToAngle(CurrentTickVal);
    AngleRad := DegToRad(AngleDeg);

    if CurrentTickVal >= FCriticalThreshold then
      ACanvas.Pen.Color := FCriticalColor
    else if CurrentTickVal >= FWarningThreshold then
      ACanvas.Pen.Color := FWarningColor
    else
      ACanvas.Pen.Color := FNormalColor;

    Tx1 := CenterX + Round(Radius * Cos(AngleRad));
    Ty1 := CenterY - Round(Radius * Sin(AngleRad));
    Tx2 := CenterX + Round(InnerRadius * Cos(AngleRad));
    Ty2 := CenterY - Round(InnerRadius * Sin(AngleRad));

    ACanvas.MoveTo(Tx1, Ty1);
    ACanvas.LineTo(Tx2, Ty2);

    CurrentTickVal := CurrentTickVal + (FMajorTickStep / 4.0);
  end;

  { 3. Marcações Principais (Major Ticks) e Números }
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 7;
  ACanvas.Font.Color := $00A0A0A0;
  ACanvas.Brush.Style := bsClear;

  CurrentTickVal := FMinValue;
  while CurrentTickVal <= FMaxValue do
  begin
    AngleDeg := ValueToAngle(CurrentTickVal);
    AngleRad := DegToRad(AngleDeg);

    Tx1 := CenterX + Round(Radius * Cos(AngleRad));
    Ty1 := CenterY - Round(Radius * Sin(AngleRad));
    Tx2 := CenterX + Round((InnerRadius - 6) * Cos(AngleRad));
    Ty2 := CenterY - Round((InnerRadius - 6) * Sin(AngleRad));

    ACanvas.Pen.Color := clWhite;
    ACanvas.Pen.Width := 2;
    ACanvas.MoveTo(Tx1, Ty1);
    ACanvas.LineTo(Tx2, Ty2);

    { Texto do Tick }
    ValStr := Format('%.0f', [CurrentTickVal]);
    Px := CenterX + Round((InnerRadius - 16) * Cos(AngleRad)) - (ACanvas.TextWidth(ValStr) div 2);
    Py := CenterY - Round((InnerRadius - 16) * Sin(AngleRad)) - (ACanvas.TextHeight(ValStr) div 2);
    ACanvas.TextOut(Px, Py, ValStr);

    CurrentTickVal := CurrentTickVal + FMajorTickStep;
  end;

  { 4. Ponteiro / Agulha Dinâmica }
  AngleDeg := ValueToAngle(FValue);
  AngleRad := DegToRad(AngleDeg);
  Nx := CenterX + Round(NeedleLength * Cos(AngleRad));
  Ny := CenterY - Round(NeedleLength * Sin(AngleRad));

  ACanvas.Pen.Color := FNeedleColor;
  ACanvas.Pen.Width := 3;
  ACanvas.MoveTo(CenterX, CenterY);
  ACanvas.LineTo(Nx, Ny);

  { 5. Pivô Central Metálico }
  ACanvas.Brush.Color := $00555555;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Pen.Width := 1;
  ACanvas.Ellipse(CenterX - 6, CenterY - 6, CenterX + 6, CenterY + 6);

  { 6. Leitura Digital Central e Título }
  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := $00808080;
  TitleStr := FGaugeTitle;
  ACanvas.TextOut(CenterX - (ACanvas.TextWidth(TitleStr) div 2), CenterY - (Radius div 2), TitleStr);

  ACanvas.Font.Size := 12;
  ACanvas.Font.Color := clWhite;
  ValStr := Format('%.1f %s', [FValue, FUnitLabel]);
  ACanvas.TextOut(CenterX - (ACanvas.TextWidth(ValStr) div 2), CenterY + 16, ValStr);
end;

procedure TLazAnalogGauge.Paint;
var
  BufferBmp: TBitmap;
begin
  { Double Buffering Manual estrito via TBitmap em memória para eliminação de flicker }
  BufferBmp := TBitmap.Create;
  try
    BufferBmp.SetSize(Width, Height);
    BufferBmp.Canvas.Brush.Color := ColorToRGB(clDefault);
    { Copia o fundo do Parent se for transparente }
    RenderGaugeToCanvas(BufferBmp.Canvas, Rect(0, 0, Width, Height));
    Canvas.Draw(0, 0, BufferBmp);
  finally
    BufferBmp.Free;
  end;
end;

end.
