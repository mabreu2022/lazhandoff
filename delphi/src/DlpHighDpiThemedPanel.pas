{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 12: High-DPI, Escalonamento e Suporte a Temas Modernos
  Componente: TDlpHighDpiThemedPanel
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Painel corporativo moderno com suporte profundo a High-DPI
             (Per-Monitor v2 / ChangeScale / ScaleForPPI), integração com
             VCL Styles / TStyleManager e renderização proporcional nítida
             em qualquer fator de escala (100% a 400%).
==============================================================================}
unit DlpHighDpiThemedPanel;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.Themes;

type
  { Modo de estilo do painel }
  TDlpPanelStyleMode = (psmAutoVclStyle, psmForcedDark, psmForcedLight);

  {============================================================================
    Classe: TDlpHighDpiThemedPanel
    Controle visual resiliente a High-DPI e estilos VCL no Delphi 12
  ============================================================================}
  TDlpHighDpiThemedPanel = class(TCustomControl)
  private
    FStyleMode: TDlpPanelStyleMode;
    FHeaderTitle: string;
    FBaseHeaderHeight: Integer;
    FScaledHeaderHeight: Integer;
    FBaseBorderRadius: Integer;
    FScaledBorderRadius: Integer;

    procedure SetStyleMode(const AValue: TDlpPanelStyleMode);
    procedure SetHeaderTitle(const AValue: string);
    procedure SetBaseHeaderHeight(const AValue: Integer);
    procedure SetBaseBorderRadius(const AValue: Integer);

    function ScaleMetric(AValue: Integer): Integer;
    procedure RecalculateScaledMetrics;
  protected
    procedure Paint; override;
    procedure Resize; override;
    { Métodos oficiais do Delphi para escalonamento Per-Monitor v2 }
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ScaleForPPI(NewPPI: Integer); override;
  published
    property StyleMode: TDlpPanelStyleMode read FStyleMode write SetStyleMode default psmAutoVclStyle;
    property HeaderTitle: string read FHeaderTitle write SetHeaderTitle;
    property BaseHeaderHeight: Integer read FBaseHeaderHeight write SetBaseHeaderHeight default 38;
    property BaseBorderRadius: Integer read FBaseBorderRadius write SetBaseBorderRadius default 10;

    { Propriedades herdadas publicadas }
    property Align;
    property Anchors;
    property Color default $001E1E1E;
    property DoubleBuffered default True;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Eventos }
    property OnClick;
    property OnDblClick;
    property OnResize;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpHighDpiThemedPanel]);
end;

{ TDlpHighDpiThemedPanel }

constructor TDlpHighDpiThemedPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse, csClickEvents];
  DoubleBuffered := True;

  FBaseHeaderHeight := 38;
  FBaseBorderRadius := 10;
  FStyleMode := psmAutoVclStyle;
  FHeaderTitle := 'Per-Monitor v2 High-DPI Panel';

  Width := 350;
  Height := 210;
  Color := $001E1E1E;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00F0F0F0;

  RecalculateScaledMetrics;
end;

function TDlpHighDpiThemedPanel.ScaleMetric(AValue: Integer): Integer;
var
  TargetPPI: Integer;
begin
  TargetPPI := CurrentPPI;
  if TargetPPI <= 0 then
    TargetPPI := 96;

  Result := MulDiv(AValue, TargetPPI, 96);
end;

procedure TDlpHighDpiThemedPanel.RecalculateScaledMetrics;
begin
  FScaledHeaderHeight := ScaleMetric(FBaseHeaderHeight);
  FScaledBorderRadius := ScaleMetric(FBaseBorderRadius);
  Invalidate;
end;

procedure TDlpHighDpiThemedPanel.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited ChangeScale(M, D, isDpiChange);
  RecalculateScaledMetrics;
end;

procedure TDlpHighDpiThemedPanel.ScaleForPPI(NewPPI: Integer);
begin
  inherited ScaleForPPI(NewPPI);
  RecalculateScaledMetrics;
end;

procedure TDlpHighDpiThemedPanel.SetStyleMode(const AValue: TDlpPanelStyleMode);
begin
  if FStyleMode <> AValue then
  begin
    FStyleMode := AValue;
    Invalidate;
  end;
end;

procedure TDlpHighDpiThemedPanel.SetHeaderTitle(const AValue: string);
begin
  if FHeaderTitle <> AValue then
  begin
    FHeaderTitle := AValue;
    Invalidate;
  end;
end;

procedure TDlpHighDpiThemedPanel.SetBaseHeaderHeight(const AValue: Integer);
begin
  if (FBaseHeaderHeight <> AValue) and (AValue >= 20) then
  begin
    FBaseHeaderHeight := AValue;
    RecalculateScaledMetrics;
  end;
end;

procedure TDlpHighDpiThemedPanel.SetBaseBorderRadius(const AValue: Integer);
begin
  if (FBaseBorderRadius <> AValue) and (AValue >= 0) then
  begin
    FBaseBorderRadius := AValue;
    RecalculateScaledMetrics;
  end;
end;

procedure TDlpHighDpiThemedPanel.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TDlpHighDpiThemedPanel.Paint;
var
  HeaderR, TextR: TRect;
  BgColor, HdrColor, TextColor, BorderColor: TColor;
  IsDarkTheme: Boolean;
  DpiBadgeStr: string;
begin
  { Avalia estilo ativo }
  case FStyleMode of
    psmForcedDark:
      IsDarkTheme := True;
    psmForcedLight:
      IsDarkTheme := False;
    psmAutoVclStyle:
      begin
        if StyleServices.Enabled then
          IsDarkTheme := (ColorToRGB(StyleServices.GetSystemColor(clWindow)) < $00808080)
        else
          IsDarkTheme := True;
      end;
  end;

  if IsDarkTheme then
  begin
    BgColor := $001A1A1A;
    HdrColor := $00262626;
    TextColor := $00F0F0F0;
    BorderColor := $00404040;
  end
  else
  begin
    BgColor := $00F8F8F8;
    HdrColor := $00EEEEEE;
    TextColor := $00202020;
    BorderColor := $00CCCCCC;
  end;

  { 1. Fundo do Contêiner Escalonado }
  Canvas.Brush.Color := BgColor;
  Canvas.Pen.Color := BorderColor;
  Canvas.RoundRect(0, 0, Width, Height, FScaledBorderRadius, FScaledBorderRadius);

  { 2. Cabeçalho }
  HeaderR := Rect(0, 0, Width, FScaledHeaderHeight);
  Canvas.Brush.Color := HdrColor;
  Canvas.FillRect(HeaderR);

  Canvas.Pen.Color := BorderColor;
  Canvas.MoveTo(0, FScaledHeaderHeight);
  Canvas.LineTo(Width, FScaledHeaderHeight);

  { 3. Título Escalonado }
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := TextColor;
  Canvas.Brush.Style := bsClear;

  TextR := Rect(ScaleMetric(14), 0, Width - ScaleMetric(90), FScaledHeaderHeight);
  Vcl.Graphics.DrawText(Canvas.Handle, PChar(FHeaderTitle), Length(FHeaderTitle),
    TextR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  { 4. Badge Informativo de Escala e DPI }
  DpiBadgeStr := Format('%d DPI (%d%%)', [CurrentPPI, MulDiv(CurrentPPI, 100, 96)]);
  Canvas.Font.Size := 7;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $0000C853;
  Canvas.TextOut(Width - Canvas.TextWidth(DpiBadgeStr) - ScaleMetric(14),
    (FScaledHeaderHeight - Canvas.TextHeight(DpiBadgeStr)) div 2, DpiBadgeStr);
end;

end.
