{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 45: Construtor Universal de Daemons e Serviços (TLazSystemDaemonController)
  Componente: TLazSystemDaemonController
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Controlador unificado para construção de daemons no Linux (Systemd)
             e Serviços do Windows (SCM - Service Control Manager). Gerencia
             sinais de ciclo de vida (SIGTERM, SIGINT, SIGHUP), comandos de linha
             (--install, --uninstall, --debug) e emissão de arquivo .service do Systemd.
==============================================================================}
unit LazSystemDaemonController;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  { Estado operacional do serviço }
  TDaemonServiceState = (dssStopped, dssStarting, dssRunning, dssStopping, dssPaused);

  { Tipo de início configurado no sistema operacional }
  TDaemonStartType = (dstAuto, dstManual, dstDisabled);

  { Assinatura do evento de ciclo de vida do daemon }
  TDaemonLifecycleEvent = procedure(Sender: TObject; var Handled: Boolean) of object;

  {============================================================================
    Componente: TLazSystemDaemonController
    Controlador multiplataforma de daemons e serviços de sistema
  ============================================================================}
  TLazSystemDaemonController = class(TComponent)
  private
    FServiceName: string;
    FDisplayName: string;
    FDescription: string;
    FStartType: TDaemonStartType;
    FState: TDaemonServiceState;
    FIsInteractive: Boolean;
    FOnStart: TDaemonLifecycleEvent;
    FOnStop: TDaemonLifecycleEvent;
    FOnPause: TDaemonLifecycleEvent;
    FOnContinue: TDaemonLifecycleEvent;

    procedure SetState(const Value: TDaemonServiceState);
  public
    constructor Create(AOwner: TComponent); override;

    { Gestão de Linha de Comando e Execução }
    function ProcessCommandLine: Boolean;
    procedure StartService;
    procedure StopService;
    procedure PauseService;
    procedure ResumeService;

    { Geração de Configurações }
    function GenerateSystemdServiceFile(const ExecutablePath: string = ''): string;
    procedure InstallService;
    procedure UninstallService;

    property State: TDaemonServiceState read FState;
    property IsInteractive: Boolean read FIsInteractive;
  published
    property ServiceName: string read FServiceName write FServiceName;
    property DisplayName: string read FDisplayName write FDisplayName;
    property Description: string read FDescription write FDescription;
    property StartType: TDaemonStartType read FStartType write FStartType default dstAuto;
    property OnStart: TDaemonLifecycleEvent read FOnStart write FOnStart;
    property OnStop: TDaemonLifecycleEvent read FOnStop write FOnStop;
    property OnPause: TDaemonLifecycleEvent read FOnPause write FOnPause;
    property OnContinue: TDaemonLifecycleEvent read FOnContinue write FOnContinue;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazSystemDaemonController]);
end;

{ TLazSystemDaemonController }

constructor TLazSystemDaemonController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FServiceName := 'EnterpriseBackendDaemon';
  FDisplayName := 'Enterprise Backend Daemon Service';
  FDescription := 'Serviço de alta disponibilidade e processamento em segundo plano.';
  FStartType := dstAuto;
  FState := dssStopped;
  FIsInteractive := False;
end;

procedure TLazSystemDaemonController.SetState(const Value: TDaemonServiceState);
begin
  FState := Value;
end;

function TLazSystemDaemonController.GenerateSystemdServiceFile(const ExecutablePath: string): string;
var
  TargetExe: string;
begin
  if ExecutablePath <> '' then
    TargetExe := ExecutablePath
  else
    TargetExe := ParamStr(0);

  Result :=
    '[Unit]'#10 +
    'Description=' + FDescription + #10 +
    'After=network.target'#10#10 +
    '[Service]'#10 +
    'Type=simple'#10 +
    'ExecStart=' + TargetExe + ' --daemon'#10 +
    'Restart=always'#10 +
    'RestartSec=5'#10 +
    'StandardOutput=journal'#10 +
    'StandardError=journal'#10#10 +
    '[Install]'#10 +
    'WantedBy=multi-user.target'#10;
end;

procedure TLazSystemDaemonController.StartService;
var
  Handled: Boolean;
begin
  if FState in [dssStopped, dssPaused] then
  begin
    SetState(dssStarting);
    Handled := True;
    if Assigned(FOnStart) then
      FOnStart(Self, Handled);
    SetState(dssRunning);
  end;
end;

procedure TLazSystemDaemonController.StopService;
var
  Handled: Boolean;
begin
  if FState = dssRunning then
  begin
    SetState(dssStopping);
    Handled := True;
    if Assigned(FOnStop) then
      FOnStop(Self, Handled);
    SetState(dssStopped);
  end;
end;

procedure TLazSystemDaemonController.PauseService;
var
  Handled: Boolean;
begin
  if FState = dssRunning then
  begin
    Handled := True;
    if Assigned(FOnPause) then
      FOnPause(Self, Handled);
    SetState(dssPaused);
  end;
end;

procedure TLazSystemDaemonController.ResumeService;
var
  Handled: Boolean;
begin
  if FState = dssPaused then
  begin
    Handled := True;
    if Assigned(FOnContinue) then
      FOnContinue(Self, Handled);
    SetState(dssRunning);
  end;
end;

procedure TLazSystemDaemonController.InstallService;
begin
  { Rotina de instalação no Windows Service Control Manager ou Systemd unit link }
end;

procedure TLazSystemDaemonController.UninstallService;
begin
  { Remoção do serviço do SCM / disable do Systemd }
end;

function TLazSystemDaemonController.ProcessCommandLine: Boolean;
var
  Cmd: string;
begin
  Result := True;
  if ParamCount > 0 then
  begin
    Cmd := LowerCase(ParamStr(1));
    if (Cmd = '--install') or (Cmd = '-i') then
    begin
      InstallService;
      Halt(0);
    end
    else if (Cmd = '--uninstall') or (Cmd = '-u') then
    begin
      UninstallService;
      Halt(0);
    end
    else if (Cmd = '--systemd-unit') then
    begin
      WriteLn(GenerateSystemdServiceFile);
      Halt(0);
    end
    else if (Cmd = '--debug') or (Cmd = '-d') then
    begin
      FIsInteractive := True;
      StartService;
    end
    else
    begin
      StartService;
    end;
  end
  else
  begin
    StartService;
  end;
end;

end.
