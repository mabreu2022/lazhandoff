{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 10: Controles Visuais Janelados (TWinControl)
  Componente: TLazAccordionContainer
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Painel colapsável sanfonado (Accordion Container) construído sobre
             TCustomControl (TWinControl), com Handle nativo próprio, suporte
             a foco, teclado, animação fluida de abertura/fechamento e aceitação
             plena de controles filhos em tempo de design (csAcceptsControls).
==============================================================================}
unit LazAccordionContainer;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Forms,
  ExtCtrls,
  LCLType,
  LCLIntf;

type
  { Evento disparado quando o estado do painel é alternado }
  TOnAccordionToggleEvent = procedure(Sender: TObject; IsCollapsed: Boolean) of object;

  {============================================================================
    Classe: TLazAccordionContainer
    Controle janelado contêiner expansível com foco e teclado
  ============================================================================}
  TLazAccordionContainer = class(TCustomControl)
  private
    FCollapsed: Boolean;
    FHeaderHeight: Integer;
    FExpandedHeight: Integer;
    FHeaderCaption: string;
    FHeaderColor: TColor;
    FHeaderHoverColor: TColor;
    FBorderColor: TColor;
    FIsHovered: Boolean;
    FAnimationTimer: TTimer;
    FTargetHeight: Integer;
    FOnToggle: TOnAccordionToggleEvent;

    procedure SetCollapsed(const AValue: Boolean);
    procedure SetHeaderHeight(const AValue: Integer);
    procedure SetExpandedHeight(const AValue: Integer);
    procedure SetHeaderCaption(const AValue: string);
    procedure SetHeaderColor(const AValue: TColor);
    procedure SetHeaderHoverColor(const AValue: TColor);
    procedure SetBorderColor(const AValue: TColor);

    procedure OnTimerStep(Sender: TObject);
    procedure ToggleState;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos públicos de expansão }
    procedure Expand;
    procedure Collapse;
  published
    property Collapsed: Boolean read FCollapsed write SetCollapsed default False;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 32;
    property ExpandedHeight: Integer read FExpandedHeight write SetExpandedHeight default 220;
    property HeaderCaption: string read FHeaderCaption write SetHeaderCaption;
    property HeaderColor: TColor read FHeaderColor write SetHeaderColor default $00262626;
    property HeaderHoverColor: TColor read FHeaderHoverColor write SetHeaderHoverColor default $00333333;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00444444;

    { Propriedades herdadas de TWinControl }
    property Align;
    property Anchors;
    property Color default $001A1A1A;
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
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnResize;
    property OnToggle: TOnAccordionToggleEvent read FOnToggle write FOnToggle;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazAccordionContainer]);
end;

{ TLazAccordionContainer }

constructor TLazAccordionContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Habilita aceitação de filhos, foco e clique de mouse }
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse, csClickEvents, csDoubleClicks];
  TabStop := True;

  Width := 300;
  FHeaderHeight := 32;
  FExpandedHeight := 220;
  Height := FExpandedHeight;
  FCollapsed := False;
  FIsHovered := False;

  Color := $001A1A1A;
  FHeaderColor := $00262626;
  FHeaderHoverColor := $00333333;
  FBorderColor := $00444444;
  FHeaderCaption := 'Seção Expansível';

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00E0E0E0;

  { Timer para interpolação de animação suave }
  FAnimationTimer := TTimer.Create(Self);
  FAnimationTimer.Enabled := False;
  FAnimationTimer.Interval := 15; // ~60 FPS
  FAnimationTimer.OnTimer := @OnTimerStep;
end;

destructor TLazAccordionContainer.Destroy;
begin
  FAnimationTimer.Enabled := False;
  inherited Destroy;
end;

procedure TLazAccordionContainer.SetCollapsed(const AValue: Boolean);
begin
  if FCollapsed <> AValue then
  begin
    FCollapsed := AValue;

    if FCollapsed then
      FTargetHeight := FHeaderHeight
    else
      FTargetHeight := FExpandedHeight;

    if csDesigning in ComponentState then
    begin
      Height := FTargetHeight;
      Invalidate;
    end
    else
    begin
      FAnimationTimer.Enabled := True;
    end;

    if Assigned(FOnToggle) then
      FOnToggle(Self, FCollapsed);
  end;
end;

procedure TLazAccordionContainer.OnTimerStep(Sender: TObject);
var
  Step: Integer;
begin
  Step := 16;
  if Height < FTargetHeight then
  begin
    if Height + Step >= FTargetHeight then
    begin
      Height := FTargetHeight;
      FAnimationTimer.Enabled := False;
    end
    else
      Height := Height + Step;
  end
  else if Height > FTargetHeight then
  begin
    if Height - Step <= FTargetHeight then
    begin
      Height := FTargetHeight;
      FAnimationTimer.Enabled := False;
    end
    else
      Height := Height - Step;
  end
  else
    FAnimationTimer.Enabled := False;

  Invalidate;
