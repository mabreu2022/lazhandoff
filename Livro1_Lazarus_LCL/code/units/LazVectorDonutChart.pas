{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 28: Gráficos de Radar e Donut Vetorial (TLazVectorDonutChart)
  Componente: TLazVectorDonutChart
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Gráfico vetorial moderno em formato Donut (rosca) com trigonometria
             nativa, orifício proporcional, realce de fatias no hover por cálculo
             angular polar e suporte a temas claros e escuros.
==============================================================================}
unit LazVectorDonutChart;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Math;

type
  { Item que representa uma fatia individual da rosca }
  TLazDonutSliceItem = class(TCollectionItem)
  private
    FCaption: string;
    FValue: Double;
    FColor: TColor;
    procedure SetCaption(const AValue: string);
    procedure SetValue(const AValue: Double);
    procedure SetColor(const AValue: TColor);
  published
    property Caption: string read FCaption write SetCaption;
    property Value: Double read FValue write SetValue;
    property Color: TColor read FColor write SetColor;
  end;

  { Coleção de fatias }
  TLazDonutSliceCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TLazDonutSliceItem;
    procedure SetItem(Index: Integer; const AValue: TLazDonutSliceItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TLazDonutSliceItem;
    property Items[Index: Integer]: TLazDonutSliceItem read GetItem write SetItem; default;
  end;

  { Evento de seleção de fatia no hover ou clique }
  TOnSliceHoverEvent = procedure(Sender: TObject; SliceIndex: Integer;
    const Caption: string; Value: Double) of object;

  {============================================================================
    Classe: TLazVectorDonutChart
    Controle gráfico de rosca (Donut) vetorial
  ============================================================================}
  TLazVectorDonutChart = class(TGraphicControl)
  private
    FSlices: TLazDonutSliceCollection;
    FHoleRatio: Double;
    FHoveredIndex: Integer;
    FOnSliceHover: TOnSliceHoverEvent;

    procedure SetSlices(const AValue: TLazDonutSliceCollection);
    procedure SetHoleRatio(const AValue: Double);
    function GetTotalValue: Double;
    function HitTestSlice(X, Y: Integer): Integer;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property HoveredIndex: Integer read FHoveredIndex;
  published
    property Slices: TLazDonutSliceCollection read FSlices write SetSlices;
    property HoleRatio: Double read FHoleRatio write SetHoleRatio;
    property OnSliceHover: TOnSliceHoverEvent read FOnSliceHover write FOnSliceHover;

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
  RegisterComponents('Lazarus Component Engineering', [TLazVectorDonutChart]);
end;

{ TLazDonutSliceItem }

procedure TLazDonutSliceItem.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Changed(False);
  end;
end;

procedure TLazDonutSliceItem.SetValue(const AValue: Double);
begin
  if (AValue >= 0) and (FValue <> AValue) then
  begin
    FValue := AValue;
    Changed(False);
  end;
end;

procedure TLazDonutSliceItem.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    Changed(False);
  end;
end;

{ TLazDonutSliceCollection }

constructor TLazDonutSliceCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TLazDonutSliceItem);
end;

function TLazDonutSliceCollection.GetItem(Index: Integer): TLazDonutSliceItem;
begin
  Result := TLazDonutSliceItem(inherited GetItem(Index));
end;

procedure TLazDonutSliceCollection.SetItem(Index: Integer; const AValue: TLazDonutSliceItem);
begin
  inherited SetItem(Index, AValue);
end;

function TLazDonutSliceCollection.Add: TLazDonutSliceItem;
begin
  Result := TLazDonutSliceItem(inherited Add);
end;

{ TLazVectorDonutChart }

constructor TLazVectorDonutChart.Create(AOwner: TComponent);
var
  S: TLazDonutSliceItem;
begin
  inherited Create(AOwner);
  Width := 260;
  Height := 260;
  Color := clWhite;
  FHoleRatio := 0.55;
  FHoveredIndex := -1;

  FSlices := TLazDonutSliceCollection.Create(Self);

  // Amostras padrão
  S := FSlices.Add; S.Caption := 'Desktop VCL/LCL'; S.Value := 45.0; S.Color := $00D07020;
  S := FSlices.Add; S.Caption := 'Serviços REST';   S.Value := 30.0; S.Color := $00116329;
  S := FSlices.Add; S.Caption := 'Mobile / IoT';    S.Value := 25.0; S.Color := $000550AE;
end;

destructor TLazVectorDonutChart.Destroy;
begin
  FreeAndNil(FSlices);
  inherited Destroy;
end;

procedure TLazVectorDonutChart.SetSlices(const AValue: TLazDonutSliceCollection);
begin
  FSlices.Assign(AValue);
  Invalidate;
end;

procedure TLazVectorDonutChart.SetHoleRatio(const AValue: Double);
begin
  if (AValue >= 0.1) and (AValue <= 0.9) and (AValue <> FHoleRatio) then
  begin
    FHoleRatio := AValue;
    Invalidate;
  end;
