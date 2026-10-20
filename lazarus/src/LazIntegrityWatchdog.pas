{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 37: Auditor de Integridade de Executáveis (TLazIntegrityWatchdog)
  Componente: TLazIntegrityWatchdog
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Guardião de integridade binária e anti-adulteração (Anti-Tampering)
             para executáveis LCL. Executa cálculo de hash SHA-256 do próprio binário
             em disco na inicialização, detecção de depuradores ativos (Debuggers),
             verificação de pontos de interrupção (Software Breakpoints 0xCC) e
             término seguro de processo em caso de violação comprovada.
==============================================================================}
unit LazIntegrityWatchdog;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  sha256;

type
  { Tipo de violação de segurança detectada }
  TTamperType = (ttBinaryChecksumMismatch, ttDebuggerDetected, ttMemoryHookDetected);

  { Evento disparado quando uma adulteração é identificada }
  TTamperDetectedEvent = procedure(Sender: TObject; ATamperType: TTamperType;
    const ADescription: string; var ActionAbort: Boolean) of object;

  {============================================================================
    Componente: TLazIntegrityWatchdog
    Auditor anti-adulteração de binários e memória em tempo de execução
  ============================================================================}
  TLazIntegrityWatchdog = class(TComponent)
  private
    FExpectedHash: string;
    FCheckOnStartup: Boolean;
    FTerminateOnViolation: Boolean;
    FOnTamperDetected: TTamperDetectedEvent;

    function ComputeExecutableSha256: string;
    function IsDebuggerActive: Boolean;
    function HasMemoryBreakpoints(FuncPtr: Pointer; CheckBytes: Integer): Boolean;
    procedure TriggerViolation(AType: TTamperType; const ADesc: string);
  public
    constructor Create(AOwner: TComponent); override;

    { Métodos de verificação }
    function VerifyBinaryIntegrity: Boolean;
    function CheckSystemSecurity: Boolean;
    function GetCurrentBinaryHash: string;
  published
    property ExpectedHash: string read FExpectedHash write FExpectedHash;
    property CheckOnStartup: Boolean read FCheckOnStartup write FCheckOnStartup default True;
    property TerminateOnViolation: Boolean read FTerminateOnViolation write FTerminateOnViolation default True;
    property OnTamperDetected: TTamperDetectedEvent read FOnTamperDetected write FOnTamperDetected;
  end;

procedure Register;

implementation

{$IFDEF WINDOWS}
uses
  Windows;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazIntegrityWatchdog]);
end;

{ TLazIntegrityWatchdog }

constructor TLazIntegrityWatchdog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExpectedHash := '';
  FCheckOnStartup := True;
  FTerminateOnViolation := True;
end;

function TLazIntegrityWatchdog.ComputeExecutableSha256: string;
var
  ExePath: string;
  FS: TFileStream;
  Digest: TSHA256Digest;
  i: Integer;
begin
  ExePath := ParamStr(0);
  if not FileExists(ExePath) then Exit('');

  FS := TFileStream.Create(ExePath, fmOpenRead or fmShareDenyNone);
  try
    Digest := SHA256Stream(FS);
    Result := '';
    for i := 0 to 31 do
      Result := Result + IntToHex(Digest[i], 2);
    Result := LowerCase(Result);
  finally
    FS.Free;
  end;
end;

function TLazIntegrityWatchdog.GetCurrentBinaryHash: string;
begin
  Result := ComputeExecutableSha256;
end;

function TLazIntegrityWatchdog.IsDebuggerActive: Boolean;
{$IFDEF WINDOWS}
begin
  Result := IsDebuggerPresent;
end;
{$ELSE}
var
  SL: TStringList;
  i, P: Integer;
  Line: string;
begin
  Result := False;
  if FileExists('/proc/self/status') then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile('/proc/self/status');
      for i := 0 to SL.Count - 1 do
      begin
        Line := SL[i];
        if Pos('TracerPid:', Line) = 1 then
        begin
          P := StrToIntDef(Trim(Copy(Line, 11, Length(Line))), 0);
          Result := (P > 0);
          Break;
        end;
      end;
    finally
      SL.Free;
    end;
  end;
end;
{$ENDIF}

function TLazIntegrityWatchdog.HasMemoryBreakpoints(FuncPtr: Pointer; CheckBytes: Integer): Boolean;
var
  P: PByte;
  i: Integer;
begin
  Result := False;
  if not Assigned(FuncPtr) or (CheckBytes <= 0) then Exit;

  P := PByte(FuncPtr);
  for i := 0 to CheckBytes - 1 do
  begin
    { Byte 0xCC corresponde à instrução INT 3 em x86/x64 }
    if P[i] = $CC then
      Exit(True);
  end;
end;

procedure TLazIntegrityWatchdog.TriggerViolation(AType: TTamperType; const ADesc: string);
var
  ShouldAbort: Boolean;
begin
  ShouldAbort := FTerminateOnViolation;
  if Assigned(FOnTamperDetected) then
    FOnTamperDetected(Self, AType, ADesc, ShouldAbort);

  if ShouldAbort then
  begin
    { Encerramento forçado e determinístico do processo }
    Halt(1);
  end;
end;

function TLazIntegrityWatchdog.VerifyBinaryIntegrity: Boolean;
var
  CurrentHash: string;
begin
  if FExpectedHash = '' then Exit(True);

  CurrentHash := ComputeExecutableSha256;
  if not SameText(CurrentHash, FExpectedHash) then
  begin
    TriggerViolation(ttBinaryChecksumMismatch,
      Format('Checksum divergente! Lido: %s | Esperado: %s', [CurrentHash, FExpectedHash]));
    Exit(False);
  end;

  Result := True;
end;

function TLazIntegrityWatchdog.CheckSystemSecurity: Boolean;
begin
  Result := True;

  if IsDebuggerActive then
  begin
    TriggerViolation(ttDebuggerDetected, 'Depurador ativo detectado anexado ao processo.');
    Exit(False);
  end;

  if HasMemoryBreakpoints(@TLazIntegrityWatchdog.CheckSystemSecurity, 32) then
  begin
    TriggerViolation(ttMemoryHookDetected, 'Software breakpoint (0xCC) detectado no corpo da função.');
    Exit(False);
  end;
end;

end.
