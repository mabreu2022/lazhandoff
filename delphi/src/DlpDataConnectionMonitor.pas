{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 16: Monitoramento e Gerenciador de Transações de Dados
  Componente: TDlpDataConnectionMonitor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / FireDAC
  Descrição: Componente não-visual corporativo para auditoria de conexões FireDAC,
             captura de queries lentas (Slow Query Alert) e governança de
             transações zumbis (Zombie Transaction Watchdog).
==============================================================================}
unit DlpDataConnectionMonitor;

interface

uses
  System.Classes,
  System.SysUtils,
  System.DateUtils,
  System.Diagnostics,
  FireDAC.Comp.Client,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option;

type
  /// <summary>
  /// Assinatura do evento disparado ao detectar execução de SQL acima do limiar.
  /// </summary>
  TOnDlpSlowQueryEvent = procedure(Sender: TObject; const ASQL: string;
    DurationMS: Int64) of object;

  /// <summary>
  /// Assinatura do evento de detecção de transação com duração excessiva.
  /// </summary>
  TOnDlpZombieTxEvent = procedure(Sender: TObject; AConnection: TFDConnection;
    DurationSec: Int64; var AutoRollback: Boolean) of object;

  /// <summary>
  /// Assinatura de evento de registro de mensagens e auditoria.
  /// </summary>
  TOnDlpLogMessageEvent = procedure(Sender: TObject; const AMessage: string) of object;

  /// <summary>
  /// Componente não-visual para auditoria, diagnóstico de performance e
  /// segurança de transações em conexões FireDAC.
  /// </summary>
  TDlpDataConnectionMonitor = class(TComponent)
  private
    FConnection: TFDConnection;
    FSlowQueryThresholdMS: Int64;
    FMaxTransactionDurationSec: Int64;
    FAutoRollbackZombies: Boolean;
    FLogFileName: string;
    FActive: Boolean;
    FTxStartTime: TDateTime;

    FOnSlowQueryDetected: TOnDlpSlowQueryEvent;
    FOnZombieTransactionDetected: TOnDlpZombieTxEvent;
    FOnLogMessage: TOnDlpLogMessageEvent;

    procedure SetConnection(const AValue: TFDConnection);
    procedure SetActive(const AValue: Boolean);
    procedure WriteLogEntry(const AEntry: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Rastreia e calcula o tempo de execução de uma instrução SQL.
    /// </summary>
    procedure RegisterQueryExecution(const ASQL: string; DurationMS: Int64);

    /// <summary>
    /// Inspeciona a transação ativa da conexão informada e atua sobre transações órfãs.
    /// </summary>
    procedure CheckZombieTransactions;

    /// <summary>
    /// Sinaliza manualmente o início de uma transação para cálculo de tempo de vida.
    /// </summary>
    procedure MarkTransactionStart;

    /// <summary>
    /// Sinaliza a conclusão (commit ou rollback) da transação.
    /// </summary>
    procedure MarkTransactionEnd;

    /// <summary>
    /// Retorna True se a transação do FireDAC estiver ativa.
    /// </summary>
    function IsTransactionActive: Boolean;

    /// <summary>
    /// Retorna a duração em segundos da transação corrente.
    /// </summary>
    function GetTransactionAgeSeconds: Int64;
  published
    property Connection: TFDConnection read FConnection write SetConnection;
    property SlowQueryThresholdMS: Int64 read FSlowQueryThresholdMS
      write FSlowQueryThresholdMS default 1000;
    property MaxTransactionDurationSec: Int64 read FMaxTransactionDurationSec
      write FMaxTransactionDurationSec default 60;
    property AutoRollbackZombies: Boolean read FAutoRollbackZombies
      write FAutoRollbackZombies default False;
    property LogFileName: string read FLogFileName write FLogFileName;
    property Active: Boolean read FActive write SetActive default False;

    property OnSlowQueryDetected: TOnDlpSlowQueryEvent
      read FOnSlowQueryDetected write FOnSlowQueryDetected;
    property OnZombieTransactionDetected: TOnDlpZombieTxEvent
      read FOnZombieTransactionDetected write FOnZombieTransactionDetected;
    property OnLogMessage: TOnDlpLogMessageEvent
      read FOnLogMessage write FOnLogMessage;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Component Engineering', [TDlpDataConnectionMonitor]);
end;

{ TDlpDataConnectionMonitor }

constructor TDlpDataConnectionMonitor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSlowQueryThresholdMS := 1000;
  FMaxTransactionDurationSec := 60;
  FAutoRollbackZombies := False;
  FLogFileName := '';
  FActive := False;
  FTxStartTime := 0;
end;

destructor TDlpDataConnectionMonitor.Destroy;
begin
  FActive := False;
  inherited Destroy;
end;

procedure TDlpDataConnectionMonitor.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FConnection) then
    FConnection := nil;