end;

function TLazVectorDonutChart.GetTotalValue: Double;
var
  i: Integer;
begin
  Result := 0.0;
  for i := 0 to FSlices.Count - 1 do
    Result := Result + FSlices[i].Value;
end;

function TLazVectorDonutChart.HitTestSlice(X, Y: Integer): Integer;
var
  Cx, Cy, OuterR, InnerR, DistSq: Integer;
  Dist, AngleRad, AngleDeg, TotalVal, CurrentAngle, SweepAngle: Double;
  i: Integer;
begin
  Result := -1;
  Cx := Width div 2;
  Cy := Height div 2;
  OuterR := Min(Cx, Cy) - 16;
  InnerR := Round(OuterR * FHoleRatio);

  DistSq := Sqr(X - Cx) + Sqr(Y - Cy);
  Dist := Sqrt(DistSq);

  if (Dist < InnerR) or (Dist > OuterR) then
    Exit;

  // Ângulo polar relativo ao centro em radianos
  AngleRad := ArcTan2(Y - Cy, X - Cx);
  AngleDeg := RadToDeg(AngleRad);
  if AngleDeg < 0 then
    AngleDeg := AngleDeg + 360.0;

  TotalVal := GetTotalValue;
  if TotalVal <= 0 then
    Exit;

  CurrentAngle := 0.0;
  for i := 0 to FSlices.Count - 1 do
  begin
    SweepAngle := (FSlices[i].Value / TotalVal) * 360.0;
    if (AngleDeg >= CurrentAngle) and (AngleDeg < CurrentAngle + SweepAngle) then
      Exit(i);
    CurrentAngle := CurrentAngle + SweepAngle;
  end;
end;

procedure TLazVectorDonutChart.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIdx: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  NewIdx := HitTestSlice(X, Y);
  if NewIdx <> FHoveredIndex then
  begin
    FHoveredIndex := NewIdx;
    if (FHoveredIndex >= 0) and (FHoveredIndex < FSlices.Count) and Assigned(FOnSliceHover) then
      FOnSliceHover(Self, FHoveredIndex, FSlices[FHoveredIndex].Caption, FSlices[FHoveredIndex].Value);
    Invalidate;
  end;
end;

procedure TLazVectorDonutChart.Paint;
var
  Cx, Cy, OuterR, InnerR: Integer;
  TotalVal, StartAngle, SweepAngle: Double;
  i, X1, Y1, X2, Y2: Integer;
  RadStart, RadEnd: Double;
begin
  Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(0, 0, Width, Height);

  TotalVal := GetTotalValue;
  if TotalVal <= 0 then
    Exit;

  Cx := Width div 2;
  Cy := Height div 2;
  OuterR := Min(Cx, Cy) - 16;
  InnerR := Round(OuterR * FHoleRatio);

  StartAngle := 0.0;
  for i := 0 to FSlices.Count - 1 do
  begin
    SweepAngle := (FSlices[i].Value / TotalVal) * 360.0;
    RadStart := DegToRad(StartAngle);
    RadEnd := DegToRad(StartAngle + SweepAngle);

    Canvas.Brush.Color := FSlices[i].Color;
    Canvas.Pen.Color := Self.Color;
    Canvas.Pen.Width := 2;

    X1 := Cx + Round(OuterR * Cos(RadStart));
    Y1 := Cy + Round(OuterR * Sin(RadStart));
    X2 := Cx + Round(OuterR * Cos(RadEnd));
    Y2 := Cy + Round(OuterR * Sin(RadEnd));

    // Desenha setor circular
    Canvas.Pie(Cx - OuterR, Cy - OuterR, Cx + OuterR, Cy + OuterR, X1, Y1, X2, Y2);

    StartAngle := StartAngle + SweepAngle;
  end;

  // Desenha orifício central (Donut Hole)
  Canvas.Brush.Color := Self.Color;
  Canvas.Pen.Color := Self.Color;
  Canvas.Ellipse(Cx - InnerR, Cy - InnerR, Cx + InnerR, Cy + InnerR);

  // Rótulo central se houver fatia em foco
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Bold := True;
  Canvas.Font.Size := 9;
  Canvas.Font.Color := $001E293B;

  if (FHoveredIndex >= 0) and (FHoveredIndex < FSlices.Count) then
  begin
    Canvas.TextOut(Cx - (Canvas.TextWidth(FSlices[FHoveredIndex].Caption) div 2),
                   Cy - 10, FSlices[FHoveredIndex].Caption);
    Canvas.TextOut(Cx - 20, Cy + 6, Format('%.1f%%', [(FSlices[FHoveredIndex].Value / TotalVal) * 100.0]));
  end
  else
  begin
    Canvas.TextOut(Cx - 22, Cy - 6, 'Total');
  end;
end;

end.
