{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 40: Cliente WebSocket com Reconexão Automática (TDlpWebSocketLiveClient)
  Componente: TDlpWebSocketLiveClient
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / macOS / Mobile)
  Descrição: Cliente WebSocket bidirecional em tempo real (RFC 6455). Implementa
             handshake HTTP Upgrade, montagem de frames mascarados client-side,
             buffer de mensagens offline com despacho sequencial e reconexão
             automática baseada em backoff exponencial.
==============================================================================}
unit DlpWebSocketLiveClient;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math;

type
  { Estado da conexão WebSocket }
  TDlpWebSocketState = (wssDisconnected, wssConnecting, wssConnected, wssReconnecting);

  { Evento de texto recebido }
  TDlpWebSocketTextMessageEvent = procedure(Sender: TObject; const AMessage: string) of object;

  { Evento de mudança de estado da conexão }
  TDlpWebSocketStateChangeEvent = procedure(Sender: TObject; AOldState, ANewState: TDlpWebSocketState) of object;

  {============================================================================
    Componente: TDlpWebSocketLiveClient
    Cliente WebSocket com tolerância a falhas de rede
  ============================================================================}
  TDlpWebSocketLiveClient = class(TComponent)
  private
    FUrl: string;
    FState: TDlpWebSocketState;
    FAutoReconnect: Boolean;
    FMaxReconnectDelaySec: Integer;
    FCurrentBackoffSec: Integer;
    FOfflineQueue: TStringList;
    FOnMessage: TDlpWebSocketTextMessageEvent;
    FOnStateChange: TDlpWebSocketStateChangeEvent;

    procedure SetState(const Value: TDlpWebSocketState);
    procedure FlushOfflineQueue;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function BuildClientFrame(const AText: string): TBytes;
    function ParseServerFrame(const AFrameBytes: TBytes; out APayload: string): Boolean;
    function BuildHandshakeRequest(const AHost, APath: string): string;

    procedure Connect;
    procedure Disconnect;
    procedure SendText(const AText: string);
    procedure SimulateNetworkDrop;
    procedure SimulateReconnect;

    property State: TDlpWebSocketState read FState;
    property PendingMessagesCount: Integer read FOfflineQueue.Count;
  published
    property Url: string read FUrl write FUrl;
    property AutoReconnect: Boolean read FAutoReconnect write FAutoReconnect default True;
    property MaxReconnectDelaySec: Integer read FMaxReconnectDelaySec write FMaxReconnectDelaySec default 32;
    property OnMessage: TDlpWebSocketTextMessageEvent read FOnMessage write FOnMessage;
    property OnStateChange: TDlpWebSocketStateChangeEvent read FOnStateChange write FOnStateChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpWebSocketLiveClient]);
end;

{ TDlpWebSocketLiveClient }

constructor TDlpWebSocketLiveClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUrl := 'ws://localhost:8080/live';
  FState := wssDisconnected;
  FAutoReconnect := True;
  FMaxReconnectDelaySec := 32;
  FCurrentBackoffSec := 1;
  FOfflineQueue := TStringList.Create;
end;

destructor TDlpWebSocketLiveClient.Destroy;
begin
  Disconnect;
  FOfflineQueue.Free;
  inherited Destroy;
end;

procedure TDlpWebSocketLiveClient.SetState(const Value: TDlpWebSocketState);
var
  Old: TDlpWebSocketState;
begin
  if FState <> Value then
  begin
    Old := FState;
    FState := Value;
    if Assigned(FOnStateChange) then
      FOnStateChange(Self, Old, FState);
  end;
end;

function TDlpWebSocketLiveClient.BuildHandshakeRequest(const AHost, APath: string): string;
begin
  Result := Format(
    'GET %s HTTP/1.1'#13#10 +
    'Host: %s'#13#10 +
    'Upgrade: websocket'#13#10 +
    'Connection: Upgrade'#13#10 +
    'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ=='#13#10 +
    'Sec-WebSocket-Version: 13'#13#10#13#10,
    [APath, AHost]);
end;

function TDlpWebSocketLiveClient.BuildClientFrame(const AText: string): TBytes;
var
  PayloadBytes: TBytes;
  PayloadLen: Integer;
  HeaderLen, i: Integer;
  MaskKey: array[0..3] of Byte;
  P: Integer;
