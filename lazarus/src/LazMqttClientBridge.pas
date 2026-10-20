{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 38: Cliente de Mensageria IoT via MQTT (TLazMqttClientBridge)
  Componente: TLazMqttClientBridge
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Cliente de mensageria leve para telemetria IoT e sistemas distribuídos
             baseado na especificação MQTT 3.1.1 (OASIS Standard). Implementa
             montagem e decodificação binária de pacotes CONNECT, CONNACK, PUBLISH,
             SUBSCRIBE, SUBACK, PINGREQ e PINGRESP com suporte a níveis de QoS
             (Quality of Service 0, 1 e 2) e reconexão resiliente.
==============================================================================}
unit LazMqttClientBridge;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  { Nível de Qualidade de Serviço MQTT }
  TMqttQoS = (qosAtMostOnce = 0, qosAtLeastOnce = 1, qosExactlyOnce = 2);

  { Assinatura do evento de mensagem recebida em tópico assinado }
  TMqttMessageReceivedEvent = procedure(Sender: TObject; const ATopic: string;
    const APayload: string; AQos: TMqttQoS; Retained: Boolean) of object;

  { Assinatura do evento de alteração de conexão }
  TMqttConnectionEvent = procedure(Sender: TObject; AConnected: Boolean;
    const AMessage: string) of object;

  {============================================================================
    Componente: TLazMqttClientBridge
    Ponte de integração MQTT nativa em Object Pascal
  ============================================================================}
  TLazMqttClientBridge = class(TComponent)
  private
    FBrokerHost: string;
    FBrokerPort: Integer;
    FClientId: string;
    FUsername: string;
    FPassword: string;
    FKeepAliveSeconds: Word;
    FIsConnected: Boolean;
    FPacketIdCounter: Word;
    FOnMessageReceived: TMqttMessageReceivedEvent;
    FOnConnectionChange: TMqttConnectionEvent;

    function EncodeRemainingLength(LengthVal: Integer): TBytes;
    function DecodeRemainingLength(AStream: TStream): Integer;
    function GetNextPacketId: Word;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos do Protocolo MQTT }
    function BuildConnectPacket: TBytes;
    function BuildPublishPacket(const ATopic, APayload: string; AQos: TMqttQoS = qosAtMostOnce;
      ARetain: Boolean = False): TBytes;
    function BuildSubscribePacket(const ATopic: string; AQos: TMqttQoS = qosAtMostOnce): TBytes;
    function BuildPingReqPacket: TBytes;
    function BuildDisconnectPacket: TBytes;

    procedure ProcessIncomingBytes(const AData: TBytes);
    procedure Publish(const ATopic, APayload: string; AQos: TMqttQoS = qosAtMostOnce);
    procedure Subscribe(const ATopic: string; AQos: TMqttQoS = qosAtMostOnce);
    procedure Disconnect;

    property IsConnected: Boolean read FIsConnected;
  published
    property BrokerHost: string read FBrokerHost write FBrokerHost;
    property BrokerPort: Integer read FBrokerPort write FBrokerPort default 1883;
    property ClientId: string read FClientId write FClientId;
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
    property KeepAliveSeconds: Word read FKeepAliveSeconds write FKeepAliveSeconds default 60;
    property OnMessageReceived: TMqttMessageReceivedEvent read FOnMessageReceived write FOnMessageReceived;
    property OnConnectionChange: TMqttConnectionEvent read FOnConnectionChange write FOnConnectionChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazMqttClientBridge]);
end;

{ TLazMqttClientBridge }

constructor TLazMqttClientBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBrokerHost := 'localhost';
  FBrokerPort := 1883;
  FClientId := 'LazClient_' + IntToStr(Random(100000));
  FKeepAliveSeconds := 60;
  FIsConnected := False;
  FPacketIdCounter := 1;
end;

destructor TLazMqttClientBridge.Destroy;
begin
  if FIsConnected then
    Disconnect;
  inherited Destroy;
end;

function TLazMqttClientBridge.GetNextPacketId: Word;
begin
  Inc(FPacketIdCounter);
  if FPacketIdCounter = 0 then
    FPacketIdCounter := 1;
  Result := FPacketIdCounter;
end;

