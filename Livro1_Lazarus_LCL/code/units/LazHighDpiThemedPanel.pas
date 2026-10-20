{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 12: High-DPI, Escalonamento e Suporte a Temas Modernos
  Componente: TLazHighDpiThemedPanel
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Painel visual corporativo com suporte nativo a High-DPI dinâmico
             (DoAutoAdjustLayout / Per-Monitor v2), renderização integrada
             com ThemeServices (Light/Dark Theme nativo do SO) e cálculo de
             escalonamento vetorial proporcional de fontes e métricas.
==============================================================================}
unit LazHighDpiThemedPanel;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Forms,
  Themes,
  LCLType,
  LCLIntf;

type
  { Modo de tema visual do painel }
  TLazThemeMode = (tmAutoSystem, tmForcedDark, tmForcedLight);

  {============================================================================
    Classe: TLazHighDpiThemedPanel
    Controle visual resiliente a mudanças de DPI e temas da LCL
  ============================================================================}
  TLazHighDpiThemedPanel = class(TCustomControl)
  private
    FThemeMode: TLazThemeMode;
    FHeaderCaption: string;
    FBaseHeaderHeight: Integer;
    FScaledHeaderHeight: Integer;
    FBorderRadius: Integer;
    FCurrentDPI: Integer;

    procedure SetThemeMode(const AValue: TLazThemeMode);
    procedure SetHeaderCaption(const AValue: string);
    procedure SetBaseHeaderHeight(const AValue: Integer);
    procedure SetBorderRadius(const AValue: Integer);

    function ScalePixels(AValue: Integer): Integer;
    procedure RecalculateMetrics;
  protected
    procedure Paint; override;
    procedure Resize; override;
    { Ponto de entrada oficial da LCL para escalonamento automático de DPI }
    procedure DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy;
      const AXProportion, AYProportion: Double); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ThemeMode: TLazThemeMode read FThemeMode write SetThemeMode default tmAutoSystem;
    property HeaderCaption: string read FHeaderCaption write SetHeaderCaption;
    property BaseHeaderHeight: Integer read FBaseHeaderHeight write SetBaseHeaderHeight default 36;
    property BorderRadius: Integer read FBorderRadius write SetBorderRadius default 8;

    { Propriedades herdadas publicadas }
    property Align;
    property Anchors;
    property Color default $00202020;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property PopupMenu;
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
  RegisterComponents('Engenharia Lazarus', [TLazHighDpiThemedPanel]);
end;

{ TLazHighDpiThemedPanel }

constructor TLazHighDpiThemedPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse, csClickEvents];

  FCurrentDPI := 96;
  FBaseHeaderHeight := 36;
  FBorderRadius := 8;
  FThemeMode := tmAutoSystem;
  FHeaderCaption := 'High-DPI Dynamic Themed Panel';

  Color := $00202020;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00F0F0F0;

  Width := 340;
  Height := 200;

  RecalculateMetrics;
end;

function TLazHighDpiThemedPanel.ScalePixels(AValue: Integer): Integer;
var
  PPI: Integer;
begin
  PPI := Font.PixelsPerInch;
  if PPI <= 0 then
    PPI := Screen.PixelsPerInch;
  if PPI <= 0 then
    PPI := 96;

  Result := MulDiv(AValue, PPI, 96);
end;

procedure TLazHighDpiThemedPanel.RecalculateMetrics;
begin
  FScaledHeaderHeight := ScalePixels(FBaseHeaderHeight);
  Invalidate;
end;

procedure TLazHighDpiThemedPanel.DoAutoAdjustLayout(
  const AMode: TLayoutAdjustmentPolicy; const AXProportion, AYProportion: Double);
begin
  inherited DoAutoAdjustLayout(AMode, AXProportion, AYProportion);

  { Atualiza métricas internas quando a LCL detectar troca de monitor ou escala de DPI }
  RecalculateMetrics;
end;

procedure TLazHighDpiThemedPanel.SetThemeMode(const AValue: TLazThemeMode);
begin
  if FThemeMode <> AValue then
  begin
    FThemeMode := AValue;
    Invalidate;
  end;
end;

procedure TLazHighDpiThemedPanel.SetHeaderCaption(const AValue: string);
begin
  if FHeaderCaption <> AValue then
  begin
    FHeaderCaption := AValue;
    Invalidate;
  end;
end;

procedure TLazHighDpiThemedPanel.SetBaseHeaderHeight(const AValue: Integer);
begin
  if (FBaseHeaderHeight <> AValue) and (AValue >= 20) then
  begin
    FBaseHeaderHeight := AValue;
    RecalculateMetrics;
  end;
end;

procedure TLazHighDpiThemedPanel.SetBorderRadius(const AValue: Integer);
begin
  if (FBorderRadius <> AValue) and (AValue >= 0) then
  begin
    FBorderRadius := AValue;
    Invalidate;
  end;
end;

procedure TLazHighDpiThemedPanel.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TLazHighDpiThemedPanel.Paint;
var
  HeaderR, TextR: TRect;
  BgColor, HdrColor, TextColor, BorderColor: TColor;
  IsDark: Boolean;
  ScaledRadius: Integer;
  DpiBadge: string;
begin
  ScaledRadius := ScalePixels(FBorderRadius);

  { Determina tema visual ativo }
  case FThemeMode of
    tmForcedDark:  IsDark := True;
    tmForcedLight: IsDark := False;
    tmAutoSystem:
      begin
        { Consulta ThemeServices da LCL }
        if ThemeServices.ThemesEnabled then
          IsDark := (ColorToRGB(clWindow) < $00808080)
        else
          IsDark := True;
      end;
  end;

  if IsDark then
  begin
    BgColor := $001A1A1A;
    HdrColor := $00262626;
    TextColor := $00F0F0F0;
    BorderColor := $00404040;
  end
  else
  begin
    BgColor := $00F5F5F5;
    HdrColor := $00E8E8E8;
    TextColor := $001E1E1E;
    BorderColor := $00D0D0D0;
  end;

  { 1. Fundo do Painel }
  Canvas.Brush.Color := BgColor;
  Canvas.Pen.Color := BorderColor;
  Canvas.RoundRect(0, 0, Width, Height, ScaledRadius, ScaledRadius);

  { 2. Cabeçalho }
  HeaderR := Rect(0, 0, Width, FScaledHeaderHeight);
  Canvas.Brush.Color := HdrColor;
  Canvas.FillRect(HeaderR);

  Canvas.Pen.Color := BorderColor;
  Canvas.MoveTo(0, FScaledHeaderHeight);
  Canvas.LineTo(Width, FScaledHeaderHeight);

  { 3. Texto do Título Escalonado }
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := TextColor;
  Canvas.Brush.Style := bsClear;

  TextR := Rect(ScalePixels(12), 0, Width - ScalePixels(80), FScaledHeaderHeight);
  LCLIntf.DrawText(Canvas.Handle, PChar(FHeaderCaption), Length(FHeaderCaption),
    TextR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  { 4. Badge Informativo de DPI Atual }
  DpiBadge := Format('%d DPI', [Font.PixelsPerInch]);
  Canvas.Font.Size := 7;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $0000C853;
  Canvas.TextOut(Width - Canvas.TextWidth(DpiBadge) - ScalePixels(12),
    (FScaledHeaderHeight - Canvas.TextHeight(DpiBadge)) div 2, DpiBadge);
end;

end.
