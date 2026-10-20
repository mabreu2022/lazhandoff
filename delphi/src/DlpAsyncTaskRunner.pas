{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 21: Componentes de Execução Assíncrona e Worker Threads
  Componente: TDlpAsyncTaskRunner
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL & FMX
  Descrição: Gerenciador de tarefas paralelas e assíncronas baseado na PPL
             (Parallel Programming Library / System.Threading.ITask) com
             cancelamento cooperativo e despacho seguro via TThread.Queue.
==============================================================================}
unit DlpAsyncTaskRunner;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Threading;

type
  /// <summary>
  /// Procedimento executado no contexto da thread de trabalho da PPL.
  /// </summary>
  TOnDlpTaskExecute = procedure(Sender: TObject; var Cancelled: Boolean) of object;

  /// <summary>
  /// Procedimento de progresso despachado de forma assíncrona para a UI thread.
  /// </summary>
  TOnDlpTaskProgress = procedure(Sender: TObject; Current, Total: Integer;
    const StatusMsg: string) of object;

  /// <summary>
  /// Procedimento acionado no encerramento da tarefa no contexto da UI thread.
  /// </summary>
  TOnDlpTaskComplete = procedure(Sender: TObject; Success: Boolean;
    const ErrorMsg: string) of object;

  /// <summary>
  /// Componente não-visual de concorrência e tarefas em segundo plano.
  /// </summary>
  TDlpAsyncTaskRunner = class(TComponent)
  private
    FTask: ITask;
    FCancelled: Boolean;
    FIsRunning: Boolean;
    FOnExecuteTask: TOnDlpTaskExecute;
    FOnProgress: TOnDlpTaskProgress;
    FOnComplete: TOnDlpTaskComplete;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Dispara a execução assíncrona da tarefa através da PPL.
    /// </summary>
    procedure RunAsync;

    /// <summary>
    /// Sinaliza o cancelamento cooperativo da execução.
    /// </summary>
    procedure Cancel;

    /// <summary>
    /// Notifica o progresso para a UI thread de forma não-bloqueante.
    /// </summary>
    procedure NotifyProgress(ACurrent, ATotal: Integer; const AStatusMsg: string);

    property IsRunning: Boolean read FIsRunning;
  published
    property OnExecuteTask: TOnDlpTaskExecute read FOnExecuteTask write FOnExecuteTask;
    property OnProgress: TOnDlpTaskProgress read FOnProgress write FOnProgress;
    property OnComplete: TOnDlpTaskComplete read FOnComplete write FOnComplete;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Component Engineering', [TDlpAsyncTaskRunner]);
end;

{ TDlpAsyncTaskRunner }

constructor TDlpAsyncTaskRunner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTask := nil;
  FCancelled := False;
  FIsRunning := False;
end;

destructor TDlpAsyncTaskRunner.Destroy;
begin
  Cancel;
  if FTask <> nil then
  begin
    if FTask.Status = TTaskStatus.Running then
      FTask.Wait(1500);
    FTask := nil;
  end;
  inherited Destroy;
end;

procedure TDlpAsyncTaskRunner.NotifyProgress(ACurrent, ATotal: Integer; const AStatusMsg: string);
var
  Cur, Tot: Integer;
  Msg: string;
begin
  if not Assigned(FOnProgress) then
    Exit;

  Cur := ACurrent;
  Tot := ATotal;
  Msg := AStatusMsg;

  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOnProgress) then
        FOnProgress(Self, Cur, Tot, Msg);
    end);
end;

procedure TDlpAsyncTaskRunner.RunAsync;
begin
  if FIsRunning then
    raise Exception.Create('TDlpAsyncTaskRunner: Uma tarefa assíncrona já está em execução.');

  FIsRunning := True;
  FCancelled := False;

  FTask := TTask.Run(
    procedure
    var
      TaskSuccess: Boolean;
      TaskError: string;
    begin
      TaskSuccess := False;
      TaskError := '';

      try
        if Assigned(FOnExecuteTask) then
        begin
          FOnExecuteTask(Self, FCancelled);
          TaskSuccess := not FCancelled;
        end;
      except
        on E: Exception do
        begin
          TaskSuccess := False;
          TaskError := E.Message;
        end;
      end;

      TThread.Queue(nil,
        procedure
        begin
          FIsRunning := False;
          FTask := nil;
          if Assigned(FOnComplete) then
            FOnComplete(Self, TaskSuccess, TaskError);
        end);
    end);
end;

procedure TDlpAsyncTaskRunner.Cancel;
begin
  FCancelled := True;
  if FTask <> nil then
    FTask.Cancel;
end;

end.