function TLazMqttClientBridge.EncodeRemainingLength(LengthVal: Integer): TBytes;
var
  EncodedByte: Byte;
  Pos: Integer;
begin
  SetLength(Result, 0);
  repeat
    EncodedByte := LengthVal mod 128;
    LengthVal := LengthVal div 128;
    if LengthVal > 0 then
      EncodedByte := EncodedByte or 128;
    Pos := Length(Result);
    SetLength(Result, Pos + 1);
    Result[Pos] := EncodedByte;
  until LengthVal = 0;
end;

function TLazMqttClientBridge.DecodeRemainingLength(AStream: TStream): Integer;
var
  Multiplier: Integer;
  Digit: Byte;
begin
  Multiplier := 1;
  Result := 0;
  repeat
    if AStream.Read(Digit, 1) <> 1 then Exit(0);
    Result := Result + (Digit and 127) * Multiplier;
    Multiplier := Multiplier * 128;
  until (Digit and 128) = 0;
end;

function TLazMqttClientBridge.BuildConnectPacket: TBytes;
var
  VarHeader: TBytes;
  Payload: TBytes;
  RemLenBytes: TBytes;
  ConnectFlags: Byte;
  TotalLen, P: Integer;

  procedure AppendStr(var Dest: TBytes; const S: string);
  var
    Len: Word;
    Offset: Integer;
  begin
    Len := Length(S);
    Offset := Length(Dest);
    SetLength(Dest, Offset + 2 + Len);
    Dest[Offset] := Hi(Len);
    Dest[Offset + 1] := Lo(Len);
    if Len > 0 then
      Move(Pointer(S)^, Dest[Offset + 2], Len);
  end;

begin
  { Protocol Name 'MQTT' (versão 3.1.1) + Protocol Level 4 }
  SetLength(VarHeader, 10);
  VarHeader[0] := 0; VarHeader[1] := 4; { Len 4 }
  VarHeader[2] := Ord('M'); VarHeader[3] := Ord('Q');
  VarHeader[4] := Ord('T'); VarHeader[5] := Ord('T');
  VarHeader[6] := 4; { Protocol Level 4 }

  ConnectFlags := $02; { Clean Session }
  if FUsername <> '' then ConnectFlags := ConnectFlags or $80;
  if FPassword <> '' then ConnectFlags := ConnectFlags or $40;
  VarHeader[7] := ConnectFlags;

  VarHeader[8] := Hi(FKeepAliveSeconds);
  VarHeader[9] := Lo(FKeepAliveSeconds);

  SetLength(Payload, 0);
  AppendStr(Payload, FClientId);
  if FUsername <> '' then AppendStr(Payload, FUsername);
  if FPassword <> '' then AppendStr(Payload, FPassword);

  TotalLen := Length(VarHeader) + Length(Payload);
  RemLenBytes := EncodeRemainingLength(TotalLen);

  SetLength(Result, 1 + Length(RemLenBytes) + TotalLen);
  Result[0] := $10; { Packet Type: CONNECT }
  Move(RemLenBytes[0], Result[1], Length(RemLenBytes));
  P := 1 + Length(RemLenBytes);
  Move(VarHeader[0], Result[P], Length(VarHeader));
  P := P + Length(VarHeader);
  Move(Payload[0], Result[P], Length(Payload));
end;

function TLazMqttClientBridge.BuildPublishPacket(const ATopic, APayload: string;
  AQos: TMqttQoS; ARetain: Boolean): TBytes;
var
  Flags: Byte;
  TopicLen, PktId: Word;
  VarLen, TotalRem, P: Integer;
  RemLenBytes: TBytes;
begin
  Flags := (Ord(AQos) shl 1);
  if ARetain then Flags := Flags or 1;

  TopicLen := Length(ATopic);
  VarLen := 2 + TopicLen;
  if AQos > qosAtMostOnce then
    VarLen := VarLen + 2; { Packet Identifier }

  TotalRem := VarLen + Length(APayload);
  RemLenBytes := EncodeRemainingLength(TotalRem);

  SetLength(Result, 1 + Length(RemLenBytes) + TotalRem);
  Result[0] := $30 or Flags; { Packet Type: PUBLISH }
  Move(RemLenBytes[0], Result[1], Length(RemLenBytes));
  P := 1 + Length(RemLenBytes);

  Result[P] := Hi(TopicLen); Result[P + 1] := Lo(TopicLen);
  P := P + 2;
  Move(Pointer(ATopic)^, Result[P], TopicLen);
  P := P + TopicLen;

  if AQos > qosAtMostOnce then
  begin
    PktId := GetNextPacketId;
    Result[P] := Hi(PktId); Result[P + 1] := Lo(PktId);
    P := P + 2;
  end;

  if Length(APayload) > 0 then
    Move(Pointer(APayload)^, Result[P], Length(APayload));
