{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 10: Controles Visuais Janelados (TWinControl)
  Componente: TDlpAccordionContainer
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Painel colapsável sanfonado (Accordion Container) para Delphi 12,
             construído sobre TCustomControl (TWinControl) com HWND nativo,
             suporte a foco de teclado, animação de altura a 60 FPS e aceitação
             completa de controles filhos no Form Designer (csAcceptsControls).
==============================================================================}
unit DlpAccordionContainer;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.ExtCtrls;

type
  { Evento de alternância do estado de colapso }
  TDlpAccordionToggleEvent = procedure(Sender: TObject; IsCollapsed: Boolean) of object;

  {============================================================================
    Classe: TDlpAccordionContainer
    Controle janelado contêiner expansível com HWND próprio
  ============================================================================}
  TDlpAccordionContainer = class(TCustomControl)
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
    FOnToggle: TDlpAccordionToggleEvent;

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

    procedure Expand;
    procedure Collapse;
  published
    property Collapsed: Boolean read FCollapsed write SetCollapsed default False;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 34;
    property ExpandedHeight: Integer read FExpandedHeight write SetExpandedHeight default 240;
    property HeaderCaption: string read FHeaderCaption write SetHeaderCaption;
    property HeaderColor: TColor read FHeaderColor write SetHeaderColor default $00262626;
    property HeaderHoverColor: TColor read FHeaderHoverColor write SetHeaderHoverColor default $00363636;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00484848;

    { Propriedades herdadas de TWinControl }
    property Align;
    property Anchors;
    property Color default $001A1A1A;
    property DoubleBuffered default True;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentDoubleBuffered;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Touch;
    property Visible;

    { Eventos }
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnResize;
    property OnToggle: TDlpAccordionToggleEvent read FOnToggle write FOnToggle;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpAccordionContainer]);
end;

{ TDlpAccordionContainer }

constructor TDlpAccordionContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Habilita aceitação de controles filhos no designer e double buffering nativo }
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse, csClickEvents, csDoubleClicks];
  DoubleBuffered := True;
  TabStop := True;

  Width := 320;
  FHeaderHeight := 34;
  FExpandedHeight := 240;
  Height := FExpandedHeight;
  FCollapsed := False;
  FIsHovered := False;

  Color := $001A1A1A;
  FHeaderColor := $00262626;
  FHeaderHoverColor := $00363636;
  FBorderColor := $00484848;
  FHeaderCaption := 'Seção de Painel Sanfonado';

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00F0F0F0;

  { Timer interno de interpolação de altura para animação suave }
  FAnimationTimer := TTimer.Create(Self);
  FAnimationTimer.Enabled := False;
  FAnimationTimer.Interval := 15; // ~60 FPS
  FAnimationTimer.OnTimer := OnTimerStep;
end;

destructor TDlpAccordionContainer.Destroy;
begin
  FAnimationTimer.Enabled := False;
  inherited Destroy;
end;

procedure TDlpAccordionContainer.SetCollapsed(const AValue: Boolean);
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

procedure TDlpAccordionContainer.OnTimerStep(Sender: TObject);
var
  Step: Integer;
begin
  Step := 18;
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

procedure TDlpAccordionContainer.ToggleState;
begin
  Collapsed := not Collapsed;
end;

procedure TDlpAccordionContainer.Expand;
begin
  Collapsed := False;
end;

procedure TDlpAccordionContainer.Collapse;
begin
  Collapsed := True;
end;

procedure TDlpAccordionContainer.SetHeaderHeight(const AValue: Integer);
begin
  if (FHeaderHeight <> AValue) and (AValue >= 24) then
  begin
    FHeaderHeight := AValue;
    if FCollapsed then
      Height := FHeaderHeight;
    Invalidate;
  end;
end;

procedure TDlpAccordionContainer.SetExpandedHeight(const AValue: Integer);
begin
  if (FExpandedHeight <> AValue) and (AValue > FHeaderHeight) then
  begin
    FExpandedHeight := AValue;
    if not FCollapsed then
      Height := FExpandedHeight;
    Invalidate;
  end;
end;

procedure TDlpAccordionContainer.SetHeaderCaption(const AValue: string);
begin
  if FHeaderCaption <> AValue then
  begin
    FHeaderCaption := AValue;
    Invalidate;
  end;
end;

procedure TDlpAccordionContainer.SetHeaderColor(const AValue: TColor);
begin
  if FHeaderColor <> AValue then
  begin
    FHeaderColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpAccordionContainer.SetHeaderHoverColor(const AValue: TColor);
begin
  if FHeaderHoverColor <> AValue then
  begin
    FHeaderHoverColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpAccordionContainer.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpAccordionContainer.Resize;
begin
  inherited Resize;
  if not (csDesigning in ComponentState) and not FAnimationTimer.Enabled then
  begin
    if not FCollapsed then
      FExpandedHeight := Height;
  end;
  Invalidate;
end;

procedure TDlpAccordionContainer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and (Y <= FHeaderHeight) then
  begin
    SetFocus;
    ToggleState;
  end;
end;

procedure TDlpAccordionContainer.MouseEnter;
begin
  inherited MouseEnter;
  FIsHovered := True;
  Invalidate;
end;

procedure TDlpAccordionContainer.MouseLeave;
begin
  inherited MouseLeave;
  FIsHovered := False;
  Invalidate;
end;

procedure TDlpAccordionContainer.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_SPACE) or (Key = VK_RETURN) then
  begin
    ToggleState;
    Key := 0;
  end;
end;

procedure TDlpAccordionContainer.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TDlpAccordionContainer.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TDlpAccordionContainer.Paint;
var
  HeaderR, TextR: TRect;
  ChevronText: string;
  CurrentHeaderBg: TColor;
begin
  { 1. Fundo do Contêiner }
  Canvas.Brush.Color := Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := FBorderColor;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(0, 0, Width, Height);

  { 2. Cabeçalho Interativo }
  HeaderR := Rect(0, 0, Width, FHeaderHeight);
  if FIsHovered then
    CurrentHeaderBg := FHeaderHoverColor
  else
    CurrentHeaderBg := FHeaderColor;

  Canvas.Brush.Color := CurrentHeaderBg;
  Canvas.FillRect(HeaderR);

  if not FCollapsed then
  begin
    Canvas.Pen.Color := FBorderColor;
    Canvas.MoveTo(0, FHeaderHeight);
    Canvas.LineTo(Width, FHeaderHeight);
  end;

  { 3. Indicador de Chevron Animado (▼ / ►) }
  if FCollapsed then
    ChevronText := '►'
  else
    ChevronText := '▼';

  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $0000C853; // Verde accent
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(14, (FHeaderHeight - Canvas.TextHeight(ChevronText)) div 2, ChevronText);

  { 4. Título do Cabeçalho }
  Canvas.Font.Color := Font.Color;
  Canvas.Font.Style := [fsBold];
  TextR := Rect(36, 0, Width - 14, FHeaderHeight);
  Vcl.Graphics.DrawText(Canvas.Handle, PChar(FHeaderCaption), Length(FHeaderCaption),
    TextR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  { 5. Retângulo de Foco de Teclado }
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
