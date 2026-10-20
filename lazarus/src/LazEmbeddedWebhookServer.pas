{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 39: Servidor de Webhooks Embutido (TLazEmbeddedWebhookServer)
  Componente: TLazEmbeddedWebhookServer
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Microservidor HTTP embutido de alta velocidade para recepção autônoma
             de Webhooks (callbacks de gateways de pagamento como Mercado Pago,
             Stripe, Asaas e notificações de CI/CD). Opera como listener TCP
             autônomo em background sem necessidade de servidores web externos.
==============================================================================}
unit LazEmbeddedWebhookServer;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Sockets;

type
  { Dados de uma requisição de Webhook recebida }
  TWebhookRequest = record
    Method: string;
    Path: string;
    QueryString: string;
    ContentType: string;
    Signature: string;
    RawBody: string;
    ClientIP: string;
  end;

  { Assinatura do evento de tratamento de Webhook }
  TWebhookReceivedEvent = procedure(Sender: TObject; const ARequest: TWebhookRequest;
    var AResponseCode: Integer; var AResponseBody: string) of object;

  { Forward declaration }
  TLazEmbeddedWebhookServer = class;

  { Thread de escuta de conexões de rede HTTP }
  TWebhookListenerThread = class(TThread)
  private
    FServer: TLazEmbeddedWebhookServer;
    FServerSocket: LongInt;
    FPort: Word;

    procedure HandleClient(ClientSocket: LongInt; const ClientIP: string);
    function ParseRequest(const RawHttp: string; out Req: TWebhookRequest): Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AServer: TLazEmbeddedWebhookServer; APort: Word);
    destructor Destroy; override;
  end;

  {============================================================================
    Componente: TLazEmbeddedWebhookServer
    Servidor de Webhooks HTTP desacoplado
  ============================================================================}
  TLazEmbeddedWebhookServer = class(TComponent)
  private
    FPort: Word;
    FActive: Boolean;
    FListenerThread: TWebhookListenerThread;
    FSecretToken: string;
    FOnWebhookReceived: TWebhookReceivedEvent;

    procedure SetActive(const Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure StartServer;
    procedure StopServer;
  published
    property Port: Word read FPort write FPort default 8085;
    property Active: Boolean read FActive write SetActive default False;
    property SecretToken: string read FSecretToken write FSecretToken;
    property OnWebhookReceived: TWebhookReceivedEvent read FOnWebhookReceived write FOnWebhookReceived;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazEmbeddedWebhookServer]);
end;

{ TWebhookListenerThread }

constructor TWebhookListenerThread.Create(AServer: TLazEmbeddedWebhookServer; APort: Word);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FServer := AServer;
  FPort := APort;
  FServerSocket := -1;
end;

destructor TWebhookListenerThread.Destroy;
begin
  if FServerSocket >= 0 then
    CloseSocket(FServerSocket);
  inherited Destroy;
end;

function TWebhookListenerThread.ParseRequest(const RawHttp: string; out Req: TWebhookRequest): Boolean;
var
  Lines: TStringList;
  i, P, BodyStart: Integer;
  FirstLine, HeaderLine: string;
  Parts: TStringArray;