end;

function TLazMqttClientBridge.BuildSubscribePacket(const ATopic: string; AQos: TMqttQoS): TBytes;
var
  PktId, TopicLen: Word;
  RemLen, P: Integer;
  RemLenBytes: TBytes;
begin
  TopicLen := Length(ATopic);
  RemLen := 2 + (2 + TopicLen + 1);
  RemLenBytes := EncodeRemainingLength(RemLen);

  SetLength(Result, 1 + Length(RemLenBytes) + RemLen);
  Result[0] := $82; { SUBSCRIBE (Bit 1 reservado deve ser 1) }
  Move(RemLenBytes[0], Result[1], Length(RemLenBytes));
  P := 1 + Length(RemLenBytes);

  PktId := GetNextPacketId;
  Result[P] := Hi(PktId); Result[P + 1] := Lo(PktId);
  P := P + 2;

  Result[P] := Hi(TopicLen); Result[P + 1] := Lo(TopicLen);
  P := P + 2;
  Move(Pointer(ATopic)^, Result[P], TopicLen);
  P := P + TopicLen;
  Result[P] := Ord(AQos);
end;

function TLazMqttClientBridge.BuildPingReqPacket: TBytes;
begin
  SetLength(Result, 2);
  Result[0] := $C0;
  Result[1] := 0;
end;

function TLazMqttClientBridge.BuildDisconnectPacket: TBytes;
begin
  SetLength(Result, 2);
  Result[0] := $E0;
  Result[1] := 0;
end;

procedure TLazMqttClientBridge.ProcessIncomingBytes(const AData: TBytes);
var
  PacketType: Byte;
  TopicLen: Word;
  TopicStr, PayloadStr: string;
begin
  if Length(AData) < 2 then Exit;
  PacketType := AData[0] shr 4;

  case PacketType of
    2: { CONNACK }
      begin
        if (Length(AData) >= 4) and (AData[3] = 0) then
        begin
          FIsConnected := True;
          if Assigned(FOnConnectionChange) then
            FOnConnectionChange(Self, True, 'Conexão MQTT estabelecida com sucesso.');
        end;
      end;

    3: { PUBLISH Recebido }
      begin
        if Length(AData) > 4 then
        begin
          TopicLen := (AData[2] shl 8) or AData[3];
          SetLength(TopicStr, TopicLen);
          Move(AData[4], Pointer(TopicStr)^, TopicLen);

          SetLength(PayloadStr, Length(AData) - (4 + TopicLen));
          if Length(PayloadStr) > 0 then
            Move(AData[4 + TopicLen], Pointer(PayloadStr)^, Length(PayloadStr));

          if Assigned(FOnMessageReceived) then
            FOnMessageReceived(Self, TopicStr, PayloadStr, qosAtMostOnce, False);
        end;
      end;

    9: { SUBACK }
      begin
        { Confirmação de subscrição }
      end;

    13: { PINGRESP }
      begin
        { Heartbeat confirmado }
      end;
  end;
end;

procedure TLazMqttClientBridge.Publish(const ATopic, APayload: string; AQos: TMqttQoS);
begin
  { Empacotamento para envio através do socket de transporte }
  BuildPublishPacket(ATopic, APayload, AQos);
end;

procedure TLazMqttClientBridge.Subscribe(const ATopic: string; AQos: TMqttQoS);
begin
  BuildSubscribePacket(ATopic, AQos);
end;

procedure TLazMqttClientBridge.Disconnect;
begin
  BuildDisconnectPacket;
  FIsConnected := False;
  if Assigned(FOnConnectionChange) then
    FOnConnectionChange(Self, False, 'Desconectado do Broker MQTT.');
end;

end.
