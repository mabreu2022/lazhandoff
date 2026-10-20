{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 28: Gráficos de Radar e Donut Vetorial (TDlpVectorDonutChart)
  Componente: TDlpVectorDonutChart
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL
  Descrição: Gráfico vetorial moderno em formato Donut (rosca) com trigonometria polar,
             orifício proporcional, detecção de hover em tempo real e adaptação
             a estilos claros e escuros da VCL.
==============================================================================}
unit DlpVectorDonutChart;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Math,
  Vcl.Controls,
  Vcl.Graphics;

type
  /// <summary>
  /// Item de coleção representando uma fatia da rosca gráfica.
  /// </summary>
  TDlpDonutSliceItem = class(TCollectionItem)
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

  /// <summary>
  /// Coleção fortemente tipada de fatias.
  /// </summary>
  TDlpDonutSliceCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TDlpDonutSliceItem;
    procedure SetItem(Index: Integer; const AValue: TDlpDonutSliceItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDlpDonutSliceItem;
    property Items[Index: Integer]: TDlpDonutSliceItem read GetItem write SetItem; default;
  end;

  /// <summary>
  /// Evento disparado quando o cursor do mouse sobrepõe uma fatia.
  /// </summary>
  TOnDlpSliceHoverEvent = procedure(Sender: TObject; SliceIndex: Integer;
    const Caption: string; Value: Double) of object;

  /// <summary>
  /// Gráfico vetorial Donut/Rosca para dashboards analíticos.
  /// </summary>
  TDlpVectorDonutChart = class(TGraphicControl)
  private
    FSlices: TDlpDonutSliceCollection;
    FHoleRatio: Double;
    FHoveredIndex: Integer;
    FOnSliceHover: TOnDlpSliceHoverEvent;

    procedure SetSlices(const AValue: TDlpDonutSliceCollection);
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
    property Slices: TDlpDonutSliceCollection read FSlices write SetSlices;
    property HoleRatio: Double read FHoleRatio write SetHoleRatio;
    property OnSliceHover: TOnDlpSliceHoverEvent read FOnSliceHover write FOnSliceHover;

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
  RegisterComponents('Delphi Component Engineering', [TDlpVectorDonutChart]);
end;

{ TDlpDonutSliceItem }

procedure TDlpDonutSliceItem.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Changed(False);
  end;
end;

procedure TDlpDonutSliceItem.SetValue(const AValue: Double);
begin
  if (AValue >= 0) and (FValue <> AValue) then
  begin
    FValue := AValue;
    Changed(False);
  end;
end;

procedure TDlpDonutSliceItem.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    Changed(False);
  end;
end;

{ TDlpDonutSliceCollection }

constructor TDlpDonutSliceCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDlpDonutSliceItem);
end;

function TDlpDonutSliceCollection.GetItem(Index: Integer): TDlpDonutSliceItem;
begin
  Result := TDlpDonutSliceItem(inherited GetItem(Index));
end;

procedure TDlpDonutSliceCollection.SetItem(Index: Integer; const AValue: TDlpDonutSliceItem);
begin
  inherited SetItem(Index, AValue);
end;

function TDlpDonutSliceCollection.Add: TDlpDonutSliceItem;
begin
  Result := TDlpDonutSliceItem(inherited Add);
end;

{ TDlpVectorDonutChart }

constructor TDlpVectorDonutChart.Create(AOwner: TComponent);
var
  S: TDlpDonutSliceItem;
begin
  inherited Create(AOwner);
  Width := 260;
  Height := 260;
  Color := clWhite;
  FHoleRatio := 0.55;
  FHoveredIndex := -1;

  FSlices := TDlpDonutSliceCollection.Create(Self);

  S := FSlices.Add; S.Caption := 'Desktop VCL/LCL'; S.Value := 45.0; S.Color := $00D07020;
  S := FSlices.Add; S.Caption := 'Serviços REST';   S.Value := 30.0; S.Color := $00116329;
  S := FSlices.Add; S.Caption := 'Mobile / IoT';    S.Value := 25.0; S.Color := $000550AE;
end;

destructor TDlpVectorDonutChart.Destroy;
begin
  FreeAndNil(FSlices);
  inherited Destroy;
end;

procedure TDlpVectorDonutChart.SetSlices(const AValue: TDlpDonutSliceCollection);
begin
  FSlices.Assign(AValue);
  Invalidate;
end;

procedure TDlpVectorDonutChart.SetHoleRatio(const AValue: Double);
begin
  if (AValue >= 0.1) and (AValue <= 0.9) and (AValue <> FHoleRatio) then
  begin
    FHoleRatio := AValue;
    Invalidate;
  end;
end;

function TDlpVectorDonutChart.GetTotalValue: Double;
var
  i: Integer;
begin
  Result := 0.0;
  for i := 0 to FSlices.Count - 1 do
    Result := Result + FSlices[i].Value;
end;

function TDlpVectorDonutChart.HitTestSlice(X, Y: Integer): Integer;
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

procedure TDlpVectorDonutChart.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TDlpVectorDonutChart.Paint;
var
  Cx, Cy, OuterR, InnerR: Integer;
  TotalVal, StartAngle, SweepAngle: Double;
  i, X1, Y1, X2, Y2: Integer;
  RadStart, RadEnd: Double;
begin
  Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(Rect(0, 0, Width, Height));

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

    Canvas.Pie(Cx - OuterR, Cy - OuterR, Cx + OuterR, Cy + OuterR, X1, Y1, X2, Y2);

    StartAngle := StartAngle + SweepAngle;
  end;

  Canvas.Brush.Color := Self.Color;
  Canvas.Pen.Color := Self.Color;
  Canvas.Ellipse(Cx - InnerR, Cy - InnerR, Cx + InnerR, Cy + InnerR);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Style := [fsBold];
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
