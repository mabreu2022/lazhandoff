{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 02: O Ciclo de Vida Completo do Componente
  Componente: TLazSafeLinkedPanel
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Painel contêiner visual avançado que demonstra o ciclo de vida
             completo de um componente (Create -> CreateWnd -> Loaded ->
             Notification -> Destroy), com gerenciamento seguro de referências
             cruzadas fracas e renderização diferenciada para csDesigning.
==============================================================================}
unit LazSafeLinkedPanel;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Forms,
  LCLType,
  LCLIntf;

type
  { Enum para estilo de destaque visual no Form Designer }
  TLazDesignIndicator = (diDottedBorder, diWatermarkText, diNone);

  { Evento para notificar alterações de ciclo de vida à aplicação }
  TOnLifecycleStage = procedure(Sender: TObject; const AStageName: string;
    const ADetails: string) of object;

  {============================================================================
    Classe: TLazSafeLinkedPanel
    Herda de TCustomControl para ter Handle próprio (TWinControl) e método
    Paint virtual configurável, além de gerenciar referências cruzadas fracas.
  ============================================================================}
  TLazSafeLinkedPanel = class(TCustomControl)
  private
    FLinkedControl: TControl;
    FCompanionComponent: TComponent;
    FDesignIndicator: TLazDesignIndicator;
    FHeaderColor: TColor;
    FHeaderHeight: Integer;
    FBorderColor: TColor;
    FTitleText: string;
    FOnLifecycleStage: TOnLifecycleStage;

    procedure SetLinkedControl(const AValue: TControl);
    procedure SetCompanionComponent(const AValue: TComponent);
    procedure SetDesignIndicator(const AValue: TLazDesignIndicator);
    procedure SetHeaderColor(const AValue: TColor);
    procedure SetHeaderHeight(const AValue: Integer);
    procedure SetBorderColor(const AValue: TColor);
    procedure SetTitleText(const AValue: string);

    procedure NotifyStage(const AStageName, ADetails: string);
    procedure DrawDesignWatermark(ACanvas: TCanvas);
  protected
    { 1. Fase de alocação de handle no Widgetset nativo }
    procedure CreateWnd; override;
    procedure DestroyWnd; override;

    { 2. Fase de pós-carregamento do streaming LFM }
    procedure Loaded; override;

    { 3. Mecanismo de notificação de ciclo de vida entre componentes }
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    { 4. Ciclo de renderização visual }
    procedure Paint; override;
    procedure Resize; override;
  public
    { Construtor e Destrutor gerenciadores de memória }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos públicos utilitários }
    function IsLinkedControlActive: Boolean;
    function GetLifecycleDiagnosticInfo: string;
  published
    { Propriedades de vinculação fraca com ciclo de vida seguro }
    property LinkedControl: TControl read FLinkedControl write SetLinkedControl;
    property CompanionComponent: TComponent read FCompanionComponent write SetCompanionComponent;

    { Propriedades visuais publicadas no Object Inspector }
    property DesignIndicator: TLazDesignIndicator read FDesignIndicator write SetDesignIndicator default diDottedBorder;
    property HeaderColor: TColor read FHeaderColor write SetHeaderColor default $002B2B2B;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 28;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00555555;
    property TitleText: string read FTitleText write SetTitleText;

    { Propriedades padrão herdadas da LCL }
    property Align;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Caption;
    property Color default $001E1E1E;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property PopupMenu;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Eventos padrão }
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;

    { Evento customizado de monitoramento de ciclo de vida }
    property OnLifecycleStage: TOnLifecycleStage read FOnLifecycleStage write FOnLifecycleStage;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazSafeLinkedPanel]);
end;

{ TLazSafeLinkedPanel }

constructor TLazSafeLinkedPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Inicializa estilos de controle de contêiner }
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse, csClickEvents, csDoubleClicks];

  { Define dimensões padrão e cores iniciais (Dark Theme Moderno) }
  Width := 280;
  Height := 180;
  Color := $001E1E1E;
  FHeaderColor := $002B2B2B;
  FHeaderHeight := 28;
  FBorderColor := $00555555;
  FTitleText := 'Safe Linked Panel';
  FDesignIndicator := diDottedBorder;
  FLinkedControl := nil;
  FCompanionComponent := nil;

  { Configura fonte padrão para alta nitidez }
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00E0E0E0;

  NotifyStage('Create', Format('Owner: %s | csDesigning: %s',
    [BoolToStr(Assigned(AOwner), 'Presente', 'nil'),
     BoolToStr(csDesigning in ComponentState, 'Sim', 'Não')]));
end;

