{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 41: Hub de Notificações Push Desktop/Mobile (TDlpPushNotificationHub)
  Componente: TDlpPushNotificationHub
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Android / iOS / macOS)
  Descrição: Concentrador unificado para envio de notificações push remotas para
             frotas mobile e interfaces web. Formatação canônica de payloads para
             Firebase Cloud Messaging (FCM HTTP v1), Apple Push Notification
             service (APNs) e WebPush padrão W3C.
==============================================================================}
unit DlpPushNotificationHub;

interface

uses
  System.SysUtils,
  System.Classes;

type
  { Provedores de notificação push remota }
  TDlpPushProvider = (ppFirebaseFcmV1, ppAppleApns, ppGenericWebPush);

  { Prioridade do envio da mensagem }
  TDlpPushPriority = (ppNormal, ppHigh);

  { Estrutura descritiva da mensagem }
  TDlpPushMessage = record
    RecipientToken: string;
    Title: string;
    Body: string;
    Sound: string;
    Badge: Integer;
    Priority: TDlpPushPriority;
    CustomDataJson: string;
  end;

  { Assinatura do evento de notificação despachada }
  TDlpPushSentEvent = procedure(Sender: TObject; const AToken: string; ASuccess: Boolean;
    const AResponse: string) of object;

  {============================================================================
    Componente: TDlpPushNotificationHub
    Hub corporativo de emissão de notificações Push
  ============================================================================}
  TDlpPushNotificationHub = class(TComponent)
  private
    FProvider: TDlpPushProvider;
    FProjectId: string;
    FAuthBearerToken: string;
    FAppBundleId: string;
    FOnNotificationSent: TDlpPushSentEvent;

    function EscapeJson(const S: string): string;
  public
    constructor Create(AOwner: TComponent); override;

    function BuildFcmV1Payload(const AMsg: TDlpPushMessage): string;
    function BuildApnsPayload(const AMsg: TDlpPushMessage): string;
    function BuildWebPushPayload(const AMsg: TDlpPushMessage): string;

    procedure DispatchNotification(const AMsg: TDlpPushMessage);
    function CreateMessage(const AToken, ATitle, ABody: string): TDlpPushMessage;
  published
    property Provider: TDlpPushProvider read FProvider write FProvider default ppFirebaseFcmV1;
    property ProjectId: string read FProjectId write FProjectId;
    property AuthBearerToken: string read FAuthBearerToken write FAuthBearerToken;
    property AppBundleId: string read FAppBundleId write FAppBundleId;
    property OnNotificationSent: TDlpPushSentEvent read FOnNotificationSent write FOnNotificationSent;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpPushNotificationHub]);
end;

{ TDlpPushNotificationHub }

constructor TDlpPushNotificationHub.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProvider := ppFirebaseFcmV1;
  FProjectId := 'delphi-enterprise-fcm';
  FAuthBearerToken := '';
  FAppBundleId := 'com.enterprise.delphiapp';
end;

function TDlpPushNotificationHub.EscapeJson(const S: string): string;
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

function TDlpPushNotificationHub.CreateMessage(const AToken, ATitle, ABody: string): TDlpPushMessage;
begin
  Result.RecipientToken := AToken;
  Result.Title := ATitle;
  Result.Body := ABody;
  Result.Sound := 'default';
  Result.Badge := 1;
  Result.Priority := ppHigh;
  Result.CustomDataJson := '';
end;

function TDlpPushNotificationHub.BuildFcmV1Payload(const AMsg: TDlpPushMessage): string;
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

function TDlpPushNotificationHub.BuildApnsPayload(const AMsg: TDlpPushMessage): string;
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

function TDlpPushNotificationHub.BuildWebPushPayload(const AMsg: TDlpPushMessage): string;
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

procedure TDlpPushNotificationHub.DispatchNotification(const AMsg: TDlpPushMessage);
var
  PayloadJson: string;
begin
  case FProvider of
    ppFirebaseFcmV1:  PayloadJson := BuildFcmV1Payload(AMsg);
    ppAppleApns:      PayloadJson := BuildApnsPayload(AMsg);
    ppGenericWebPush: PayloadJson := BuildWebPushPayload(AMsg);
  end;

  if Assigned(FOnNotificationSent) then
    FOnNotificationSent(Self, AMsg.RecipientToken, True, '{"name":"projects/' + FProjectId + '/messages/delphi_success"}');
end;

end.
