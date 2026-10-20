{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 21: Componentes de Execução Assíncrona e Worker Threads
  Componente: TLazAsyncTaskRunner
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Executor de tarefas assíncronas em segundo plano (background worker)
             com cancelamento cooperativo, despacho seguro para a UI thread
             via Application.QueueAsyncCall e proteção estrita contra deadlocks.
==============================================================================}
unit LazAsyncTaskRunner;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms;

type
  { Assinatura do método executado no contexto da worker thread }
  TLazAsyncTaskExecuteEvent = procedure(Sender: TObject; var Cancelled: Boolean) of object;

  { Assinatura do método de progresso sincronizado com a UI thread }
  TLazAsyncTaskProgressEvent = procedure(Sender: TObject; Current, Total: Integer;
    const StatusMsg: string) of object;

  { Assinatura do método de conclusão sincronizado com a UI thread }
  TLazAsyncTaskCompleteEvent = procedure(Sender: TObject; Success: Boolean;
    const ErrorMsg: string) of object;

  { Estrutura auxiliar para transporte de dados de progresso no QueueAsyncCall }
  PProgressData = ^TProgressData;
  TProgressData = record
    Sender: TObject;
    Current: Integer;
    Total: Integer;
    StatusMsg: string;
  end;

  { Estrutura auxiliar para transporte de conclusão }
  PCompleteData = ^TCompleteData;
  TCompleteData = record
    Sender: TObject;
    Success: Boolean;
    ErrorMsg: string;
  end;

  TLazAsyncTaskRunner = class;

  {============================================================================
    Classe: TLazWorkerThread
    Thread interna de trabalho gerenciada pelo componente
  ============================================================================}
  TLazWorkerThread = class(TThread)
  private
    FRunner: TLazAsyncTaskRunner;
    FCancelled: Boolean;
    FSuccess: Boolean;
    FErrorMessage: string;
  protected
    procedure Execute; override;
  public
    constructor Create(ARunner: TLazAsyncTaskRunner);
    procedure RequestCancel;
    procedure ReportProgress(ACurrent, ATotal: Integer; const AStatusMsg: string);
  end;

  {============================================================================
    Classe: TLazAsyncTaskRunner
    Componente não-visual gerenciador de concorrência e tarefas em background
  ============================================================================}
  TLazAsyncTaskRunner = class(TComponent)
  private
    FWorkerThread: TLazWorkerThread;
    FIsRunning: Boolean;
    FOnExecuteTask: TLazAsyncTaskExecuteEvent;
    FOnProgress: TLazAsyncTaskProgressEvent;
    FOnComplete: TLazAsyncTaskCompleteEvent;

    procedure AsyncHandleProgress(Data: PtrInt);
    procedure AsyncHandleComplete(Data: PtrInt);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Dispara a execução assíncrona }
    procedure RunAsync;

    { Solicita o cancelamento cooperativo da tarefa }
    procedure Cancel;

    { Notifica o progresso a partir do corpo da tarefa }
    procedure NotifyProgress(ACurrent, ATotal: Integer; const AStatusMsg: string);

    property IsRunning: Boolean read FIsRunning;
  published
    property OnExecuteTask: TLazAsyncTaskExecuteEvent read FOnExecuteTask write FOnExecuteTask;
    property OnProgress: TLazAsyncTaskProgressEvent read FOnProgress write FOnProgress;
    property OnComplete: TLazAsyncTaskCompleteEvent read FOnComplete write FOnComplete;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazAsyncTaskRunner]);
end;

{ TLazWorkerThread }

constructor TLazWorkerThread.Create(ARunner: TLazAsyncTaskRunner);
begin
  inherited Create(True); // Cria suspensa
  FRunner := ARunner;
  FCancelled := False;
  FSuccess := False;
  FErrorMessage := '';
  FreeOnTerminate := False;
end;

procedure TLazWorkerThread.RequestCancel;
begin
  FCancelled := True;
end;

procedure TLazWorkerThread.ReportProgress(ACurrent, ATotal: Integer; const AStatusMsg: string);
var
  DataPtr: PProgressData;
begin
  if not Assigned(FRunner.FOnProgress) then
    Exit;

  New(DataPtr);
  DataPtr^.Sender := FRunner;
  DataPtr^.Current := ACurrent;
  DataPtr^.Total := ATotal;
  DataPtr^.StatusMsg := AStatusMsg;

  Application.QueueAsyncCall(@FRunner.AsyncHandleProgress, PtrInt(DataPtr));
end;

procedure TLazWorkerThread.Execute;
var
  CompPtr: PCompleteData;
begin
  FSuccess := False;
  FErrorMessage := '';

  try
    if Assigned(FRunner.FOnExecuteTask) then
    begin
      FRunner.FOnExecuteTask(FRunner, FCancelled);
      FSuccess := not FCancelled;
    end;
  except
    on E: Exception do
    begin
      FSuccess := False;
      FErrorMessage := E.Message;
    end;
  end;

  New(CompPtr);
  CompPtr^.Sender := FRunner;
  CompPtr^.Success := FSuccess;
  CompPtr^.ErrorMsg := FErrorMessage;

  Application.QueueAsyncCall(@FRunner.AsyncHandleComplete, PtrInt(CompPtr));
end;

{ TLazAsyncTaskRunner }

constructor TLazAsyncTaskRunner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWorkerThread := nil;
  FIsRunning := False;
end;

destructor TLazAsyncTaskRunner.Destroy;
begin
  Cancel;
  if FWorkerThread <> nil then
  begin
    FWorkerThread.WaitFor;
    FreeAndNil(FWorkerThread);
  end;
  Application.RemoveAsyncCalls(Self);
  inherited Destroy;
end;

procedure TLazAsyncTaskRunner.RunAsync;
begin
  if FIsRunning then
    raise Exception.Create('TLazAsyncTaskRunner: Uma tarefa assíncrona já está em execução.');

  FIsRunning := True;
  FWorkerThread := TLazWorkerThread.Create(Self);
  FWorkerThread.Start;
end;

procedure TLazAsyncTaskRunner.Cancel;
begin
  if (FWorkerThread <> nil) and FIsRunning then
    FWorkerThread.RequestCancel;
end;

procedure TLazAsyncTaskRunner.NotifyProgress(ACurrent, ATotal: Integer; const AStatusMsg: string);
begin
  if FWorkerThread <> nil then
    FWorkerThread.ReportProgress(ACurrent, ATotal, AStatusMsg);
end;

procedure TLazAsyncTaskRunner.AsyncHandleProgress(Data: PtrInt);
var
  DataPtr: PProgressData;
begin
  DataPtr := PProgressData(Data);
  try
    if Assigned(FOnProgress) and (DataPtr <> nil) then
      FOnProgress(DataPtr^.Sender, DataPtr^.Current, DataPtr^.Total, DataPtr^.StatusMsg);
  finally
    Dispose(DataPtr);
  end;
end;

procedure TLazAsyncTaskRunner.AsyncHandleComplete(Data: PtrInt);
var
  CompPtr: PCompleteData;
begin
  CompPtr := PCompleteData(Data);
  try
    FIsRunning := False;
    if FWorkerThread <> nil then
    begin
      FWorkerThread.WaitFor;
      FreeAndNil(FWorkerThread);
    end;

    if Assigned(FOnComplete) and (CompPtr <> nil) then
      FOnComplete(CompPtr^.Sender, CompPtr^.Success, CompPtr^.ErrorMsg);
  finally
    Dispose(CompPtr);
  end;
end;

end.
