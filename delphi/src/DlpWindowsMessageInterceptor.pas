{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 04: Tratamento de Mensagens do SO e Arquitetura de Eventos
  Componente: TDlpWindowsMessageInterceptor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Componente não-visual que realiza subclassing avançado de janelas
             VCL via WindowProc, provê interceptação com cancelamento de mensagens
             nativas do Windows (WM_*), despachos assíncronos desacoplados via
             TThread.Queue e suporte a eventos modernos com métodos anônimos.
==============================================================================}
unit DlpWindowsMessageInterceptor;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms;

type
  { Dados estruturados da mensagem do Windows interceptada }
  TDlpMessageInfo = record
    Msg: Cardinal;
    WParam: WPARAM;
    LParam: LPARAM;
    Handled: Boolean;
    Result: LRESULT;
    Timestamp: TDateTime;
  end;

  { Delegate clássico com parâmetros tipados }
  TOnWindowsMessageIntercepted = procedure(Sender: TObject;
    var AMsgInfo: TDlpMessageInfo) of object;

  { Delegate assíncrono moderno com suporte a métodos anônimos }
  TDlpAsyncMessageCallback = reference to procedure(const AToken: Int64;
    const APayload: string);

  { Evento publicado convencional para notificação assíncrona }
  TOnAsyncDispatchedEvent = procedure(Sender: TObject; AToken: Int64;
    const APayload: string) of object;

  {============================================================================
    Classe: TDlpWindowsMessageInterceptor
    Componente não-visual para interceptação de mensagens Win32/64
  ============================================================================}
  TDlpWindowsMessageInterceptor = class(TComponent)
  private
    FTargetControl: TWinControl;
    FOriginalWindowProc: TWndMethod;
    FActive: Boolean;
    FSequenceToken: Int64;
    FInterceptKeyboard: Boolean;
    FInterceptMouse: Boolean;
    FInterceptSystem: Boolean;
    FOnMessageIntercepted: TOnWindowsMessageIntercepted;
    FOnAsyncDispatched: TOnAsyncDispatchedEvent;

    procedure SetTargetControl(const AValue: TWinControl);
    procedure SetActive(const AValue: Boolean);
    procedure AttachSubclass;
    procedure DetachSubclass;

    { Procedimento de janela substituto }
    procedure InterceptorWindowProc(var Message: TMessage);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Despacho de mensagens assíncronas thread-safe para a fila da UI }
    procedure QueueAsyncNotification(const APayload: string);
    procedure QueueAnonymousCallback(ACallback: TDlpAsyncMessageCallback;
      const APayload: string);
  published
    property TargetControl: TWinControl read FTargetControl write SetTargetControl;
    property Active: Boolean read FActive write SetActive default True;
    property InterceptKeyboard: Boolean read FInterceptKeyboard write FInterceptKeyboard default True;
    property InterceptMouse: Boolean read FInterceptMouse write FInterceptMouse default False;
    property InterceptSystem: Boolean read FInterceptSystem write FInterceptSystem default False;

    property OnMessageIntercepted: TOnWindowsMessageIntercepted read FOnMessageIntercepted write FOnMessageIntercepted;
    property OnAsyncDispatched: TOnAsyncDispatchedEvent read FOnAsyncDispatched write FOnAsyncDispatched;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpWindowsMessageInterceptor]);
end;

{ TDlpWindowsMessageInterceptor }

constructor TDlpWindowsMessageInterceptor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTargetControl := nil;
  FOriginalWindowProc := nil;
  FActive := True;
  FSequenceToken := 0;
  FInterceptKeyboard := True;
  FInterceptMouse := False;
  FInterceptSystem := False;
end;

destructor TDlpWindowsMessageInterceptor.Destroy;
begin
  DetachSubclass;
  inherited Destroy;
end;

procedure TDlpWindowsMessageInterceptor.Loaded;
begin
  inherited Loaded;
  if FActive and Assigned(FTargetControl) then
    AttachSubclass;
end;

procedure TDlpWindowsMessageInterceptor.SetTargetControl(const AValue: TWinControl);
begin
  if FTargetControl <> AValue then
  begin
    DetachSubclass;

    if Assigned(FTargetControl) then
      FTargetControl.RemoveFreeNotification(Self);

    FTargetControl := AValue;

    if Assigned(FTargetControl) then
    begin
      FTargetControl.FreeNotification(Self);
      if FActive and not (csLoading in ComponentState) then
        AttachSubclass;
    end;
  end;
