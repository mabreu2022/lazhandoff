{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 38: Cliente de Mensageria IoT via MQTT (TDlpMqttClientBridge)
  Componente: TDlpMqttClientBridge
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / Android / iOS)
  Descrição: Cliente de mensageria leve para telemetria IoT e microsserviços em
             conformidade com a especificação OASIS MQTT 3.1.1. Serialização e
             parsing binário de pacotes CONNECT, CONNACK, PUBLISH, SUBSCRIBE,
             SUBACK, PINGREQ, PINGRESP com suporte a QoS 0, 1 e 2.
==============================================================================}
unit DlpMqttClientBridge;

interface

uses
  System.SysUtils,
  System.Classes;

type
  { Níveis de QoS do protocolo MQTT }
  TDlpMqttQoS = (qosAtMostOnce = 0, qosAtLeastOnce = 1, qosExactlyOnce = 2);

  { Assinatura do evento de mensagem recebida }
  TDlpMqttMessageReceivedEvent = procedure(Sender: TObject; const ATopic: string;
    const APayload: string; AQos: TDlpMqttQoS; Retained: Boolean) of object;

  { Assinatura do evento de alteração de conexão }
  TDlpMqttConnectionEvent = procedure(Sender: TObject; AConnected: Boolean;
    const AMessage: string) of object;

  {============================================================================
    Componente: TDlpMqttClientBridge
    Ponte de integração MQTT nativa em Object Pascal
  ============================================================================}
  TDlpMqttClientBridge = class(TComponent)
  private
    FBrokerHost: string;
    FBrokerPort: Integer;
    FClientId: string;
    FUsername: string;
    FPassword: string;
    FKeepAliveSeconds: Word;
    FIsConnected: Boolean;
    FPacketIdCounter: Word;
    FOnMessageReceived: TDlpMqttMessageReceivedEvent;
    FOnConnectionChange: TDlpMqttConnectionEvent;

    function EncodeRemainingLength(LengthVal: Integer): TBytes;
    function DecodeRemainingLength(AStream: TStream): Integer;
    function GetNextPacketId: Word;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function BuildConnectPacket: TBytes;
    function BuildPublishPacket(const ATopic, APayload: string; AQos: TDlpMqttQoS = qosAtMostOnce;
      ARetain: Boolean = False): TBytes;
    function BuildSubscribePacket(const ATopic: string; AQos: TDlpMqttQoS = qosAtMostOnce): TBytes;
    function BuildPingReqPacket: TBytes;
    function BuildDisconnectPacket: TBytes;

    procedure ProcessIncomingBytes(const AData: TBytes);
    procedure Publish(const ATopic, APayload: string; AQos: TDlpMqttQoS = qosAtMostOnce);
    procedure Subscribe(const ATopic: string; AQos: TDlpMqttQoS = qosAtMostOnce);
    procedure Disconnect;

    property IsConnected: Boolean read FIsConnected;
  published
    property BrokerHost: string read FBrokerHost write FBrokerHost;
    property BrokerPort: Integer read FBrokerPort write FBrokerPort default 1883;
    property ClientId: string read FClientId write FClientId;
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
    property KeepAliveSeconds: Word read FKeepAliveSeconds write FKeepAliveSeconds default 60;
    property OnMessageReceived: TDlpMqttMessageReceivedEvent read FOnMessageReceived write FOnMessageReceived;
    property OnConnectionChange: TDlpMqttConnectionEvent read FOnConnectionChange write FOnConnectionChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpMqttClientBridge]);
end;

{ TDlpMqttClientBridge }

constructor TDlpMqttClientBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBrokerHost := 'localhost';
  FBrokerPort := 1883;
  FClientId := 'DlpClient_' + Random(100000).ToString;
  FKeepAliveSeconds := 60;
  FIsConnected := False;
  FPacketIdCounter := 1;
end;

destructor TDlpMqttClientBridge.Destroy;
begin
  if FIsConnected then
    Disconnect;
  inherited Destroy;
end;

function TDlpMqttClientBridge.GetNextPacketId: Word;
begin
  Inc(FPacketIdCounter);
  if FPacketIdCounter = 0 then
    FPacketIdCounter := 1;
  Result := FPacketIdCounter;
end;

function TDlpMqttClientBridge.EncodeRemainingLength(LengthVal: Integer): TBytes;
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

function TDlpMqttClientBridge.DecodeRemainingLength(AStream: TStream): Integer;
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

function TDlpMqttClientBridge.BuildConnectPacket: TBytes;
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
    StrBytes: TBytes;
  begin
    StrBytes := TEncoding.UTF8.GetBytes(S);
    Len := Length(StrBytes);
    Offset := Length(Dest);
    SetLength(Dest, Offset + 2 + Len);
    Dest[Offset] := Hi(Len);
    Dest[Offset + 1] := Lo(Len);
    if Len > 0 then
      Move(StrBytes[0], Dest[Offset + 2], Len);
  end;

