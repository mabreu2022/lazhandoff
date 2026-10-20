{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 04: Tratamento de Mensagens do SO e Arquitetura de Eventos
  Componente: TLazAsyncEventHook
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Componente que demonstra interceptação segura do ciclo de
             mensagens LCL (WndProc / TLMessage / LM_*), criação de delegates
             avançados com múltiplos parâmetros, despacho assíncrono seguro
             via Application.QueueAsyncCall e proteção contra deadlocks na UI.
==============================================================================}
unit LazAsyncEventHook;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Forms,
  LCLType,
  LCLMessages,
  LMessages;

const
  { Mensagem LCL customizada para despacho interno }
  LM_LAZ_ASYNC_DISPATCH = LM_USER + $0410;

type
  { Registro contendo dados detalhados da mensagem interceptada }
  TLazInterceptedMessage = record
    MsgCode: Cardinal;
    WParamVal: PtrUInt;
    LParamVal: PtrInt;
    Handled: Boolean;
    Timestamp: TDateTime;
  end;

  { Delegate tipado com múltiplos parâmetros para notificações ricas }
  TOnInterceptMessageEvent = procedure(Sender: TObject;
    var AMessage: TLazInterceptedMessage) of object;

  { Delegate assíncrono desacoplado da pilha de chamadas }
  TOnAsyncNotification = procedure(Sender: TObject; AToken: Int64;
    const APayload: string) of object;

  { Registro para transporte seguro no QueueAsyncCall }
  PAsyncPayloadRecord = ^TAsyncPayloadRecord;
  TAsyncPayloadRecord = record
    Token: Int64;
    Payload: string;
  end;

  {============================================================================
    Classe: TLazAsyncEventHook
    Componente não-visual que intercepta a fila de mensagens de um TWinControl
    e provê agendamento seguro de eventos assíncronos na fila da aplicação.
  ============================================================================}
  TLazAsyncEventHook = class(TComponent)
  private
    FTargetControl: TWinControl;
    FOriginalWndProc: TWndMethod;
    FEnabled: Boolean;
    FTokenSequence: Int64;
    FInterceptKeyMessages: Boolean;
    FInterceptMouseMessages: Boolean;
    FOnInterceptMessage: TOnInterceptMessageEvent;
    FOnAsyncNotification: TOnAsyncNotification;

    procedure SetTargetControl(const AValue: TWinControl);
    procedure SetEnabled(const AValue: Boolean);
    procedure HookControl;
    procedure UnhookControl;

    { Interceptador de mensagens do controle alvo }
    procedure SubclassedWndProc(var Message: TLMessage);

    { Callback executado pelo Application.QueueAsyncCall na UI thread }
    procedure ProcessAsyncCall(Data: PtrInt);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Disparo de evento assíncrono na fila principal sem travar a thread }
    procedure PostAsyncEvent(const APayload: string);
  published
    property TargetControl: TWinControl read FTargetControl write SetTargetControl;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property InterceptKeyMessages: Boolean read FInterceptKeyMessages write FInterceptKeyMessages default True;
    property InterceptMouseMessages: Boolean read FInterceptMouseMessages write FInterceptMouseMessages default False;

    property OnInterceptMessage: TOnInterceptMessageEvent read FOnInterceptMessage write FOnInterceptMessage;
    property OnAsyncNotification: TOnAsyncNotification read FOnAsyncNotification write FOnAsyncNotification;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazAsyncEventHook]);
end;

{ TLazAsyncEventHook }

constructor TLazAsyncEventHook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTargetControl := nil;
  FOriginalWndProc := nil;
  FEnabled := True;
  FTokenSequence := 0;
  FInterceptKeyMessages := True;
  FInterceptMouseMessages := False;
end;

destructor TLazAsyncEventHook.Destroy;
begin
  UnhookControl;
  inherited Destroy;
end;

procedure TLazAsyncEventHook.Loaded;
begin
  inherited Loaded;
  if FEnabled and Assigned(FTargetControl) then
    HookControl;