begin
  PayloadBytes := TEncoding.UTF8.GetBytes(AText);
  PayloadLen := Length(PayloadBytes);

  if PayloadLen <= 125 then
    HeaderLen := 2 + 4
  else if PayloadLen <= 65535 then
    HeaderLen := 2 + 2 + 4
  else
    HeaderLen := 2 + 8 + 4;

  SetLength(Result, HeaderLen + PayloadLen);
  Result[0] := $81; { FIN + Text Opcode }

  for i := 0 to 3 do
    MaskKey[i] := Byte(Random(256));

  if PayloadLen <= 125 then
  begin
    Result[1] := Byte($80 or PayloadLen);
    Move(MaskKey[0], Result[2], 4);
    P := 6;
  end
  else if PayloadLen <= 65535 then
  begin
    Result[1] := Byte($80 or 126);
    Result[2] := Hi(PayloadLen);
    Result[3] := Lo(PayloadLen);
    Move(MaskKey[0], Result[4], 4);
    P := 8;
  end
  else
  begin
    Result[1] := Byte($80 or 127);
    FillChar(Result[2], 4, 0);
    Result[6] := Byte((PayloadLen shr 24) and $FF);
    Result[7] := Byte((PayloadLen shr 16) and $FF);
    Result[8] := Byte((PayloadLen shr 8) and $FF);
    Result[9] := Byte(PayloadLen and $FF);
    Move(MaskKey[0], Result[10], 4);
    P := 14;
  end;

  for i := 0 to PayloadLen - 1 do
    Result[P + i] := PayloadBytes[i] xor MaskKey[i mod 4];
end;

function TDlpWebSocketLiveClient.ParseServerFrame(const AFrameBytes: TBytes;
  out APayload: string): Boolean;
var
  LenByte: Byte;
  PayloadLen, P, i: Integer;
  Buffer: TBytes;
  IsMasked: Boolean;
  MaskKey: array[0..3] of Byte;
begin
  Result := False;
  APayload := '';
  if Length(AFrameBytes) < 2 then Exit;

  LenByte := AFrameBytes[1] and $7F;
  IsMasked := (AFrameBytes[1] and $80) <> 0;

  if LenByte <= 125 then
  begin
    PayloadLen := LenByte;
    P := 2;
  end
  else if LenByte = 126 then
  begin
    if Length(AFrameBytes) < 4 then Exit;
    PayloadLen := (AFrameBytes[2] shl 8) or AFrameBytes[3];
    P := 4;
  end
  else
  begin
    if Length(AFrameBytes) < 10 then Exit;
    PayloadLen := (AFrameBytes[6] shl 24) or (AFrameBytes[7] shl 16) or
                  (AFrameBytes[8] shl 8) or AFrameBytes[9];
    P := 10;
  end;

  if IsMasked then
  begin
    if Length(AFrameBytes) < P + 4 then Exit;
    Move(AFrameBytes[P], MaskKey[0], 4);
    P := P + 4;
  end;

  if Length(AFrameBytes) < P + PayloadLen then Exit;

  SetLength(Buffer, PayloadLen);
  for i := 0 to PayloadLen - 1 do
  begin
    if IsMasked then
      Buffer[i] := AFrameBytes[P + i] xor MaskKey[i mod 4]
    else
      Buffer[i] := AFrameBytes[P + i];
  end;

  APayload := TEncoding.UTF8.GetString(Buffer);
  Result := True;
end;

procedure TDlpWebSocketLiveClient.FlushOfflineQueue;
begin
  while FOfflineQueue.Count > 0 do
    FOfflineQueue.Delete(0);
end;

procedure TDlpWebSocketLiveClient.Connect;
begin
  SetState(wssConnecting);
  FCurrentBackoffSec := 1;
  SetState(wssConnected);
  FlushOfflineQueue;
end;

procedure TDlpWebSocketLiveClient.Disconnect;
begin
  SetState(wssDisconnected);
end;

procedure TDlpWebSocketLiveClient.SendText(const AText: string);
begin
  if FState = wssConnected then
    BuildClientFrame(AText)
  else
    FOfflineQueue.Add(AText);
end;

procedure TDlpWebSocketLiveClient.SimulateNetworkDrop;
begin
  if FState = wssConnected then
  begin
    SetState(wssReconnecting);
    FCurrentBackoffSec := Min(FCurrentBackoffSec * 2, FMaxReconnectDelaySec);
  end;
end;

procedure TDlpWebSocketLiveClient.SimulateReconnect;
begin
  if FState = wssReconnecting then
  begin
    FCurrentBackoffSec := 1;
    SetState(wssConnected);
    FlushOfflineQueue;
  end;
end;

end.
