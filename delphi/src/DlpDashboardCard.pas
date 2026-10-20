{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 07: Component Editors e Ações de Design-Time (Verbos)
  Componente: TDlpDashboardCard
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Cartão de métricas e KPIs modernos para dashboards corporativos,
             com indicadores dinâmicos de tendência, suporte a Double Buffering
             e integração com Component Editor via verbos de menu de contexto.
==============================================================================}
unit DlpDashboardCard;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms;

type
  { Indicador de tendência da métrica }
  TDlpTrendDirection = (tdUp, tdDown, tdNeutral);

  {============================================================================
    Classe: TDlpDashboardCard
    Controle visual de cartão de KPI com métrica e tendência
  ============================================================================}
  TDlpDashboardCard = class(TCustomControl)
  private
    FMetricTitle: string;
    FMetricValue: string;
    FMetricSubtitle: string;
    FTrendDirection: TDlpTrendDirection;
    FTrendPercentText: string;
    FCardColor: TColor;
    FAccentColor: TColor;

    procedure SetMetricTitle(const AValue: string);
    procedure SetMetricValue(const AValue: string);
    procedure SetMetricSubtitle(const AValue: string);
    procedure SetTrendDirection(const AValue: TDlpTrendDirection);
    procedure SetTrendPercentText(const AValue: string);
    procedure SetCardColor(const AValue: TColor);
    procedure SetAccentColor(const AValue: TColor);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;

    { Métodos consumidos pelo Component Editor no Design-Time }
    procedure CycleTrend;
    procedure ResetToSampleMetrics;
    procedure InvertPalette;
  published
    property MetricTitle: string read FMetricTitle write SetMetricTitle;
    property MetricValue: string read FMetricValue write SetMetricValue;
    property MetricSubtitle: string read FMetricSubtitle write SetMetricSubtitle;
    property TrendDirection: TDlpTrendDirection read FTrendDirection write SetTrendDirection default tdUp;
    property TrendPercentText: string read FTrendPercentText write SetTrendPercentText;
    property CardColor: TColor read FCardColor write SetCardColor default $00222222;
    property AccentColor: TColor read FAccentColor write SetAccentColor default $0000C853;

    { Propriedades VCL convencionais }
    property Align;
    property Anchors;
    property DoubleBuffered default True;
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
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpDashboardCard]);
end;

{ TDlpDashboardCard }

constructor TDlpDashboardCard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  Width := 260;
  Height := 140;
  FCardColor := $00222222;
  FAccentColor := $0000C853; // Verde moderno
  FMetricTitle := 'RECEITA RECORRENTE (MRR)';
  FMetricValue := 'R$ 148.520';
  FMetricSubtitle := 'Comparado ao mês anterior';
  FTrendDirection := tdUp;
  FTrendPercentText := '+14.2%';

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := clWhite;
end;

procedure TDlpDashboardCard.SetMetricTitle(const AValue: string);
begin
  if FMetricTitle <> AValue then
  begin
    FMetricTitle := AValue;
    Invalidate;
  end;
end;

procedure TDlpDashboardCard.SetMetricValue(const AValue: string);
begin
  if FMetricValue <> AValue then
  begin
    FMetricValue := AValue;
    Invalidate;
  end;
end;

procedure TDlpDashboardCard.SetMetricSubtitle(const AValue: string);
begin
  if FMetricSubtitle <> AValue then
  begin
    FMetricSubtitle := AValue;
    Invalidate;
  end;
end;

procedure TDlpDashboardCard.SetTrendDirection(const AValue: TDlpTrendDirection);
begin
  if FTrendDirection <> AValue then
  begin
    FTrendDirection := AValue;
    Invalidate;
  end;
end;

procedure TDlpDashboardCard.SetTrendPercentText(const AValue: string);
begin
  if FTrendPercentText <> AValue then
  begin
    FTrendPercentText := AValue;
    Invalidate;
  end;
end;

procedure TDlpDashboardCard.SetCardColor(const AValue: TColor);
begin
  if FCardColor <> AValue then
  begin
    FCardColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpDashboardCard.SetAccentColor(const AValue: TColor);
begin
  if FAccentColor <> AValue then
  begin
    FAccentColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpDashboardCard.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TDlpDashboardCard.Paint;
var
  R, BadgeR: TRect;
  TrendSymbol: string;
  TrendBgColor: TColor;
begin
  R := ClientRect;

  { 1. Fundo do Cartão com bordas arredondadas e sombra suave }
  Canvas.Brush.Color := FCardColor;
  Canvas.Pen.Color := $00383838;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 12, 12);

  { 2. Barra de Destaque Superior }
  Canvas.Brush.Color := FAccentColor;
  Canvas.FillRect(Rect(R.Left + 16, R.Top, R.Right - 16, R.Top + 4));

  { 3. Título da Métrica }
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $009E9E9E;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(R.Left + 18, R.Top + 16, FMetricTitle);

  { 4. Valor Principal da Métrica (Grande) }
  Canvas.Font.Size := 20;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  Canvas.TextOut(R.Left + 18, R.Top + 38, FMetricValue);

  { 5. Badge de Tendência }
  case FTrendDirection of
    tdUp:
      begin
        TrendSymbol := '▲ ' + FTrendPercentText;
        TrendBgColor := $001B5E20; // Verde escuro
      end;
    tdDown:
      begin
        TrendSymbol := '▼ ' + FTrendPercentText;
        TrendBgColor := $001A1A8B; // Vermelho escuro
      end;
    tdNeutral:
      begin
        TrendSymbol := '● ' + FTrendPercentText;
        TrendBgColor := $00424242; // Cinza
      end;
  end;

  BadgeR := Rect(R.Left + 18, R.Top + 88, R.Left + 18 + Canvas.TextWidth(TrendSymbol) + 20, R.Top + 112);
  Canvas.Brush.Color := TrendBgColor;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := TrendBgColor;
  Canvas.RoundRect(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom, 6, 6);

  Canvas.Font.Size := 8;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  Canvas.Brush.Style := bsClear;
  Canvas.TextRect(BadgeR, BadgeR.Left + 8, BadgeR.Top + 4, TrendSymbol);

  { 6. Subtítulo }
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  Canvas.Font.Color := $00757575;
  Canvas.TextOut(BadgeR.Right + 8, R.Top + 93, FMetricSubtitle);
end;

procedure TDlpDashboardCard.CycleTrend;
begin
  case FTrendDirection of
    tdUp:
      begin
        TrendDirection := tdDown;
        TrendPercentText := '-5.8%';
      end;
    tdDown:
      begin
        TrendDirection := tdNeutral;
        TrendPercentText := '0.0%';
      end;
    tdNeutral:
      begin
        TrendDirection := tdUp;
        TrendPercentText := '+14.2%';
      end;
  end;
end;

procedure TDlpDashboardCard.ResetToSampleMetrics;
begin
  FMetricTitle := 'NOVOS CLIENTES';
  FMetricValue := '1.248';
  FTrendDirection := tdUp;
  FTrendPercentText := '+28.4%';
  FMetricSubtitle := 'No período vigente';
  Invalidate;
end;

procedure TDlpDashboardCard.InvertPalette;
begin
  if FCardColor = $00222222 then
  begin
    FCardColor := $00FAFAFA;
    Font.Color := $00212121;
  end
  else
  begin
    FCardColor := $00222222;
    Font.Color := clWhite;
  end;
  Invalidate;
end;

end.