end;

procedure TLazAsyncEventHook.SetTargetControl(const AValue: TWinControl);
begin
  if FTargetControl <> AValue then
  begin
    UnhookControl;

    if Assigned(FTargetControl) then
      FTargetControl.RemoveFreeNotification(Self);

    FTargetControl := AValue;

    if Assigned(FTargetControl) then
    begin
      FTargetControl.FreeNotification(Self);
      if FEnabled and not (csLoading in ComponentState) then
        HookControl;
    end;
  end;
end;

procedure TLazAsyncEventHook.SetEnabled(const AValue: Boolean);
begin
  if FEnabled <> AValue then
  begin
    FEnabled := AValue;
    if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    begin
      if FEnabled then
        HookControl
      else
        UnhookControl;
    end;
  end;
end;

procedure TLazAsyncEventHook.HookControl;
begin
  if csDesigning in ComponentState then
    Exit;

  if Assigned(FTargetControl) and (FOriginalWndProc = nil) then
  begin
    FOriginalWndProc := FTargetControl.WindowProc;
    FTargetControl.WindowProc := @SubclassedWndProc;
  end;
end;

procedure TLazAsyncEventHook.UnhookControl;
begin
  if Assigned(FTargetControl) and Assigned(FOriginalWndProc) then
  begin
    FTargetControl.WindowProc := FOriginalWndProc;
    FOriginalWndProc := nil;
  end;
end;

procedure TLazAsyncEventHook.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FTargetControl) then
  begin
    FOriginalWndProc := nil;
    FTargetControl := nil;
  end;
end;

procedure TLazAsyncEventHook.SubclassedWndProc(var Message: TLMessage);
var
  Intercepted: TLazInterceptedMessage;
  IsTargetMsg: Boolean;
begin
  IsTargetMsg := False;

  if FInterceptKeyMessages and (Message.Msg in [LM_KEYDOWN, LM_KEYUP, LM_CHAR]) then
    IsTargetMsg := True;

  if FInterceptMouseMessages and (Message.Msg in [LM_LBUTTONDOWN, LM_RBUTTONDOWN, LM_MOUSEMOVE]) then
    IsTargetMsg := True;

  if IsTargetMsg and Assigned(FOnInterceptMessage) then
  begin
    Intercepted.MsgCode := Message.Msg;
    Intercepted.WParamVal := Message.WParam;
    Intercepted.LParamVal := Message.LParam;
    Intercepted.Handled := False;
    Intercepted.Timestamp := Now;

    try
      FOnInterceptMessage(Self, Intercepted);
    except
      { Impede que falhas no handler do usuário quebrem o pipeline da janela }
    end;

    if Intercepted.Handled then
    begin
      Message.Result := 0;
      Exit;
    end;
  end;

  { Encaminha para a WindowProc original do controle }
  if Assigned(FOriginalWndProc) then
    FOriginalWndProc(Message);
end;

procedure TLazAsyncEventHook.PostAsyncEvent(const APayload: string);
var
  DataPtr: PAsyncPayloadRecord;
begin
  if not Assigned(FOnAsyncNotification) then
    Exit;

  Inc(FTokenSequence);
  New(DataPtr);
  DataPtr^.Token := FTokenSequence;
  DataPtr^.Payload := APayload;

  { Enfileira de forma assíncrona e thread-safe na fila do Lazarus }
  Application.QueueAsyncCall(@ProcessAsyncCall, PtrInt(DataPtr));
end;

procedure TLazAsyncEventHook.ProcessAsyncCall(Data: PtrInt);
var
  DataPtr: PAsyncPayloadRecord;
begin
  DataPtr := PAsyncPayloadRecord(Data);
  if DataPtr = nil then
    Exit;

  try
    if Assigned(FOnAsyncNotification) and not (csDestroying in ComponentState) then
    begin
      FOnAsyncNotification(Self, DataPtr^.Token, DataPtr^.Payload);
    end;
  finally
    Dispose(DataPtr);
  end;
end;

end.
