{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 16: Monitoramento e Gerenciador de Transações de Dados
  Componente: TLazDataConnectionMonitor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+ / SQLDB
  Descrição: Monitor não-visual para auditoria de transações, detecção de
             consultas SQL lentas (Slow Query Alert) e contenção de transações
             órfãs (zombie transactions) no framework SQLDB.
==============================================================================}
unit LazDataConnectionMonitor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  DateUtils,
  sqldb,
  db;

type
  { Evento para notificação de consultas SQL com tempo excessivo }
  TSlowQueryEvent = procedure(Sender: TObject; const ASQL: string;
    DurationMS: Int64) of object;

  { Evento para detecção de transações de longa duração }
  TZombieTransactionEvent = procedure(Sender: TObject; ATransaction: TSQLTransaction;
    DurationSec: Int64; var CanRollback: Boolean) of object;

  { Evento genérico para registro de logs de auditoria }
  TLogMessageEvent = procedure(Sender: TObject; const AMessage: string) of object;

  {============================================================================
    Classe: TLazDataConnectionMonitor
    Componente não-visual de auditoria e segurança transacional SQLDB
  ============================================================================}
  TLazDataConnectionMonitor = class(TComponent)
  private
    FConnection: TSQLConnection;
    FTransaction: TSQLTransaction;
    FSlowQueryThresholdMS: Int64;
    FMaxTransactionDurationSec: Int64;
    FAutoRollbackZombies: Boolean;
    FLogFileName: string;
    FActive: Boolean;
    FTransactionStartTime: TDateTime;
    FOriginalLogEvent: TDBLogEvent;

    FOnSlowQueryDetected: TSlowQueryEvent;
    FOnZombieTransactionDetected: TZombieTransactionEvent;
    FOnLogMessage: TLogMessageEvent;

    procedure SetConnection(const AValue: TSQLConnection);
    procedure SetTransaction(const AValue: TSQLTransaction);
    procedure SetActive(const AValue: Boolean);
    procedure HookConnectionEvents;
    procedure UnhookConnectionEvents;
    procedure InternalConnectionLog(Sender: TSQLConnection; EventType: TDBEventType;
      const Msg: string);
    procedure WriteLogEntry(const AEntry: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos públicos de auditoria e inspeção }
    procedure CheckZombieTransactions;
    procedure RegisterManualQueryTime(const ASQL: string; DurationMS: Int64);
    function IsTransactionAlive: Boolean;
    function GetTransactionAgeSeconds: Int64;
  published
    property Connection: TSQLConnection read FConnection write SetConnection;
    property Transaction: TSQLTransaction read FTransaction write SetTransaction;
    property SlowQueryThresholdMS: Int64 read FSlowQueryThresholdMS
      write FSlowQueryThresholdMS default 1000;
    property MaxTransactionDurationSec: Int64 read FMaxTransactionDurationSec
      write FMaxTransactionDurationSec default 60;
    property AutoRollbackZombies: Boolean read FAutoRollbackZombies
      write FAutoRollbackZombies default False;
    property LogFileName: string read FLogFileName write FLogFileName;
    property Active: Boolean read FActive write SetActive default False;

    property OnSlowQueryDetected: TSlowQueryEvent
      read FOnSlowQueryDetected write FOnSlowQueryDetected;
    property OnZombieTransactionDetected: TZombieTransactionEvent
      read FOnZombieTransactionDetected write FOnZombieTransactionDetected;
    property OnLogMessage: TLogMessageEvent
      read FOnLogMessage write FOnLogMessage;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazDataConnectionMonitor]);
end;

{ TLazDataConnectionMonitor }

constructor TLazDataConnectionMonitor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSlowQueryThresholdMS := 1000;       // 1 segundo como limiar padrão
  FMaxTransactionDurationSec := 60;    // 60 segundos para alerta de transação zumbi
  FAutoRollbackZombies := False;
  FLogFileName := '';
  FActive := False;
  FTransactionStartTime := 0;
  FOriginalLogEvent := nil;
end;

destructor TLazDataConnectionMonitor.Destroy;
begin
  if FActive then
    SetActive(False);
  inherited Destroy;
end;

procedure TLazDataConnectionMonitor.Loaded;
begin
  inherited Loaded;
  if FActive and not (csDesigning in ComponentState) then
    HookConnectionEvents;
end;

procedure TLazDataConnectionMonitor.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FConnection then
    begin
      UnhookConnectionEvents;
      FConnection := nil;
    end;
    if AComponent = FTransaction then
      FTransaction := nil;
  end;
end;

procedure TLazDataConnectionMonitor.SetConnection(const AValue: TSQLConnection);
begin
  if FConnection <> AValue then
  begin
    if FActive then
      UnhookConnectionEvents;

    FConnection := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);

    if FActive and not (csDesigning in ComponentState) then
      HookConnectionEvents;
  end;
end;

procedure TLazDataConnectionMonitor.SetTransaction(const AValue: TSQLTransaction);
begin
  if FTransaction <> AValue then
  begin
    FTransaction := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
  end;