destructor TLazSafeLinkedPanel.Destroy;
begin
  NotifyStage('Destroy', 'Liberando recursos e desvinculando ponteiros...');

  { Remove notificações bilaterais pendentes para evitar chamadas tardias }
  if Assigned(FLinkedControl) then
  begin
    FLinkedControl.RemoveFreeNotification(Self);
    FLinkedControl := nil;
  end;

  if Assigned(FCompanionComponent) then
  begin
    FCompanionComponent.RemoveFreeNotification(Self);
    FCompanionComponent := nil;
  end;

  inherited Destroy;
end;

procedure TLazSafeLinkedPanel.CreateWnd;
begin
  inherited CreateWnd;

  { O Handle nativo foi criado no Widgetset neste exato momento }
  NotifyStage('CreateWnd', Format('Handle nativo alocado: 0x%x', [Handle]));
end;

procedure TLazSafeLinkedPanel.DestroyWnd;
begin
  NotifyStage('DestroyWnd', Format('Handle prestes a ser desalocado: 0x%x', [Handle]));
  inherited DestroyWnd;
end;

procedure TLazSafeLinkedPanel.Loaded;
begin
  inherited Loaded;

  { Todos os componentes do LFM foram instanciados e suas propriedades carregadas }
  NotifyStage('Loaded', Format('LFM concluído. LinkedControl: %s | Companion: %s',
    [BoolToStr(Assigned(FLinkedControl), 'Atribuído', 'Vazio'),
     BoolToStr(Assigned(FCompanionComponent), 'Atribuído', 'Vazio')]));

  Invalidate;
end;

procedure TLazSafeLinkedPanel.SetLinkedControl(const AValue: TControl);
begin
  if FLinkedControl <> AValue then
  begin
    { Evita auto-referência circular }
    if AValue = Self then
      raise Exception.Create('Um componente não pode vincular-se a si mesmo como LinkedControl.');

    { Remove notificação do componente antigo }
    if Assigned(FLinkedControl) then
      FLinkedControl.RemoveFreeNotification(Self);

    FLinkedControl := AValue;

    { Solicita notificação formal de destruição do novo controle }
    if Assigned(FLinkedControl) then
      FLinkedControl.FreeNotification(Self);

    NotifyStage('SetLinkedControl', Format('Novo controle: %s',
      [BoolToStr(Assigned(FLinkedControl), FLinkedControl.Name, 'nil')]));

    Invalidate;
  end;
end;

procedure TLazSafeLinkedPanel.SetCompanionComponent(const AValue: TComponent);
begin
  if FCompanionComponent <> AValue then
  begin
    if AValue = Self then
      raise Exception.Create('Um componente não pode vincular-se a si mesmo como CompanionComponent.');

    if Assigned(FCompanionComponent) then
      FCompanionComponent.RemoveFreeNotification(Self);

    FCompanionComponent := AValue;

    if Assigned(FCompanionComponent) then
      FCompanionComponent.FreeNotification(Self);

    NotifyStage('SetCompanionComponent', Format('Novo companion: %s',
      [BoolToStr(Assigned(FCompanionComponent), FCompanionComponent.Name, 'nil')]));

    Invalidate;
  end;
end;

procedure TLazSafeLinkedPanel.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  { Tratamento cirúrgico de remoção em Design-Time e Run-Time }
  if Operation = opRemove then
  begin
    if AComponent = FLinkedControl then
    begin
      NotifyStage('Notification(opRemove)', Format('LinkedControl [%s] está sendo destruído. Anulando ponteiro.', [AComponent.Name]));
      FLinkedControl := nil;
      Invalidate;
    end
    else if AComponent = FCompanionComponent then
    begin
      NotifyStage('Notification(opRemove)', Format('CompanionComponent [%s] está sendo destruído. Anulando ponteiro.', [AComponent.Name]));
      FCompanionComponent := nil;
      Invalidate;
    end;
  end;
end;

procedure TLazSafeLinkedPanel.SetDesignIndicator(const AValue: TLazDesignIndicator);
begin
  if FDesignIndicator <> AValue then
  begin
    FDesignIndicator := AValue;
    Invalidate;
  end;
end;

procedure TLazSafeLinkedPanel.SetHeaderColor(const AValue: TColor);
begin
  if FHeaderColor <> AValue then
  begin
    FHeaderColor := AValue;
    Invalidate;
  end;
end;

procedure TLazSafeLinkedPanel.SetHeaderHeight(const AValue: Integer);
begin
  if (FHeaderHeight <> AValue) and (AValue >= 0) then
  begin
    FHeaderHeight := AValue;
    Invalidate;
  end;
end;

procedure TLazSafeLinkedPanel.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TLazSafeLinkedPanel.SetTitleText(const AValue: string);
begin
  if FTitleText <> AValue then
  begin
    FTitleText := AValue;
    Invalidate;
  end;
end;

procedure TLazSafeLinkedPanel.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TLazSafeLinkedPanel.DrawDesignWatermark(ACanvas: TCanvas);
var
  OldPenStyle: TPenStyle;
  InfoStr: string;
  TextSz: TSize;
  Tx, Ty: Integer;