begin
  Result := False;
  Req := Default(TWebhookRequest);
  if Trim(RawHttp) = '' then Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := RawHttp;
    if Lines.Count = 0 then Exit;

    FirstLine := Lines[0];
    Parts := FirstLine.Split([' ']);
    if Length(Parts) < 2 then Exit;

    Req.Method := Parts[0];
    Req.Path := Parts[1];
    P := Pos('?', Req.Path);
    if P > 0 then
    begin
      Req.QueryString := Copy(Req.Path, P + 1, Length(Req.Path));
      Req.Path := Copy(Req.Path, 1, P - 1);
    end;

    for i := 1 to Lines.Count - 1 do
    begin
      HeaderLine := Lines[i];
      if HeaderLine = '' then
      begin
        { Encerramento dos cabeçalhos HTTP, início do body }
        Break;
      end;

      if Pos('Content-Type:', HeaderLine) = 1 then
        Req.ContentType := Trim(Copy(HeaderLine, 14, Length(HeaderLine)))
      else if Pos('X-Signature:', HeaderLine) = 1 then
        Req.Signature := Trim(Copy(HeaderLine, 13, Length(HeaderLine)))
      else if Pos('X-Hub-Signature-256:', HeaderLine) = 1 then
        Req.Signature := Trim(Copy(HeaderLine, 21, Length(HeaderLine)));
    end;

    BodyStart := Pos(#13#10#13#10, RawHttp);
    if BodyStart > 0 then
      Req.RawBody := Copy(RawHttp, BodyStart + 4, Length(RawHttp))
    else
    begin
      BodyStart := Pos(#10#10, RawHttp);
      if BodyStart > 0 then
        Req.RawBody := Copy(RawHttp, BodyStart + 2, Length(RawHttp));
    end;

    Result := True;
  finally
    Lines.Free;
  end;
end;

procedure TWebhookListenerThread.HandleClient(ClientSocket: LongInt; const ClientIP: string);
var
  Buffer: array[0..8191] of Char;
  BytesRead: Integer;
  RawHttp: string;
  Req: TWebhookRequest;
  RespCode: Integer;
  RespBody: string;
  ResponseHttp: string;
begin
  RawHttp := '';
  repeat
    BytesRead := fprecv(ClientSocket, @Buffer[0], SizeOf(Buffer) - 1, 0);
    if BytesRead > 0 then
    begin
      Buffer[BytesRead] := #0;
      RawHttp := RawHttp + Buffer;
      if (Pos(#13#10#13#10, RawHttp) > 0) or (Pos(#10#10, RawHttp) > 0) then
        Break;
    end;
  until BytesRead <= 0;

  RespCode := 200;
  RespBody := '{"status":"received"}';

  if ParseRequest(RawHttp, Req) then
  begin
    Req.ClientIP := ClientIP;
    if Assigned(FServer.FOnWebhookReceived) then
      FServer.FOnWebhookReceived(FServer, Req, RespCode, RespBody);
  end
  else
  begin
    RespCode := 400;
    RespBody := '{"error":"Bad Request"}';
  end;

  ResponseHttp := Format(
    'HTTP/1.1 %d OK'#13#10 +
    'Content-Type: application/json; charset=utf-8'#13#10 +
    'Content-Length: %d'#13#10 +
    'Connection: close'#13#10#13#10 +
    '%s', [RespCode, Length(RespBody), RespBody]);

  fpsend(ClientSocket, Pointer(ResponseHttp), Length(ResponseHttp), 0);
  CloseSocket(ClientSocket);
end;

procedure TWebhookListenerThread.Execute;
var
  ServerAddr, ClientAddr: TInetSockAddr;
  ClientSocket: LongInt;
  AddrLen: TSockLen;
  ClientIP: string;
begin
  FServerSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
  if FServerSocket < 0 then Exit;

  FillChar(ServerAddr, SizeOf(ServerAddr), 0);
  ServerAddr.sin_family := AF_INET;
  ServerAddr.sin_port := htons(FPort);
  ServerAddr.sin_addr.s_addr := 0; { INADDR_ANY }

  if fpBind(FServerSocket, @ServerAddr, SizeOf(ServerAddr)) <> 0 then
  begin
    CloseSocket(FServerSocket);
    FServerSocket := -1;
    Exit;
  end;

  if fpListen(FServerSocket, 10) <> 0 then
  begin
    CloseSocket(FServerSocket);
    FServerSocket := -1;
    Exit;
  end;

  while not Terminated do
  begin
    AddrLen := SizeOf(ClientAddr);
    ClientSocket := fpAccept(FServerSocket, @ClientAddr, @AddrLen);
    if ClientSocket >= 0 then
    begin
      ClientIP := NetAddrToStr(ClientAddr.sin_addr);
      HandleClient(ClientSocket, ClientIP);
    end;
  end;
end;

{ TLazEmbeddedWebhookServer }

constructor TLazEmbeddedWebhookServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPort := 8085;
  FActive := False;
  FListenerThread := nil;
  FSecretToken := '';
end;

destructor TLazEmbeddedWebhookServer.Destroy;
begin
  StopServer;
  inherited Destroy;
end;

procedure TLazEmbeddedWebhookServer.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      StartServer
    else
      StopServer;
  end;
end;

procedure TLazEmbeddedWebhookServer.StartServer;
begin
  if not FActive then
  begin
    FListenerThread := TWebhookListenerThread.Create(Self, FPort);
    FListenerThread.Start;
    FActive := True;
  end;
end;

procedure TLazEmbeddedWebhookServer.StopServer;
begin
  if FActive and Assigned(FListenerThread) then
  begin
    FListenerThread.Terminate;
    if FListenerThread.FServerSocket >= 0 then
      CloseSocket(FListenerThread.FServerSocket);
    FListenerThread.WaitFor;
    FreeAndNil(FListenerThread);
    FActive := False;
  end;
end;

end.