end;

procedure TLazDataConnectionMonitor.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    if not (csDesigning in ComponentState) and not (csLoading in ComponentState) then
    begin
      if FActive then
        HookConnectionEvents
      else
        UnhookConnectionEvents;
    end;
  end;
end;

procedure TLazDataConnectionMonitor.HookConnectionEvents;
begin
  if (FConnection <> nil) and not (csDesigning in ComponentState) then
  begin
    FOriginalLogEvent := FConnection.OnLog;
    FConnection.OnLog := @InternalConnectionLog;
    FConnection.LogEvents := [detCustom, detPrepare, detExecute, detCommit, detRollBack];
    WriteLogEntry('MONITOR: Auditoria ativada com sucesso para conexão ' + FConnection.Name);
  end;
end;

procedure TLazDataConnectionMonitor.UnhookConnectionEvents;
begin
  if (FConnection <> nil) then
  begin
    FConnection.OnLog := FOriginalLogEvent;
    FOriginalLogEvent := nil;
    WriteLogEntry('MONITOR: Auditoria desativada para conexão ' + FConnection.Name);
  end;
end;

procedure TLazDataConnectionMonitor.WriteLogEntry(const AEntry: string);
var
  TimestampedMsg: string;
  LogFile: TextFile;
begin
  TimestampedMsg := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' | ' + AEntry;

  if Assigned(FOnLogMessage) then
    FOnLogMessage(Self, TimestampedMsg);

  if (FLogFileName <> '') then
  begin
    try
      AssignFile(LogFile, FLogFileName);
      if FileExists(FLogFileName) then
        Append(LogFile)
      else
        Rewrite(LogFile);
      try
        WriteLn(LogFile, TimestampedMsg);
      finally
        CloseFile(LogFile);
      end;
    except
      { Previne interrupção da aplicação em falhas de escrita de disco }
    end;
  end;
end;

procedure TLazDataConnectionMonitor.InternalConnectionLog(
  Sender: TSQLConnection; EventType: TDBEventType; const Msg: string);
begin
  // Preserva o tratador de log original caso configurado
  if Assigned(FOriginalLogEvent) then
    FOriginalLogEvent(Sender, EventType, Msg);

  // Rastreia início e fim de transações
  case EventType of
    detExecute:
    begin
      if (FTransactionStartTime = 0) and (FTransaction <> nil) and FTransaction.Active then
        FTransactionStartTime := Now;
      WriteLogEntry('SQL_EXEC: ' + Msg);
    end;
    detCommit:
    begin
      FTransactionStartTime := 0;
      WriteLogEntry('SQL_COMMIT: ' + Msg);
    end;
    detRollBack:
    begin
      FTransactionStartTime := 0;
      WriteLogEntry('SQL_ROLLBACK: ' + Msg);
    end;
    else
      WriteLogEntry('SQL_EVENT: ' + Msg);
  end;
end;

procedure TLazDataConnectionMonitor.RegisterManualQueryTime(
  const ASQL: string; DurationMS: Int64);
begin
  if not FActive then
    Exit;

  if DurationMS >= FSlowQueryThresholdMS then
  begin
    WriteLogEntry(Format('SLOW_QUERY_ALERT [%d ms]: %s', [DurationMS, ASQL]));
    if Assigned(FOnSlowQueryDetected) then
      FOnSlowQueryDetected(Self, ASQL, DurationMS);
  end;
end;

function TLazDataConnectionMonitor.IsTransactionAlive: Boolean;
begin
  Result := (FTransaction <> nil) and FTransaction.Active;
end;

function TLazDataConnectionMonitor.GetTransactionAgeSeconds: Int64;
begin
  Result := 0;
  if IsTransactionAlive and (FTransactionStartTime > 0) then
    Result := SecondsBetween(Now, FTransactionStartTime);
end;

procedure TLazDataConnectionMonitor.CheckZombieTransactions;
var
  AgeSec: Int64;
  ShouldRollback: Boolean;
begin
  if not FActive or (FTransaction = nil) or not FTransaction.Active then
    Exit;

  AgeSec := GetTransactionAgeSeconds;
  if (AgeSec >= FMaxTransactionDurationSec) and (AgeSec > 0) then
  begin
    ShouldRollback := FAutoRollbackZombies;
    WriteLogEntry(Format('ZOMBIE_TX_ALERT: Transação ativa por %d segundos.', [AgeSec]));

    if Assigned(FOnZombieTransactionDetected) then
      FOnZombieTransactionDetected(Self, FTransaction, AgeSec, ShouldRollback);

    if ShouldRollback and FTransaction.Active then
    begin
      try
        FTransaction.Rollback;
        FTransactionStartTime := 0;
        WriteLogEntry('ZOMBIE_TX_ACTION: Rollback automático efetuado com sucesso.');
      except
        on E: Exception do
          WriteLogEntry('ZOMBIE_TX_ERROR: Falha ao executar rollback: ' + E.Message);
      end;
    end;
  end;
end;

end.
