{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 39: Servidor de Webhooks Embutido (TDlpEmbeddedWebhookServer)
  Componente: TDlpEmbeddedWebhookServer
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux)
  Descrição: Microservidor HTTP embutido de altíssimo desempenho para recepção
             de callbacks e notificações assíncronas (Webhooks de gateways de
             pagamento, integrações bancárias Pix e pipelines de GitHub).
             Opera com listener TCP nativo multithread sem depender de IIS ou Apache.
==============================================================================}
unit DlpEmbeddedWebhookServer;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.WinSock2;

type
  { Estrutura contendo metadados e payload da requisição HTTP }
  TDlpWebhookRequest = record
    Method: string;
    Path: string;
    QueryString: string;
    ContentType: string;
    Signature: string;
    RawBody: string;
    ClientIP: string;
  end;

  { Assinatura do evento de tratamento de Webhook }
  TDlpWebhookReceivedEvent = procedure(Sender: TObject; const ARequest: TDlpWebhookRequest;
    var AResponseCode: Integer; var AResponseBody: string) of object;

  { Declaração antecipada }
  TDlpEmbeddedWebhookServer = class;

  { Thread de escuta de conexões de rede }
  TDlpWebhookListenerThread = class(TThread)
  private
    FServer: TDlpEmbeddedWebhookServer;
    FServerSocket: TSocket;
    FPort: Word;

    procedure HandleClient(ClientSocket: TSocket; const ClientIP: string);
    function ParseRequest(const RawHttp: string; out Req: TDlpWebhookRequest): Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AServer: TDlpEmbeddedWebhookServer; APort: Word);
    destructor Destroy; override;
  end;

  {============================================================================
    Componente: TDlpEmbeddedWebhookServer
    Servidor HTTP de Webhooks embutido
  ============================================================================}
  TDlpEmbeddedWebhookServer = class(TComponent)
  private
    FPort: Word;
    FActive: Boolean;
    FListenerThread: TDlpWebhookListenerThread;
    FSecretToken: string;
    FOnWebhookReceived: TDlpWebhookReceivedEvent;

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
    property OnWebhookReceived: TDlpWebhookReceivedEvent read FOnWebhookReceived write FOnWebhookReceived;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpEmbeddedWebhookServer]);
end;

{ TDlpWebhookListenerThread }

constructor TDlpWebhookListenerThread.Create(AServer: TDlpEmbeddedWebhookServer; APort: Word);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FServer := AServer;
  FPort := APort;
  FServerSocket := INVALID_SOCKET;
end;

destructor TDlpWebhookListenerThread.Destroy;
begin
  if FServerSocket <> INVALID_SOCKET then
    closesocket(FServerSocket);
  inherited Destroy;
end;

function TDlpWebhookListenerThread.ParseRequest(const RawHttp: string; out Req: TDlpWebhookRequest): Boolean;
var
  Lines: TStringList;
  i, P, BodyStart: Integer;
  FirstLine, HeaderLine: string;
  Parts: TArray<string>;
begin
  Result := False;
  Req := Default(TDlpWebhookRequest);
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
        Break;

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

procedure TDlpWebhookListenerThread.HandleClient(ClientSocket: TSocket; const ClientIP: string);
var
  Buffer: array[0..8191] of AnsiChar;
  BytesRead: Integer;
  RawHttp: string;
  Req: TDlpWebhookRequest;
  RespCode: Integer;
  RespBody: string;
  ResponseHttp: AnsiString;
begin
  RawHttp := '';
  repeat
    BytesRead := recv(ClientSocket, Buffer[0], SizeOf(Buffer) - 1, 0);
    if BytesRead > 0 then
    begin
      Buffer[BytesRead] := #0;
      RawHttp := RawHttp + string(AnsiString(Buffer));
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

  ResponseHttp := AnsiString(Format(
    'HTTP/1.1 %d OK'#13#10 +
    'Content-Type: application/json; charset=utf-8'#13#10 +
    'Content-Length: %d'#13#10 +
    'Connection: close'#13#10#13#10 +
    '%s', [RespCode, Length(RespBody), RespBody]));

  send(ClientSocket, Pointer(ResponseHttp)^, Length(ResponseHttp), 0);
  closesocket(ClientSocket);
end;

procedure TDlpWebhookListenerThread.Execute;
var
  WSA: TWSAData;
  ServerAddr, ClientAddr: TSockAddrIn;
  ClientSocket: TSocket;
  AddrLen: Integer;
  ClientIP: string;
begin
  WSAStartup($0202, WSA);
  try
    FServerSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FServerSocket = INVALID_SOCKET then Exit;

    FillChar(ServerAddr, SizeOf(ServerAddr), 0);
    ServerAddr.sin_family := AF_INET;
    ServerAddr.sin_port := htons(FPort);
    ServerAddr.sin_addr.S_addr := INADDR_ANY;

    if bind(FServerSocket, sockaddr(ServerAddr), SizeOf(ServerAddr)) <> 0 then
    begin
      closesocket(FServerSocket);
      FServerSocket := INVALID_SOCKET;
      Exit;
    end;

    if listen(FServerSocket, SOMAXCONN) <> 0 then
    begin
      closesocket(FServerSocket);
      FServerSocket := INVALID_SOCKET;
      Exit;
    end;

    while not Terminated do
    begin
      AddrLen := SizeOf(ClientAddr);
      ClientSocket := accept(FServerSocket, @ClientAddr, @AddrLen);
      if ClientSocket <> INVALID_SOCKET then
      begin
        ClientIP := string(inet_ntoa(ClientAddr.sin_addr));
        HandleClient(ClientSocket, ClientIP);
      end;
    end;
  finally
    WSACleanup;
  end;
end;

{ TDlpEmbeddedWebhookServer }

constructor TDlpEmbeddedWebhookServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPort := 8085;
  FActive := False;
  FListenerThread := nil;
  FSecretToken := '';
end;

destructor TDlpEmbeddedWebhookServer.Destroy;
begin
  StopServer;
  inherited Destroy;
end;

procedure TDlpEmbeddedWebhookServer.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      StartServer
    else
      StopServer;
  end;
end;

procedure TDlpEmbeddedWebhookServer.StartServer;
begin
  if not FActive then
  begin
    FListenerThread := TDlpWebhookListenerThread.Create(Self, FPort);
    FListenerThread.Start;
    FActive := True;
  end;
end;

procedure TDlpEmbeddedWebhookServer.StopServer;
begin
  if FActive and Assigned(FListenerThread) then
  begin
    FListenerThread.Terminate;
    if FListenerThread.FServerSocket <> INVALID_SOCKET then
      closesocket(FListenerThread.FServerSocket);
    FListenerThread.WaitFor;
    FreeAndNil(FListenerThread);
    FActive := False;
  end;
end;

end.