end;

procedure TLazAccordionContainer.ToggleState;
begin
  Collapsed := not Collapsed;
end;

procedure TLazAccordionContainer.Expand;
begin
  Collapsed := False;
end;

procedure TLazAccordionContainer.Collapse;
begin
  Collapsed := True;
end;

procedure TLazAccordionContainer.SetHeaderHeight(const AValue: Integer);
begin
  if (FHeaderHeight <> AValue) and (AValue >= 20) then
  begin
    FHeaderHeight := AValue;
    if FCollapsed then
      Height := FHeaderHeight;
    Invalidate;
  end;
end;

procedure TLazAccordionContainer.SetExpandedHeight(const AValue: Integer);
begin
  if (FExpandedHeight <> AValue) and (AValue > FHeaderHeight) then
  begin
    FExpandedHeight := AValue;
    if not FCollapsed then
      Height := FExpandedHeight;
    Invalidate;
  end;
end;

procedure TLazAccordionContainer.SetHeaderCaption(const AValue: string);
begin
  if FHeaderCaption <> AValue then
  begin
    FHeaderCaption := AValue;
    Invalidate;
  end;
end;

procedure TLazAccordionContainer.SetHeaderColor(const AValue: TColor);
begin
  if FHeaderColor <> AValue then
  begin
    FHeaderColor := AValue;
    Invalidate;
  end;
end;

procedure TLazAccordionContainer.SetHeaderHoverColor(const AValue: TColor);
begin
  if FHeaderHoverColor <> AValue then
  begin
    FHeaderHoverColor := AValue;
    Invalidate;
  end;
end;

procedure TLazAccordionContainer.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TLazAccordionContainer.Resize;
begin
  inherited Resize;
  if not (csDesigning in ComponentState) and not FAnimationTimer.Enabled then
  begin
    if not FCollapsed then
      FExpandedHeight := Height;
  end;
  Invalidate;
end;

procedure TLazAccordionContainer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and (Y <= FHeaderHeight) then
  begin
    SetFocus;
    ToggleState;
  end;
end;

procedure TLazAccordionContainer.MouseEnter;
begin
  inherited MouseEnter;
  FIsHovered := True;
  Invalidate;
end;

procedure TLazAccordionContainer.MouseLeave;
begin
  inherited MouseLeave;
  FIsHovered := False;
  Invalidate;
end;

procedure TLazAccordionContainer.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  { Suporte a teclado: espaço ou enter alterna o colapso }
  if (Key = VK_SPACE) or (Key = VK_RETURN) then
  begin
    ToggleState;
    Key := 0;
  end;
end;

procedure TLazAccordionContainer.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TLazAccordionContainer.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TLazAccordionContainer.Paint;
var
  HeaderR, TextR: TRect;
  ChevronChar: string;
  EffectiveHeaderColor: TColor;
begin
  { 1. Fundo do Contêiner }
  Canvas.Brush.Color := Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := FBorderColor;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(0, 0, Width, Height);

  { 2. Cabeçalho }
  HeaderR := Rect(0, 0, Width, FHeaderHeight);
  if FIsHovered then
    EffectiveHeaderColor := FHeaderHoverColor
  else
    EffectiveHeaderColor := FHeaderColor;

  Canvas.Brush.Color := EffectiveHeaderColor;
  Canvas.FillRect(HeaderR);

  { Linha divisória inferior do cabeçalho se expandido }
  if not FCollapsed then
  begin
    Canvas.Pen.Color := FBorderColor;
    Canvas.MoveTo(0, FHeaderHeight);
    Canvas.LineTo(Width, FHeaderHeight);
  end;

  { 3. Indicador Chevron de Estado (▼ ou ►) }
  if FCollapsed then
    ChevronChar := '►'
  else
    ChevronChar := '▼';

  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $0000C853; // Verde moderno
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(12, (FHeaderHeight - Canvas.TextHeight(ChevronChar)) div 2, ChevronChar);

  { 4. Texto do Cabeçalho }
  Canvas.Font.Color := Font.Color;
  Canvas.Font.Style := [fsBold];
  TextR := Rect(32, 0, Width - 12, FHeaderHeight);
  LCLIntf.DrawText(Canvas.Handle, PChar(FHeaderCaption), Length(FHeaderCaption),
    TextR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  { 5. Retângulo de Foco de Teclado se ativo }
  if Focused then
  begin
    Canvas.Pen.Style := psDot;
    Canvas.Pen.Color := clHighlight;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(2, 2, Width - 2, FHeaderHeight - 2);
    Canvas.Pen.Style := psSolid;
  end;
end;

end.
