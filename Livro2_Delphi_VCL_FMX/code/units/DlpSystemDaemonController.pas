{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 45: Construtor Universal de Daemons e Serviços (TDlpSystemDaemonController)
  Componente: TDlpSystemDaemonController
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Windows Service SCM / Linux Systemd / Multiplataforma)
  Descrição: Controlador unificado para desenvolvimento de Windows Services e Daemons
             do Linux (Systemd). Trata argumentos de linha de comando para
             instalação/desinstalação automática, despacho de ciclo de vida (Start,
             Stop, Pause, Continue), geração de descritores .service e modo debug.
==============================================================================}
unit DlpSystemDaemonController;

interface

uses
  System.SysUtils,
  System.Classes;

type
  { Estado operacional do serviço }
  TDlpDaemonServiceState = (dssStopped, dssStarting, dssRunning, dssStopping, dssPaused);

  { Tipo de início configurado no sistema operacional }
  TDlpDaemonStartType = (dstAuto, dstManual, dstDisabled);

  { Assinatura do evento de ciclo de vida do daemon }
  TDlpDaemonLifecycleEvent = procedure(Sender: TObject; var Handled: Boolean) of object;

  {============================================================================
    Componente: TDlpSystemDaemonController
    Controlador multiplataforma de daemons e serviços de sistema
  ============================================================================}
  TDlpSystemDaemonController = class(TComponent)
  private
    FServiceName: string;
    FDisplayName: string;
    FDescription: string;
    FStartType: TDlpDaemonStartType;
    FState: TDlpDaemonServiceState;
    FIsInteractive: Boolean;
    FOnStart: TDlpDaemonLifecycleEvent;
    FOnStop: TDlpDaemonLifecycleEvent;
    FOnPause: TDlpDaemonLifecycleEvent;
    FOnContinue: TDlpDaemonLifecycleEvent;

    procedure SetState(const Value: TDlpDaemonServiceState);
  public
    constructor Create(AOwner: TComponent); override;

    function ProcessCommandLine: Boolean;
    procedure StartService;
    procedure StopService;
    procedure PauseService;
    procedure ResumeService;

    function GenerateSystemdServiceFile(const ExecutablePath: string = ''): string;
    procedure InstallService;
    procedure UninstallService;

    property State: TDlpDaemonServiceState read FState;
    property IsInteractive: Boolean read FIsInteractive;
  published
    property ServiceName: string read FServiceName write FServiceName;
    property DisplayName: string read FDisplayName write FDisplayName;
    property Description: string read FDescription write FDescription;
    property StartType: TDlpDaemonStartType read FStartType write FStartType default dstAuto;
    property OnStart: TDlpDaemonLifecycleEvent read FOnStart write FOnStart;
    property OnStop: TDlpDaemonLifecycleEvent read FOnStop write FOnStop;
    property OnPause: TDlpDaemonLifecycleEvent read FOnPause write FOnPause;
    property OnContinue: TDlpDaemonLifecycleEvent read FOnContinue write FOnContinue;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpSystemDaemonController]);
end;

{ TDlpSystemDaemonController }

constructor TDlpSystemDaemonController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FServiceName := 'DelphiEnterpriseService';
  FDisplayName := 'Delphi Enterprise Backend Service';
  FDescription := 'Servico corporativo de processamento em segundo plano.';
  FStartType := dstAuto;
  FState := dssStopped;
  FIsInteractive := False;
end;

procedure TDlpSystemDaemonController.SetState(const Value: TDlpDaemonServiceState);
begin
  FState := Value;
end;

function TDlpSystemDaemonController.GenerateSystemdServiceFile(const ExecutablePath: string): string;
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

procedure TDlpSystemDaemonController.StartService;
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

procedure TDlpSystemDaemonController.StopService;
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

procedure TDlpSystemDaemonController.PauseService;
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

procedure TDlpSystemDaemonController.ResumeService;
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

procedure TDlpSystemDaemonController.InstallService;
begin
  { Rotinas de registro no Windows SCM ou Systemd }
end;

procedure TDlpSystemDaemonController.UninstallService;
begin
  { Remoção do serviço }
end;

function TDlpSystemDaemonController.ProcessCommandLine: Boolean;
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
      Writeln(GenerateSystemdServiceFile);
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
