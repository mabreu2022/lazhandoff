{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 49: Harness de Micro-Benchmarks de Código (TDlpCodeBenchmarkHarness)
  Componente: TDlpCodeBenchmarkHarness
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Multiplataforma)
  Descrição: Harness de micro-medição e profiling comparativo de código.
             Utiliza temporizadores de alta resolução do hardware (QueryPerformanceCounter)
             e amostragem estatística com fase de aquecimento (Warmup) para
             comparar estruturas de dados, algoritmos de ordenação e serializadores.
==============================================================================}
unit DlpCodeBenchmarkHarness;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows;

type
  { Assinatura do método ou procedimento a ser medido }
  TDlpBenchmarkProcedure = procedure of object;

  { Relatório estatístico consolidado de uma medição }
  TDlpBenchmarkReport = record
    BenchmarkName: string;
    Iterations: Integer;
    TotalElapsedMs: Double;
    AverageNanosecondsPerOp: Double;
    OperationsPerSecond: Double;
  end;

  { Item cadastrado para comparação }
  TDlpBenchmarkTarget = class
  public
    Name: string;
    Proc: TDlpBenchmarkProcedure;
    LastReport: TDlpBenchmarkReport;
  end;

  {============================================================================
    Componente: TDlpCodeBenchmarkHarness
    Executor estatístico de benchmarks de alta resolução
  ============================================================================}
  TDlpCodeBenchmarkHarness = class(TComponent)
  private
    FWarmupIterations: Integer;
    FMeasurementIterations: Integer;
    FTargets: TList;
    FFrequency: Int64;

    function ReadHighResCounter: Int64;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure RegisterTarget(const AName: string; AProc: TDlpBenchmarkProcedure);
    procedure ClearTargets;

    function RunBenchmark(const AName: string; AProc: TDlpBenchmarkProcedure): TDlpBenchmarkReport;
    function RunAllBenchmarks: string;

    property Targets: TList read FTargets;
  published
    property WarmupIterations: Integer read FWarmupIterations write FWarmupIterations default 1000;
    property MeasurementIterations: Integer read FMeasurementIterations write FMeasurementIterations default 100000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpCodeBenchmarkHarness]);
end;

{ TDlpCodeBenchmarkHarness }

constructor TDlpCodeBenchmarkHarness.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWarmupIterations := 1000;
  FMeasurementIterations := 100000;
  FTargets := TList.Create;
  QueryPerformanceFrequency(FFrequency);
end;

destructor TDlpCodeBenchmarkHarness.Destroy;
begin
  ClearTargets;
  FTargets.Free;
  inherited Destroy;
end;

procedure TDlpCodeBenchmarkHarness.ClearTargets;
var
  i: Integer;
begin
  for i := 0 to FTargets.Count - 1 do
    TDlpBenchmarkTarget(FTargets[i]).Free;
  FTargets.Clear;
end;

procedure TDlpCodeBenchmarkHarness.RegisterTarget(const AName: string; AProc: TDlpBenchmarkProcedure);
var
  T: TDlpBenchmarkTarget;
begin
  T := TDlpBenchmarkTarget.Create;
  T.Name := AName;
  T.Proc := AProc;
  FTargets.Add(T);
end;

function TDlpCodeBenchmarkHarness.ReadHighResCounter: Int64;
begin
  QueryPerformanceCounter(Result);
end;

function TDlpCodeBenchmarkHarness.RunBenchmark(const AName: string;
  AProc: TDlpBenchmarkProcedure): TDlpBenchmarkReport;
var
  i: Integer;
  StartCount, EndCount, DeltaCount: Int64;
  TotalMs: Double;
begin
  Result.BenchmarkName := AName;
  Result.Iterations := FMeasurementIterations;

  if not Assigned(AProc) then
  begin
    Result.TotalElapsedMs := 0;
    Result.AverageNanosecondsPerOp := 0;
    Result.OperationsPerSecond := 0;
    Exit;
  end;

  { Fase de aquecimento de caches L1/L2 }
  for i := 1 to FWarmupIterations do
    AProc();

  StartCount := ReadHighResCounter;
  for i := 1 to FMeasurementIterations do
    AProc();
  EndCount := ReadHighResCounter;

  DeltaCount := EndCount - StartCount;
  if FFrequency > 0 then
    TotalMs := (DeltaCount * 1000.0) / FFrequency
  else
    TotalMs := 0.001;

  if TotalMs <= 0 then TotalMs := 0.001;

  Result.TotalElapsedMs := TotalMs;
  Result.AverageNanosecondsPerOp := (TotalMs * 1000000.0) / FMeasurementIterations;
  Result.OperationsPerSecond := (FMeasurementIterations / TotalMs) * 1000.0;
end;

function TDlpCodeBenchmarkHarness.RunAllBenchmarks: string;
var
  i: Integer;
  Target: TDlpBenchmarkTarget;
  SB: TStringList;
begin
  SB := TStringList.Create;
  try
    SB.Add('========================================================================================');
    SB.Add('RELATÓRIO DE MICRO-BENCHMARKS E ALTA RESOLUÇÃO (QPC)');
    SB.Add('========================================================================================');
    SB.Add(Format('%-30s | %10s | %12s | %12s | %15s',
      ['Nome do Algoritmo', 'Iterações', 'Tempo (ms)', 'Ns/Op', 'Ops/Segundo']));
    SB.Add('----------------------------------------------------------------------------------------');

    for i := 0 to FTargets.Count - 1 do
    begin
      Target := TDlpBenchmarkTarget(FTargets[i]);
      Target.LastReport := RunBenchmark(Target.Name, Target.Proc);

      SB.Add(Format('%-30s | %10d | %12.2f | %12.1f | %15.0f', [
        Target.LastReport.BenchmarkName,
        Target.LastReport.Iterations,
        Target.LastReport.TotalElapsedMs,
        Target.LastReport.AverageNanosecondsPerOp,
        Target.LastReport.OperationsPerSecond
      ]));
    end;

    SB.Add('========================================================================================');
    Result := SB.Text;
  finally
    SB.Free;
  end;
end;

end.