end;

procedure TDlpWindowsMessageInterceptor.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    begin
      if FActive then
        AttachSubclass
      else
        DetachSubclass;
    end;
  end;
end;

procedure TDlpWindowsMessageInterceptor.AttachSubclass;
begin
  if csDesigning in ComponentState then
    Exit;

  if Assigned(FTargetControl) and not Assigned(FOriginalWindowProc) then
  begin
    FOriginalWindowProc := FTargetControl.WindowProc;
    FTargetControl.WindowProc := InterceptorWindowProc;
  end;
end;

procedure TDlpWindowsMessageInterceptor.DetachSubclass;
begin
  if Assigned(FTargetControl) and Assigned(FOriginalWindowProc) then
  begin
    FTargetControl.WindowProc := FOriginalWindowProc;
    FOriginalWindowProc := nil;
  end;
end;

procedure TDlpWindowsMessageInterceptor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FTargetControl) then
  begin
    FOriginalWindowProc := nil;
    FTargetControl := nil;
  end;
end;

procedure TDlpWindowsMessageInterceptor.InterceptorWindowProc(var Message: TMessage);
var
  MsgInfo: TDlpMessageInfo;
  ShouldIntercept: Boolean;
begin
  ShouldIntercept := False;

  case Message.Msg of
    WM_KEYDOWN, WM_KEYUP, WM_CHAR, WM_SYSKEYDOWN, WM_SYSKEYUP:
      if FInterceptKeyboard then ShouldIntercept := True;
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MOUSEMOVE, WM_MOUSEWHEEL:
      if FInterceptMouse then ShouldIntercept := True;
    WM_SYSCOMMAND, WM_COMMAND, WM_SETFOCUS, WM_KILLFOCUS:
      if FInterceptSystem then ShouldIntercept := True;
  end;

  if ShouldIntercept and Assigned(FOnMessageIntercepted) then
  begin
    MsgInfo.Msg := Message.Msg;
    MsgInfo.WParam := Message.WParam;
    MsgInfo.LParam := Message.LParam;
    MsgInfo.Handled := False;
    MsgInfo.Result := 0;
    MsgInfo.Timestamp := Now;

    try
      FOnMessageIntercepted(Self, MsgInfo);
    except
      { Isola o pipeline de janelas contra exceções em código do consumidor }
    end;

    if MsgInfo.Handled then
    begin
      Message.Result := MsgInfo.Result;
      Exit;
    end;
  end;

  { Se não interceptada ou Handled = False, repassa para a WindowProc original }
  if Assigned(FOriginalWindowProc) then
    FOriginalWindowProc(Message);
end;

procedure TDlpWindowsMessageInterceptor.QueueAsyncNotification(const APayload: string);
var
  CurrentToken: Int64;
  SavedPayload: string;
  Proc: TThreadProcedure;
begin
  if not Assigned(FOnAsyncDispatched) then
    Exit;

  Inc(FSequenceToken);
  CurrentToken := FSequenceToken;
  SavedPayload := APayload;

  { Enfileira de forma assíncrona na UI thread sem risco de deadlocks }
  Proc := procedure
    begin
      if Assigned(FOnAsyncDispatched) and not (csDestroying in ComponentState) then
        FOnAsyncDispatched(Self, CurrentToken, SavedPayload);
    end;

  TThread.Queue(nil, Proc);
end;

procedure TDlpWindowsMessageInterceptor.QueueAnonymousCallback(
  ACallback: TDlpAsyncMessageCallback; const APayload: string);
var
  CurrentToken: Int64;
  SavedPayload: string;
  SavedCallback: TDlpAsyncMessageCallback;
  Proc: TThreadProcedure;
begin
  if not Assigned(ACallback) then
    Exit;

  Inc(FSequenceToken);
  CurrentToken := FSequenceToken;
  SavedPayload := APayload;
  SavedCallback := ACallback;

  Proc := procedure
    begin
      if not (csDestroying in ComponentState) then
        SavedCallback(CurrentToken, SavedPayload);
    end;

  TThread.Queue(nil, Proc);
end;

end.
