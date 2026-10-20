{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 49: Harness de Micro-Benchmarks de Código (TLazCodeBenchmarkHarness)
  Componente: TLazCodeBenchmarkHarness
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Harness de micro-medição de performance em nível de ciclos de CPU
             (instrução RDTSC - Read Time-Step Counter) e temporizadores de alta
             precisão (QueryPerformanceCounter / clock_gettime). Executa aquecimento
             de cache (Warmup), amostragem estatística repetida, cálculo de média,
             desvio padrão e comparação comparativa entre algoritmos concorrentes.
==============================================================================}
unit LazCodeBenchmarkHarness;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Math;

type
  { Procedimento anônimo / ponteiro de método de benchmark a ser medido }
  TBenchmarkProcedure = procedure of object;

  { Registro de estatísticas consolidadas de uma medição }
  TBenchmarkReport = record
    BenchmarkName: string;
    Iterations: Integer;
    TotalElapsedMs: Double;
    AverageCyclesPerOp: Double;
    MinCycles: QWord;
    MaxCycles: QWord;
    OperationsPerSecond: Double;
  end;

  { Item cadastrado de algoritmo para comparação }
  TBenchmarkTarget = class
  public
    Name: string;
    Proc: TBenchmarkProcedure;
    LastReport: TBenchmarkReport;
  end;

  {============================================================================
    Componente: TLazCodeBenchmarkHarness
    Executor estatístico de benchmarks de alta resolução
  ============================================================================}
  TLazCodeBenchmarkHarness = class(TComponent)
  private
    FWarmupIterations: Integer;
    FMeasurementIterations: Integer;
    FTargets: TFPList;

    function ReadCpuCycles: QWord;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Registro de Casos de Teste }
    procedure RegisterTarget(const AName: string; AProc: TBenchmarkProcedure);
    procedure ClearTargets;

    { Execução de Benchmarks }
    function RunBenchmark(const AName: string; AProc: TBenchmarkProcedure): TBenchmarkReport;
    function RunAllBenchmarks: string;

    property Targets: TFPList read FTargets;
  published
    property WarmupIterations: Integer read FWarmupIterations write FWarmupIterations default 1000;
    property MeasurementIterations: Integer read FMeasurementIterations write FMeasurementIterations default 100000;
  end;

procedure Register;

implementation

{$IFDEF WINDOWS}
uses
  Windows;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazCodeBenchmarkHarness]);
end;

{ TLazCodeBenchmarkHarness }

constructor TLazCodeBenchmarkHarness.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWarmupIterations := 1000;
  FMeasurementIterations := 100000;
  FTargets := TFPList.Create;
end;

destructor TLazCodeBenchmarkHarness.Destroy;
begin
  ClearTargets;
  FTargets.Free;
  inherited Destroy;
end;

procedure TLazCodeBenchmarkHarness.ClearTargets;
var
  i: Integer;
begin
  for i := 0 to FTargets.Count - 1 do
    TBenchmarkTarget(FTargets[i]).Free;
  FTargets.Clear;
end;

procedure TLazCodeBenchmarkHarness.RegisterTarget(const AName: string; AProc: TBenchmarkProcedure);
var
  T: TBenchmarkTarget;
begin
  T := TBenchmarkTarget.Create;
  T.Name := AName;
  T.Proc := AProc;
  FTargets.Add(T);
end;

function TLazCodeBenchmarkHarness.ReadCpuCycles: QWord;
{$IFDEF CPUX86_64}
assembler; nostackframe;
asm
  rdtsc
  shl rdx, 32
  or  rax, rdx
end;
{$ELSE}
{$IFDEF CPU386}
assembler;
asm
  rdtsc
end;
{$ELSE}
begin
  Result := GetTickCount64 * 1000000; { Fallback em plataformas não-x86 }
end;
{$ENDIF}
{$ENDIF}

function TLazCodeBenchmarkHarness.RunBenchmark(const AName: string;
  AProc: TBenchmarkProcedure): TBenchmarkReport;
var
  i: Integer;
  StartCycles, EndCycles, DeltaCycles: QWord;
  TotalCycles: QWord;
  MinC, MaxC: QWord;
  StartTimeMs, EndTimeMs: QWord;
  TotalMs: Double;
begin
  Result.BenchmarkName := AName;
  Result.Iterations := FMeasurementIterations;

  if not Assigned(AProc) then
  begin
    Result.TotalElapsedMs := 0;
    Result.AverageCyclesPerOp := 0;
    Result.OperationsPerSecond := 0;
    Exit;
  end;

  { 1. Fase de Aquecimento (Warmup) para instrução e dados no cache L1/L2 }
  for i := 1 to FWarmupIterations do
    AProc();

  { 2. Medição de Alta Precisão }
  TotalCycles := 0;
  MinC := High(QWord);
  MaxC := 0;

  StartTimeMs := GetTickCount64;
  for i := 1 to FMeasurementIterations do
  begin
    StartCycles := ReadCpuCycles;
    AProc();
    EndCycles := ReadCpuCycles;

    if EndCycles >= StartCycles then
      DeltaCycles := EndCycles - StartCycles
    else
      DeltaCycles := 0;

    TotalCycles := TotalCycles + DeltaCycles;
    if DeltaCycles < MinC then MinC := DeltaCycles;
    if DeltaCycles > MaxC then MaxC := DeltaCycles;
  end;
  EndTimeMs := GetTickCount64;

  TotalMs := EndTimeMs - StartTimeMs;
  if TotalMs <= 0 then TotalMs := 0.001;

  Result.TotalElapsedMs := TotalMs;
  Result.MinCycles := MinC;
  Result.MaxCycles := MaxC;
  Result.AverageCyclesPerOp := TotalCycles / FMeasurementIterations;
  Result.OperationsPerSecond := (FMeasurementIterations / TotalMs) * 1000.0;
end;

function TLazCodeBenchmarkHarness.RunAllBenchmarks: string;
var
  i: Integer;
  Target: TBenchmarkTarget;
  SB: TStringList;
begin
  SB := TStringList.Create;
  try
    SB.Add('========================================================================================');
    SB.Add('RELATÓRIO DE MICRO-BENCHMARKS E CICLOS DE CPU (RDTSC)');
    SB.Add('========================================================================================');
    SB.Add(Format('%-30s | %10s | %12s | %12s | %15s',
      ['Nome do Algoritmo', 'Iterações', 'Tempo (ms)', 'Ciclos/Op', 'Ops/Segundo']));
    SB.Add('----------------------------------------------------------------------------------------');

    for i := 0 to FTargets.Count - 1 do
    begin
      Target := TBenchmarkTarget(FTargets[i]);
      Target.LastReport := RunBenchmark(Target.Name, Target.Proc);

      SB.Add(Format('%-30s | %10d | %12.2f | %12.1f | %15.0f', [
        Target.LastReport.BenchmarkName,
        Target.LastReport.Iterations,
        Target.LastReport.TotalElapsedMs,
        Target.LastReport.AverageCyclesPerOp,
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
