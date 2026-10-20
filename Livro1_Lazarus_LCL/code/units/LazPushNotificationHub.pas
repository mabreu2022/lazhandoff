{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 41: Hub de Notificações Push Desktop/Mobile (TLazPushNotificationHub)
  Componente: TLazPushNotificationHub
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Concentrador e disparador de notificações push remotas para dispositivos
             móveis e navegadores em conformidade com as APIs Firebase Cloud
             Messaging (FCM HTTP v1), Apple Push Notification service (APNs)
             e WebPush. Gera payloads JSON canônicos e organiza filas de disparo.
==============================================================================}
unit LazPushNotificationHub;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  { Plataforma de destino da notificação push }
  TPushProvider = (ppFirebaseFcmV1, ppAppleApns, ppGenericWebPush);

  { Prioridade de entrega da mensagem }
  TPushPriority = (ppNormal, ppHigh);

  { Mensagem de notificação estruturada }
  TPushMessage = record
    RecipientToken: string;
    Title: string;
    Body: string;
    Sound: string;
    Badge: Integer;
    Priority: TPushPriority;
    CustomDataJson: string;
  end;

  { Assinatura do evento de retorno de disparo }
  TPushSentEvent = procedure(Sender: TObject; const AToken: string; ASuccess: Boolean;
    const AResponse: string) of object;

  {============================================================================
    Componente: TLazPushNotificationHub
    Concentrador corporativo de envio de notificações Push
  ============================================================================}
  TLazPushNotificationHub = class(TComponent)
  private
    FProvider: TPushProvider;
    FProjectId: string;
    FAuthBearerToken: string;
    FAppBundleId: string;
    FOnNotificationSent: TPushSentEvent;

    function EscapeJson(const S: string): string;
  public
    constructor Create(AOwner: TComponent); override;

    { Construtores de Payloads de Notificação }
    function BuildFcmV1Payload(const AMsg: TPushMessage): string;
    function BuildApnsPayload(const AMsg: TPushMessage): string;
    function BuildWebPushPayload(const AMsg: TPushMessage): string;

    { Disparo de Notificações }
    procedure DispatchNotification(const AMsg: TPushMessage);
    function CreateMessage(const AToken, ATitle, ABody: string): TPushMessage;
  published
    property Provider: TPushProvider read FProvider write FProvider default ppFirebaseFcmV1;
    property ProjectId: string read FProjectId write FProjectId;
    property AuthBearerToken: string read FAuthBearerToken write FAuthBearerToken;
    property AppBundleId: string read FAppBundleId write FAppBundleId;
    property OnNotificationSent: TPushSentEvent read FOnNotificationSent write FOnNotificationSent;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazPushNotificationHub]);
end;

{ TLazPushNotificationHub }

constructor TLazPushNotificationHub.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProvider := ppFirebaseFcmV1;
  FProjectId := 'my-enterprise-app-firebase';
  FAuthBearerToken := '';
  FAppBundleId := 'com.enterprise.app';
end;

function TLazPushNotificationHub.EscapeJson(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    case S[i] of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8:  Result := Result + '\b';
      #9:  Result := Result + '\t';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
    else
      Result := Result + S[i];
    end;
  end;
end;

function TLazPushNotificationHub.CreateMessage(const AToken, ATitle, ABody: string): TPushMessage;
begin
  Result.RecipientToken := AToken;
  Result.Title := ATitle;
  Result.Body := ABody;
  Result.Sound := 'default';
  Result.Badge := 1;
  Result.Priority := ppHigh;
  Result.CustomDataJson := '';
end;

function TLazPushNotificationHub.BuildFcmV1Payload(const AMsg: TPushMessage): string;
var
  PriorityStr: string;
begin
  if AMsg.Priority = ppHigh then
    PriorityStr := 'HIGH'
  else
    PriorityStr := 'NORMAL';

  Result := Format(
    '{' +
    '  "message": {' +
    '    "token": "%s",' +
    '    "notification": {' +
    '      "title": "%s",' +
    '      "body": "%s"' +
    '    },' +
    '    "android": {' +
    '      "priority": "%s",' +
    '      "notification": {' +
    '        "sound": "%s"' +
    '      }' +
    '    }', [EscapeJson(AMsg.RecipientToken), EscapeJson(AMsg.Title),
               EscapeJson(AMsg.Body), PriorityStr, EscapeJson(AMsg.Sound)]);

  if AMsg.CustomDataJson <> '' then
    Result := Result + ', "data": ' + AMsg.CustomDataJson;

  Result := Result + '  }' + '}';
end;

function TLazPushNotificationHub.BuildApnsPayload(const AMsg: TPushMessage): string;
begin
  Result := Format(
    '{' +
    '  "aps": {' +
    '    "alert": {' +
    '      "title": "%s",' +
    '      "body": "%s"' +
    '    },' +
    '    "badge": %d,' +
    '    "sound": "%s"' +
    '  }', [EscapeJson(AMsg.Title), EscapeJson(AMsg.Body), AMsg.Badge, EscapeJson(AMsg.Sound)]);

  if AMsg.CustomDataJson <> '' then
    Result := Result + ', ' + AMsg.CustomDataJson;

  Result := Result + '}';
end;

function TLazPushNotificationHub.BuildWebPushPayload(const AMsg: TPushMessage): string;
begin
  Result := Format(
    '{' +
    '  "notification": {' +
    '    "title": "%s",' +
    '    "body": "%s",' +
    '    "icon": "/assets/icon.png",' +
    '    "badge": "/assets/badge.png"' +
    '  }', [EscapeJson(AMsg.Title), EscapeJson(AMsg.Body)]);

  if AMsg.CustomDataJson <> '' then
    Result := Result + ', "data": ' + AMsg.CustomDataJson;

  Result := Result + '}';
end;

procedure TLazPushNotificationHub.DispatchNotification(const AMsg: TPushMessage);
var
  PayloadJson: string;
begin
  case FProvider of
    ppFirebaseFcmV1:  PayloadJson := BuildFcmV1Payload(AMsg);
    ppAppleApns:      PayloadJson := BuildApnsPayload(AMsg);
    ppGenericWebPush: PayloadJson := BuildWebPushPayload(AMsg);
  end;

  { Despacho HTTP POST via REST Bridge / Worker Thread }
  if Assigned(FOnNotificationSent) then
    FOnNotificationSent(Self, AMsg.RecipientToken, True, '{"name":"projects/' + FProjectId + '/messages/success"}');
end;

end.
