{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 27: Medidores de Nível e Tanques Industriais (TDlpIndustrialTankGauge)
  Componente: TDlpIndustrialTankGauge
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL
  Descrição: Controle visual gráfico vetorial para simulação de tanques e reservatórios
             industriais com volume proporcional, gradientes de alerta, alarmes
             de nível e calibração por marcas de escala.
==============================================================================}
unit DlpIndustrialTankGauge;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics;

type
  /// <summary>
  /// Classificação do estado de alerta do reservatório.
  /// </summary>
  TDlpTankAlarmState = (asNormal, asLowAlarm, asHighAlarm, asOverflow);

  /// <summary>
  /// Evento notificador de transgressão de limites operacionais.
  /// </summary>
  TOnDlpTankAlarmEvent = procedure(Sender: TObject; State: TDlpTankAlarmState;
    CurrentLevel: Double) of object;

  /// <summary>
  /// Indicador visual vetorial de nível de reservatórios industriais.
  /// </summary>
  TDlpIndustrialTankGauge = class(TGraphicControl)
  private
    FCapacity: Double;
    FCurrentLevel: Double;
    FLowAlarmLevel: Double;
    FHighAlarmLevel: Double;
    FFluidColor: TColor;
    FAlarmColor: TColor;
    FTankWallColor: TColor;
    FShowTicks: Boolean;
    FUnitOfMeasure: string;
    FOnAlarmTriggered: TOnDlpTankAlarmEvent;

    procedure SetCapacity(const AValue: Double);
    procedure SetCurrentLevel(const AValue: Double);
    procedure SetLowAlarmLevel(const AValue: Double);
    procedure SetHighAlarmLevel(const AValue: Double);
    procedure SetFluidColor(const AValue: TColor);
    procedure SetAlarmColor(const AValue: TColor);
    procedure SetShowTicks(const AValue: Boolean);
    procedure SetUnitOfMeasure(const AValue: string);
    function EvaluateAlarmState: TDlpTankAlarmState;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;

    /// <summary>
    /// Retorna a ocupação volumétrica percentual (0 a 100%).
    /// </summary>
    function GetLevelPercentage: Double;
  published
    property Capacity: Double read FCapacity write SetCapacity;
    property CurrentLevel: Double read FCurrentLevel write SetCurrentLevel;
    property LowAlarmLevel: Double read FLowAlarmLevel write SetLowAlarmLevel;
    property HighAlarmLevel: Double read FHighAlarmLevel write SetHighAlarmLevel;
    property FluidColor: TColor read FFluidColor write SetFluidColor default $00D07020;
    property AlarmColor: TColor read FAlarmColor write SetAlarmColor default $002A2AE0;
    property TankWallColor: TColor read FTankWallColor write FTankWallColor default $0094A3B8;
    property ShowTicks: Boolean read FShowTicks write SetShowTicks default True;
    property UnitOfMeasure: string read FUnitOfMeasure write SetUnitOfMeasure;
    property OnAlarmTriggered: TOnDlpTankAlarmEvent read FOnAlarmTriggered write FOnAlarmTriggered;

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
  RegisterComponents('Delphi Component Engineering', [TDlpIndustrialTankGauge]);
end;

{ TDlpIndustrialTankGauge }

constructor TDlpIndustrialTankGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCapacity := 1000.0;
  FCurrentLevel := 650.0;
  FLowAlarmLevel := 150.0;
  FHighAlarmLevel := 900.0;
  FFluidColor := $00D07020;
  FAlarmColor := $002A2AE0;
  FTankWallColor := $0094A3B8;
  FShowTicks := True;
  FUnitOfMeasure := 'm³';
  Color := clWhite;
  Width := 140;
  Height := 240;
end;

procedure TDlpIndustrialTankGauge.SetCapacity(const AValue: Double);
begin
  if (AValue > 0) and (AValue <> FCapacity) then
  begin
    FCapacity := AValue;
    Invalidate;
  end;
end;

procedure TDlpIndustrialTankGauge.SetCurrentLevel(const AValue: Double);
var
  OldState, NewState: TDlpTankAlarmState;
begin
  if AValue <> FCurrentLevel then
  begin
    OldState := EvaluateAlarmState;
    FCurrentLevel := AValue;
    NewState := EvaluateAlarmState;

    if (OldState <> NewState) and (NewState <> asNormal) and Assigned(FOnAlarmTriggered) then
      FOnAlarmTriggered(Self, NewState, FCurrentLevel);

    Invalidate;
  end;
end;