begin
  { Se não estiver em design-time, ignora indicadores }
  if not (csDesigning in ComponentState) then
    Exit;

  case FDesignIndicator of
    diDottedBorder:
      begin
        OldPenStyle := ACanvas.Pen.Style;
        try
          ACanvas.Pen.Style := psDot;
          ACanvas.Pen.Color := clHighlight;
          ACanvas.Pen.Width := 1;
          ACanvas.Brush.Style := bsClear;
          ACanvas.Rectangle(1, 1, Width - 1, Height - 1);
        finally
          ACanvas.Pen.Style := OldPenStyle;
        end;
      end;

    diWatermarkText:
      begin
        InfoStr := '[DESIGN MODE] ' + Name;
        ACanvas.Font.Size := 8;
        ACanvas.Font.Color := clGray;
        ACanvas.Brush.Style := bsClear;
        TextSz := ACanvas.TextExtent(InfoStr);
        Tx := (Width - TextSz.cx) div 2;
        Ty := Height - TextSz.cy - 6;
        if Ty > FHeaderHeight then
          ACanvas.TextOut(Tx, Ty, InfoStr);
      end;

    diNone: ;
  end;
end;

procedure TLazSafeLinkedPanel.Paint;
var
  R: TRect;
  TitleR: TRect;
  OldBrushColor: TColor;
begin
  { Supressão de pintura se o componente estiver sendo destruído ou durante leitura inicial }
  if (csDestroying in ComponentState) or (csReadingState in ComponentState) then
    Exit;

  { 1. Fundo do Contêiner }
  Canvas.Brush.Color := Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := FBorderColor;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(0, 0, Width, Height);

  { 2. Cabeçalho Superior }
  if FHeaderHeight > 0 then
  begin
    R := Rect(0, 0, Width, FHeaderHeight);
    Canvas.Brush.Color := FHeaderColor;
    Canvas.FillRect(R);

    { Linha divisória inferior do cabeçalho }
    Canvas.Pen.Color := FBorderColor;
    Canvas.MoveTo(0, FHeaderHeight);
    Canvas.LineTo(Width, FHeaderHeight);

    { Texto do Título }
    TitleR := Rect(10, 0, Width - 10, FHeaderHeight);
    Canvas.Font.Assign(Self.Font);
    Canvas.Font.Style := [fsBold];
    Canvas.Brush.Style := bsClear;
    LCLIntf.DrawText(Canvas.Handle, PChar(FTitleText), Length(FTitleText),
      TitleR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;

  { 3. Destaque de Vínculo com LinkedControl }
  if Assigned(FLinkedControl) then
  begin
    Canvas.Font.Size := 8;
    Canvas.Font.Style := [fsItalic];
    Canvas.Font.Color := $0070C070; // Verde suave
    Canvas.TextOut(10, FHeaderHeight + 6, Format('Link: %s (%s)',
      [FLinkedControl.Name, FLinkedControl.ClassName]));
  end;

  { 4. Marca d'água e auxiliares do Form Designer }
  DrawDesignWatermark(Canvas);
end;

procedure TLazSafeLinkedPanel.NotifyStage(const AStageName, ADetails: string);
begin
  if Assigned(FOnLifecycleStage) then
  begin
    try
      FOnLifecycleStage(Self, AStageName, ADetails);
    except
      { Proteção contra exceções em handlers de eventos durante ciclo de vida }
    end;
  end;
end;

function TLazSafeLinkedPanel.IsLinkedControlActive: Boolean;
begin
  Result := Assigned(FLinkedControl) and
            not (csDestroying in FLinkedControl.ComponentState);
end;

function TLazSafeLinkedPanel.GetLifecycleDiagnosticInfo: string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine(Format('Componente: %s (%s)', [Name, ClassName]));
    SB.AppendLine(Format('- Handle Alocado: %s', [BoolToStr(HandleAllocated, 'Sim', 'Não')]));
    SB.AppendLine(Format('- csDesigning: %s', [BoolToStr(csDesigning in ComponentState, 'Sim', 'Não')]));
    SB.AppendLine(Format('- csLoading: %s', [BoolToStr(csLoading in ComponentState, 'Sim', 'Não')]));
    SB.AppendLine(Format('- csDestroying: %s', [BoolToStr(csDestroying in ComponentState, 'Sim', 'Não')]));
    SB.AppendLine(Format('- csReadingState: %s', [BoolToStr(csReadingState in ComponentState, 'Sim', 'Não')]));
    SB.AppendLine(Format('- LinkedControl: %s',
      [BoolToStr(Assigned(FLinkedControl), FLinkedControl.Name, 'nil')]));
    SB.AppendLine(Format('- CompanionComponent: %s',
      [BoolToStr(Assigned(FCompanionComponent), FCompanionComponent.Name, 'nil')]));
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
