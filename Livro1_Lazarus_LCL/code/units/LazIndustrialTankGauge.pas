{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 27: Medidores de Nível e Tanques Industriais (TLazIndustrialTankGauge)
  Componente: TLazIndustrialTankGauge
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Controle visual gráfico vetorial para simulação de tanques e reservatórios
             industriais, com volume proporcional de fluidos, gradientes de alerta,
             linhas de calibração graduadas e alarmes de nível crítico e transbordo.
==============================================================================}
unit LazIndustrialTankGauge;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics;

type
  { Estado operacional do tanque }
  TTankAlarmState = (asNormal, asLowAlarm, asHighAlarm, asOverflow);

  { Assinatura de evento para alarme de transbordo ou nível crítico }
  TOnTankAlarmEvent = procedure(Sender: TObject; State: TTankAlarmState;
    CurrentLevel: Double) of object;

  {============================================================================
    Classe: TLazIndustrialTankGauge
    Medidor visual de nível para plantas industriais e automação predial
  ============================================================================}
  TLazIndustrialTankGauge = class(TGraphicControl)
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
    FOnAlarmTriggered: TOnTankAlarmEvent;

    procedure SetCapacity(const AValue: Double);
    procedure SetCurrentLevel(const AValue: Double);
    procedure SetLowAlarmLevel(const AValue: Double);
    procedure SetHighAlarmLevel(const AValue: Double);
    procedure SetFluidColor(const AValue: TColor);
    procedure SetAlarmColor(const AValue: TColor);
    procedure SetShowTicks(const AValue: Boolean);
    procedure SetUnitOfMeasure(const AValue: string);
    function EvaluateAlarmState: TTankAlarmState;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;

    function GetLevelPercentage: Double;
  published
    property Capacity: Double read FCapacity write SetCapacity;
    property CurrentLevel: Double read FCurrentLevel write SetCurrentLevel;
    property LowAlarmLevel: Double read FLowAlarmLevel write SetLowAlarmLevel;
    property HighAlarmLevel: Double read FHighAlarmLevel write SetHighAlarmLevel;
    property FluidColor: TColor read FFluidColor write SetFluidColor default $00D07020; // Azul petróleo
    property AlarmColor: TColor read FAlarmColor write SetAlarmColor default $002A2AE0; // Vermelho alarme
    property TankWallColor: TColor read FTankWallColor write FTankWallColor default $0094A3B8;
    property ShowTicks: Boolean read FShowTicks write SetShowTicks default True;
    property UnitOfMeasure: string read FUnitOfMeasure write SetUnitOfMeasure;
    property OnAlarmTriggered: TOnTankAlarmEvent read FOnAlarmTriggered write FOnAlarmTriggered;

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
  RegisterComponents('Lazarus Component Engineering', [TLazIndustrialTankGauge]);
end;

{ TLazIndustrialTankGauge }

constructor TLazIndustrialTankGauge.Create(AOwner: TComponent);
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

procedure TLazIndustrialTankGauge.SetCapacity(const AValue: Double);
begin
  if (AValue > 0) and (AValue <> FCapacity) then
  begin
    FCapacity := AValue;
    Invalidate;
  end;
end;

procedure TLazIndustrialTankGauge.SetCurrentLevel(const AValue: Double);
var
  OldState, NewState: TTankAlarmState;
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

procedure TLazIndustrialTankGauge.SetLowAlarmLevel(const AValue: Double);
begin
  if AValue <> FLowAlarmLevel then
  begin
    FLowAlarmLevel := AValue;
    Invalidate;
  end;
end;

procedure TLazIndustrialTankGauge.SetHighAlarmLevel(const AValue: Double);
begin
  if AValue <> FHighAlarmLevel then
  begin
    FHighAlarmLevel := AValue;
    Invalidate;
  end;
end;

procedure TLazIndustrialTankGauge.SetFluidColor(const AValue: TColor);
begin
  if FFluidColor <> AValue then
  begin
    FFluidColor := AValue;
    Invalidate;
  end;
end;

procedure TLazIndustrialTankGauge.SetAlarmColor(const AValue: TColor);
begin
  if FAlarmColor <> AValue then
  begin
    FAlarmColor := AValue;
    Invalidate;
  end;
end;

procedure TLazIndustrialTankGauge.SetShowTicks(const AValue: Boolean);
begin
  if FShowTicks <> AValue then
  begin
    FShowTicks := AValue;
    Invalidate;
  end;
end;

procedure TLazIndustrialTankGauge.SetUnitOfMeasure(const AValue: string);
begin
  if FUnitOfMeasure <> AValue then
  begin
    FUnitOfMeasure := AValue;
    Invalidate;
  end;
end;

function TLazIndustrialTankGauge.GetLevelPercentage: Double;
begin
  if FCapacity <= 0 then
    Exit(0.0);
  Result := (FCurrentLevel / FCapacity) * 100.0;
  if Result > 100.0 then Result := 100.0;
  if Result < 0.0 then Result := 0.0;
end;

function TLazIndustrialTankGauge.EvaluateAlarmState: TTankAlarmState;
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

procedure TLazIndustrialTankGauge.Paint;
var
  TankLeft, TankRight, TankTop, TankBottom, TankHeight, TankWidth: Integer;
  FluidH, FluidTop: Integer;
  State: TTankAlarmState;
  ActiveColor: TColor;
  i, TickY: Integer;
  TickPct: Double;
  LabelStr: string;
begin
  Canvas.Font.Assign(Self.Font);
  Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(0, 0, Width, Height);

  TankLeft := 16;
  TankRight := Width - 48;
  TankTop := 16;
  TankBottom := Height - 30;
  TankWidth := TankRight - TankLeft;
  TankHeight := TankBottom - TankTop;

  State := EvaluateAlarmState;
  if (State = asHighAlarm) or (State = asOverflow) or (State = asLowAlarm) then
    ActiveColor := FAlarmColor
  else
    ActiveColor := FFluidColor;

  // Desenho do fluido
  FluidH := Round((GetLevelPercentage / 100.0) * TankHeight);
  FluidTop := TankBottom - FluidH;

  Canvas.Brush.Color := ActiveColor;
  Canvas.Pen.Color := ActiveColor;
  if FluidH > 0 then
    Canvas.Rectangle(TankLeft + 3, FluidTop, TankRight - 3, TankBottom);

  // Paredes e topo em cúpula do tanque cilíndrico
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := FTankWallColor;
  Canvas.Pen.Width := 3;

  // Corpo do tanque
  Canvas.MoveTo(TankLeft, TankTop + 10);
  Canvas.LineTo(TankLeft, TankBottom);
  Canvas.LineTo(TankRight, TankBottom);
  Canvas.LineTo(TankRight, TankTop + 10);

  // Cúpula superior
  Canvas.Arc(TankLeft, TankTop, TankRight, TankTop + 20,
             TankRight, TankTop + 10, TankLeft, TankTop + 10);

  // Graduações e Ticks
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

  // Rótulo numérico inferior
  Canvas.Font.Size := 8;
  Canvas.Font.Bold := True;
  Canvas.Font.Color := #$1e293b;
  LabelStr := Format('%.1f %s (%.0f%%)', [FCurrentLevel, FUnitOfMeasure, GetLevelPercentage]);
  Canvas.TextOut(TankLeft, Height - 22, LabelStr);
end;

end.