procedure TDlpIndustrialTankGauge.SetLowAlarmLevel(const AValue: Double);
begin
  if AValue <> FLowAlarmLevel then
  begin
    FLowAlarmLevel := AValue;
    Invalidate;
  end;
end;

procedure TDlpIndustrialTankGauge.SetHighAlarmLevel(const AValue: Double);
begin
  if AValue <> FHighAlarmLevel then
  begin
    FHighAlarmLevel := AValue;
    Invalidate;
  end;
end;

procedure TDlpIndustrialTankGauge.SetFluidColor(const AValue: TColor);
begin
  if FFluidColor <> AValue then
  begin
    FFluidColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpIndustrialTankGauge.SetAlarmColor(const AValue: TColor);
begin
  if FAlarmColor <> AValue then
  begin
    FAlarmColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpIndustrialTankGauge.SetShowTicks(const AValue: Boolean);
begin
  if FShowTicks <> AValue then
  begin
    FShowTicks := AValue;
    Invalidate;
  end;
end;

procedure TDlpIndustrialTankGauge.SetUnitOfMeasure(const AValue: string);
begin
  if FUnitOfMeasure <> AValue then
  begin
    FUnitOfMeasure := AValue;
    Invalidate;
  end;
end;

function TDlpIndustrialTankGauge.GetLevelPercentage: Double;
begin
  if FCapacity <= 0 then
    Exit(0.0);
  Result := (FCurrentLevel / FCapacity) * 100.0;
  if Result > 100.0 then Result := 100.0;
  if Result < 0.0 then Result := 0.0;
end;

function TDlpIndustrialTankGauge.EvaluateAlarmState: TDlpTankAlarmState;
begin
  if FCurrentLevel > FCapacity then
    Result := asOverflow
  else if FCurrentLevel >= FHighAlarmLevel then
    Result := asHighAlarm
  else if FCurrentLevel <= FLowAlarmLevel then
    Result := asLowAlarm
  else
    Result := asNormal;
end;

procedure TDlpIndustrialTankGauge.Paint;
var
  TankLeft, TankRight, TankTop, TankBottom, TankHeight: Integer;
  FluidH, FluidTop: Integer;
  State: TDlpTankAlarmState;
  ActiveColor: TColor;
  i, TickY: Integer;
  TickPct: Double;
  LabelStr: string;
begin
  Canvas.Font.Assign(Self.Font);
  Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(Rect(0, 0, Width, Height));

  TankLeft := 16;
  TankRight := Width - 48;
  TankTop := 16;
  TankBottom := Height - 30;
  TankHeight := TankBottom - TankTop;

  State := EvaluateAlarmState;
  if (State = asHighAlarm) or (State = asOverflow) or (State = asLowAlarm) then
    ActiveColor := FAlarmColor
  else
    ActiveColor := FFluidColor;

  FluidH := Round((GetLevelPercentage / 100.0) * TankHeight);
  FluidTop := TankBottom - FluidH;

  Canvas.Brush.Color := ActiveColor;
  Canvas.Pen.Color := ActiveColor;
  if FluidH > 0 then
    Canvas.Rectangle(TankLeft + 3, FluidTop, TankRight - 3, TankBottom);

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := FTankWallColor;
  Canvas.Pen.Width := 3;

  Canvas.MoveTo(TankLeft, TankTop + 10);
  Canvas.LineTo(TankLeft, TankBottom);
  Canvas.LineTo(TankRight, TankBottom);
  Canvas.LineTo(TankRight, TankTop + 10);

  Canvas.Arc(TankLeft, TankTop, TankRight, TankTop + 20,
             TankRight, TankTop + 10, TankLeft, TankTop + 10);

  if FShowTicks then
  begin
    Canvas.Pen.Width := 1;
    Canvas.Pen.Color := $0064748B;
    Canvas.Font.Size := 7;
    Canvas.Font.Color := $0064748B;

    for i := 0 to 4 do
    begin
      TickPct := i / 4.0;
      TickY := TankBottom - Round(TickPct * TankHeight);
      Canvas.MoveTo(TankRight + 2, TickY);
      Canvas.LineTo(TankRight + 8, TickY);

      LabelStr := FormatFloat('0', FCapacity * TickPct);
      Canvas.TextOut(TankRight + 10, TickY - 5, LabelStr);
    end;
  end;

  Canvas.Font.Size := 8;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $001E293B;
  LabelStr := Format('%.1f %s (%.0f%%)', [FCurrentLevel, FUnitOfMeasure, GetLevelPercentage]);
  Canvas.TextOut(TankLeft, Height - 22, LabelStr);
end;

end.