end;

procedure TDlpDataConnectionMonitor.SetConnection(const AValue: TFDConnection);
begin
  if FConnection <> AValue then
  begin
    FConnection := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
  end;
end;

procedure TDlpDataConnectionMonitor.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    if FActive then
      WriteLogEntry('MONITOR: Monitoramento ativado para conexão FireDAC')
    else
      WriteLogEntry('MONITOR: Monitoramento desativado');
  end;
end;

procedure TDlpDataConnectionMonitor.WriteLogEntry(const AEntry: string);
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
      { Impede propagação de exceção caso haja travamento de arquivo no SO }
    end;
  end;
end;

procedure TDlpDataConnectionMonitor.MarkTransactionStart;
begin
  FTxStartTime := Now;
  WriteLogEntry('FIREDAC_TX_START: Início de transação registrado.');
end;

procedure TDlpDataConnectionMonitor.MarkTransactionEnd;
begin
  FTxStartTime := 0;
  WriteLogEntry('FIREDAC_TX_END: Conclusão de transação registrada.');
end;

function TDlpDataConnectionMonitor.IsTransactionActive: Boolean;
begin
  Result := (FConnection <> nil) and FConnection.Connected and FConnection.InTransaction;
end;

function TDlpDataConnectionMonitor.GetTransactionAgeSeconds: Int64;
begin
  Result := 0;
  if IsTransactionActive and (FTxStartTime > 0) then
    Result := SecondsBetween(Now, FTxStartTime);
end;

procedure TDlpDataConnectionMonitor.RegisterQueryExecution(const ASQL: string;
  DurationMS: Int64);
begin
  if not FActive then
    Exit;

  if DurationMS >= FSlowQueryThresholdMS then
  begin
    WriteLogEntry(Format('FIREDAC_SLOW_QUERY [%d ms]: %s', [DurationMS, ASQL]));
    if Assigned(FOnSlowQueryDetected) then
      FOnSlowQueryDetected(Self, ASQL, DurationMS);
  end
  else
    WriteLogEntry(Format('FIREDAC_QUERY_EXEC [%d ms]: %s', [DurationMS, ASQL]));
end;

procedure TDlpDataConnectionMonitor.CheckZombieTransactions;
var
  AgeSec: Int64;
  ShouldRollback: Boolean;
begin
  if not FActive or not IsTransactionActive then
    Exit;

  AgeSec := GetTransactionAgeSeconds;
  if (AgeSec >= FMaxTransactionDurationSec) and (AgeSec > 0) then
  begin
    ShouldRollback := FAutoRollbackZombies;
    WriteLogEntry(Format('FIREDAC_ZOMBIE_TX_ALERT: Transação ativa por %d segundos.', [AgeSec]));

    if Assigned(FOnZombieTransactionDetected) then
      FOnZombieTransactionDetected(Self, FConnection, AgeSec, ShouldRollback);

    if ShouldRollback and FConnection.InTransaction then
    begin
      try
        FConnection.Rollback;
        FTxStartTime := 0;
        WriteLogEntry('FIREDAC_ZOMBIE_TX_ACTION: Rollback efetuado com sucesso.');
      except
        on E: Exception do
          WriteLogEntry('FIREDAC_ZOMBIE_TX_ERROR: Falha ao executar rollback: ' + E.Message);
      end;
    end;
  end;
end;

end.