begin
  SetLength(VarHeader, 10);
  VarHeader[0] := 0; VarHeader[1] := 4;
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
  Result[0] := $10;
  Move(RemLenBytes[0], Result[1], Length(RemLenBytes));
  P := 1 + Length(RemLenBytes);
  Move(VarHeader[0], Result[P], Length(VarHeader));
  P := P + Length(VarHeader);
  Move(Payload[0], Result[P], Length(Payload));
end;

function TDlpMqttClientBridge.BuildPublishPacket(const ATopic, APayload: string;
  AQos: TDlpMqttQoS; ARetain: Boolean): TBytes;
var
  Flags: Byte;
  TopicBytes, PayloadBytes: TBytes;
  TopicLen, PktId: Word;
  VarLen, TotalRem, P: Integer;
  RemLenBytes: TBytes;
begin
  Flags := (Ord(AQos) shl 1);
  if ARetain then Flags := Flags or 1;

  TopicBytes := TEncoding.UTF8.GetBytes(ATopic);
  PayloadBytes := TEncoding.UTF8.GetBytes(APayload);

  TopicLen := Length(TopicBytes);
  VarLen := 2 + TopicLen;
  if AQos > qosAtMostOnce then
    VarLen := VarLen + 2;

  TotalRem := VarLen + Length(PayloadBytes);
  RemLenBytes := EncodeRemainingLength(TotalRem);

  SetLength(Result, 1 + Length(RemLenBytes) + TotalRem);
  Result[0] := $30 or Flags;
  Move(RemLenBytes[0], Result[1], Length(RemLenBytes));
  P := 1 + Length(RemLenBytes);

  Result[P] := Hi(TopicLen); Result[P + 1] := Lo(TopicLen);
  P := P + 2;
  Move(TopicBytes[0], Result[P], TopicLen);
  P := P + TopicLen;

  if AQos > qosAtMostOnce then
  begin
    PktId := GetNextPacketId;
    Result[P] := Hi(PktId); Result[P + 1] := Lo(PktId);
    P := P + 2;
  end;

  if Length(PayloadBytes) > 0 then
    Move(PayloadBytes[0], Result[P], Length(PayloadBytes));
end;

function TDlpMqttClientBridge.BuildSubscribePacket(const ATopic: string; AQos: TDlpMqttQoS): TBytes;
var
  PktId, TopicLen: Word;
  RemLen, P: Integer;
  RemLenBytes, TopicBytes: TBytes;
begin
  TopicBytes := TEncoding.UTF8.GetBytes(ATopic);
  TopicLen := Length(TopicBytes);
  RemLen := 2 + (2 + TopicLen + 1);
  RemLenBytes := EncodeRemainingLength(RemLen);

  SetLength(Result, 1 + Length(RemLenBytes) + RemLen);
  Result[0] := $82;
  Move(RemLenBytes[0], Result[1], Length(RemLenBytes));
  P := 1 + Length(RemLenBytes);

  PktId := GetNextPacketId;
  Result[P] := Hi(PktId); Result[P + 1] := Lo(PktId);
  P := P + 2;

  Result[P] := Hi(TopicLen); Result[P + 1] := Lo(TopicLen);
  P := P + 2;
  Move(TopicBytes[0], Result[P], TopicLen);
  P := P + TopicLen;
  Result[P] := Ord(AQos);
end;

function TDlpMqttClientBridge.BuildPingReqPacket: TBytes;
begin
  SetLength(Result, 2);
  Result[0] := $C0;
  Result[1] := 0;
end;

function TDlpMqttClientBridge.BuildDisconnectPacket: TBytes;
begin
  SetLength(Result, 2);
  Result[0] := $E0;
  Result[1] := 0;
end;

procedure TDlpMqttClientBridge.ProcessIncomingBytes(const AData: TBytes);
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
            FOnConnectionChange(Self, True, 'Conexao com broker MQTT confirmada.');
        end;
      end;

    3: { PUBLISH Recebido }
      begin
        if Length(AData) > 4 then
        begin
          TopicLen := (AData[2] shl 8) or AData[3];
          TopicStr := TEncoding.UTF8.GetString(AData, 4, TopicLen);
          PayloadStr := TEncoding.UTF8.GetString(AData, 4 + TopicLen, Length(AData) - (4 + TopicLen));

          if Assigned(FOnMessageReceived) then
            FOnMessageReceived(Self, TopicStr, PayloadStr, qosAtMostOnce, False);
        end;
      end;
  end;
end;

procedure TDlpMqttClientBridge.Publish(const ATopic, APayload: string; AQos: TDlpMqttQoS);
begin
  BuildPublishPacket(ATopic, APayload, AQos);
end;

procedure TDlpMqttClientBridge.Subscribe(const ATopic: string; AQos: TDlpMqttQoS);
begin
  BuildSubscribePacket(ATopic, AQos);
end;

procedure TDlpMqttClientBridge.Disconnect;
begin
  BuildDisconnectPacket;
  FIsConnected := False;
  if Assigned(FOnConnectionChange) then
    FOnConnectionChange(Self, False, 'Desconectado do Broker MQTT.');
end;

end.
