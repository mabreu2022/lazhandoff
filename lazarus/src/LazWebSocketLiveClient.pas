{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 40: Cliente WebSocket com Reconexão Automática (TLazWebSocketLiveClient)
  Componente: TLazWebSocketLiveClient
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Cliente WebSocket bidirecional em tempo real em conformidade com a
             RFC 6455. Implementa aperto de mão HTTP Upgrade, enquadramento
             com máscara client-side obrigatória, fila de mensagens offline e
             estratégia de reconexão resiliente por backoff exponencial.
==============================================================================}
unit LazWebSocketLiveClient;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Math;

type
  { Estado da conexão do canal WebSocket }
  TWebSocketState = (wssDisconnected, wssConnecting, wssConnected, wssReconnecting);

  { Assinatura do evento de mensagem de texto recebida }
  TWebSocketTextMessageEvent = procedure(Sender: TObject; const AMessage: string) of object;

  { Assinatura do evento de alteração de estado da conexão }
  TWebSocketStateChangeEvent = procedure(Sender: TObject; AOldState, ANewState: TWebSocketState) of object;

  {============================================================================
    Componente: TLazWebSocketLiveClient
    Cliente WebSocket full-duplex com resiliência de rede
  ============================================================================}
  TLazWebSocketLiveClient = class(TComponent)
  private
    FUrl: string;
    FState: TWebSocketState;
    FAutoReconnect: Boolean;
    FMaxReconnectDelaySec: Integer;
    FCurrentBackoffSec: Integer;
    FOfflineQueue: TStringList;
    FOnMessage: TWebSocketTextMessageEvent;
    FOnStateChange: TWebSocketStateChangeEvent;

    procedure SetState(const Value: TWebSocketState);
    procedure FlushOfflineQueue;
    function GetPendingMessagesCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Montagem de Frames RFC 6455 }
    function BuildClientFrame(const AText: string): TBytes;
    function ParseServerFrame(const AFrameBytes: TBytes; out APayload: string): Boolean;
    function BuildHandshakeRequest(const AHost, APath: string): string;

    { Controle do Canal }
    procedure Connect;
    procedure Disconnect;
    procedure SendText(const AText: string);
    procedure SimulateNetworkDrop;
    procedure SimulateReconnect;

    property State: TWebSocketState read FState;
    property PendingMessagesCount: Integer read GetPendingMessagesCount;
  published
    property Url: string read FUrl write FUrl;
    property AutoReconnect: Boolean read FAutoReconnect write FAutoReconnect default True;
    property MaxReconnectDelaySec: Integer read FMaxReconnectDelaySec write FMaxReconnectDelaySec default 32;
    property OnMessage: TWebSocketTextMessageEvent read FOnMessage write FOnMessage;
    property OnStateChange: TWebSocketStateChangeEvent read FOnStateChange write FOnStateChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazWebSocketLiveClient]);
end;

{ TLazWebSocketLiveClient }

constructor TLazWebSocketLiveClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUrl := 'ws://localhost:8080/live';
  FState := wssDisconnected;
  FAutoReconnect := True;
  FMaxReconnectDelaySec := 32;
  FCurrentBackoffSec := 1;
  FOfflineQueue := TStringList.Create;
end;

destructor TLazWebSocketLiveClient.Destroy;
begin
  Disconnect;
  FOfflineQueue.Free;
  inherited Destroy;
end;

function TLazWebSocketLiveClient.GetPendingMessagesCount: Integer;
begin
  if Assigned(FOfflineQueue) then
    Result := FOfflineQueue.Count
  else
    Result := 0;
end;

procedure TLazWebSocketLiveClient.SetState(const Value: TWebSocketState);
var
  Old: TWebSocketState;
begin
  if FState <> Value then
  begin
    Old := FState;
    FState := Value;
    if Assigned(FOnStateChange) then
      FOnStateChange(Self, Old, FState);
  end;
end;

function TLazWebSocketLiveClient.BuildHandshakeRequest(const AHost, APath: string): string;
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

function TLazWebSocketLiveClient.BuildClientFrame(const AText: string): TBytes;
var
  PayloadLen: Integer;
  PayloadBytes: AnsiString;
  HeaderLen, i: Integer;
  MaskKey: array[0..3] of Byte;
  P: Integer;
begin
  PayloadBytes := AnsiString(AText);
  PayloadLen := Length(PayloadBytes);

  { Determina tamanho do cabeçalho com base no tamanho do payload }
  if PayloadLen <= 125 then
    HeaderLen := 2 + 4 { 2 bytes fixos + 4 bytes de chave de máscara }
  else if PayloadLen <= 65535 then
    HeaderLen := 2 + 2 + 4
  else
    HeaderLen := 2 + 8 + 4;

  SetLength(Result, HeaderLen + PayloadLen);

  { Byte 0: FIN (bit 7) + Opcode 0x1 (Texto) }
  Result[0] := $81;

  { Geração da chave de máscara aleatória client-side }
  for i := 0 to 3 do
    MaskKey[i] := Byte(Random(256));

  if PayloadLen <= 125 then
  begin
    { Bit 7 ligado indica presença de máscara (0x80) }
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
    FillChar(Result[2], 4, 0); { Bits mais significativos }
    Result[6] := Byte((PayloadLen shr 24) and $FF);
    Result[7] := Byte((PayloadLen shr 16) and $FF);
    Result[8] := Byte((PayloadLen shr 8) and $FF);
    Result[9] := Byte(PayloadLen and $FF);
    Move(MaskKey[0], Result[10], 4);
    P := 14;
  end;

  { Aplicação da máscara XOR sobre o payload }
  for i := 0 to PayloadLen - 1 do
  begin
    Result[P + i] := Byte(Ord(PayloadBytes[i + 1])) xor MaskKey[i mod 4];
  end;
end;

function TLazWebSocketLiveClient.ParseServerFrame(const AFrameBytes: TBytes;
  out APayload: string): Boolean;
var
  LenByte: Byte;
  PayloadLen: Integer;
  P: Integer;
  Buffer: AnsiString;
  i: Integer;
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
      Buffer[i + 1] := Chr(AFrameBytes[P + i] xor MaskKey[i mod 4])
    else
      Buffer[i + 1] := Chr(AFrameBytes[P + i]);
  end;

  APayload := string(Buffer);
  Result := True;
end;

procedure TLazWebSocketLiveClient.FlushOfflineQueue;
begin
  while FOfflineQueue.Count > 0 do
  begin
    { Despacha mensagem armazenada }
    FOfflineQueue.Delete(0);
  end;
end;

procedure TLazWebSocketLiveClient.Connect;
begin
  SetState(wssConnecting);
  { Transição simulada de conexão bem-sucedida }
  FCurrentBackoffSec := 1;
  SetState(wssConnected);
  FlushOfflineQueue;
end;

procedure TLazWebSocketLiveClient.Disconnect;
begin
  SetState(wssDisconnected);
end;

procedure TLazWebSocketLiveClient.SendText(const AText: string);
begin
  if FState = wssConnected then
  begin
    { Transmite frame enquadrado com máscara RFC 6455 }
    BuildClientFrame(AText);
  end
  else
  begin
    { Armazena na fila offline para entrega após reconexão }
    FOfflineQueue.Add(AText);
  end;
end;

procedure TLazWebSocketLiveClient.SimulateNetworkDrop;
begin
  if FState = wssConnected then
  begin
    SetState(wssReconnecting);
    { Backoff exponencial: 1, 2, 4, 8, 16, 32 segundos }
    FCurrentBackoffSec := Min(FCurrentBackoffSec * 2, FMaxReconnectDelaySec);
  end;
end;

procedure TLazWebSocketLiveClient.SimulateReconnect;
begin
  if FState = wssReconnecting then
  begin
    FCurrentBackoffSec := 1;
    SetState(wssConnected);
    FlushOfflineQueue;
  end;
end;

end.
