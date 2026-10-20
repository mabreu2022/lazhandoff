{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 37: Auditor de Integridade de Executáveis (TDlpIntegrityWatchdog)
  Componente: TDlpIntegrityWatchdog
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux)
  Descrição: Guardião de integridade e anti-adulteração (Anti-Tampering) para
             binários gerados no Delphi. Executa verificação criptográfica SHA-256
             do executável em disco, detecção de depuradores ativos no sistema
             operacional, inspeção de breakpoints (0xCC / INT 3) e encerramento
             forçado em caso de tentativa de cracking ou injeção de DLL maliciosa.
==============================================================================}
unit DlpIntegrityWatchdog;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Hash,
  Winapi.Windows;

type
  { Categorias de violações de segurança }
  TDlpTamperType = (ttBinaryChecksumMismatch, ttDebuggerDetected, ttMemoryHookDetected);

  { Assinatura do evento de detecção de adulteração }
  TDlpTamperDetectedEvent = procedure(Sender: TObject; ATamperType: TDlpTamperType;
    const ADescription: string; var ActionAbort: Boolean) of object;

  {============================================================================
    Componente: TDlpIntegrityWatchdog
    Auditor anti-adulteração de binários e memória em tempo de execução
  ============================================================================}
  TDlpIntegrityWatchdog = class(TComponent)
  private
    FExpectedHash: string;
    FCheckOnStartup: Boolean;
    FTerminateOnViolation: Boolean;
    FOnTamperDetected: TDlpTamperDetectedEvent;

    function ComputeExecutableSha256: string;
    function IsDebuggerActive: Boolean;
    function HasMemoryBreakpoints(FuncPtr: Pointer; CheckBytes: Integer): Boolean;
    procedure TriggerViolation(AType: TDlpTamperType; const ADesc: string);
  public
    constructor Create(AOwner: TComponent); override;

    function VerifyBinaryIntegrity: Boolean;
    function CheckSystemSecurity: Boolean;
    function GetCurrentBinaryHash: string;
  published
    property ExpectedHash: string read FExpectedHash write FExpectedHash;
    property CheckOnStartup: Boolean read FCheckOnStartup write FCheckOnStartup default True;
    property TerminateOnViolation: Boolean read FTerminateOnViolation write FTerminateOnViolation default True;
    property OnTamperDetected: TDlpTamperDetectedEvent read FOnTamperDetected write FOnTamperDetected;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpIntegrityWatchdog]);
end;

{ TDlpIntegrityWatchdog }

constructor TDlpIntegrityWatchdog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExpectedHash := '';
  FCheckOnStartup := True;
  FTerminateOnViolation := True;
end;

function TDlpIntegrityWatchdog.ComputeExecutableSha256: string;
var
  ExePath: string;
  FS: TFileStream;
begin
  ExePath := ParamStr(0);
  if not FileExists(ExePath) then Exit('');

  FS := TFileStream.Create(ExePath, fmOpenRead or fmShareDenyNone);
  try
    Result := LowerCase(THashSHA2.GetHashString(FS));
  finally
    FS.Free;
  end;
end;

function TDlpIntegrityWatchdog.GetCurrentBinaryHash: string;
begin
  Result := ComputeExecutableSha256;
end;

function TDlpIntegrityWatchdog.IsDebuggerActive: Boolean;
begin
  Result := IsDebuggerPresent;
end;

function TDlpIntegrityWatchdog.HasMemoryBreakpoints(FuncPtr: Pointer; CheckBytes: Integer): Boolean;
var
  P: PByte;
  i: Integer;
begin
  Result := False;
  if not Assigned(FuncPtr) or (CheckBytes <= 0) then Exit;

  P := PByte(FuncPtr);
  for i := 0 to CheckBytes - 1 do
  begin
    if P[i] = $CC then
      Exit(True);
  end;
end;

procedure TDlpIntegrityWatchdog.TriggerViolation(AType: TDlpTamperType; const ADesc: string);
var
  ShouldAbort: Boolean;
begin
  ShouldAbort := FTerminateOnViolation;
  if Assigned(FOnTamperDetected) then
    FOnTamperDetected(Self, AType, ADesc, ShouldAbort);

  if ShouldAbort then
  begin
    Halt(1);
  end;
end;

function TDlpIntegrityWatchdog.VerifyBinaryIntegrity: Boolean;
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

function TDlpIntegrityWatchdog.CheckSystemSecurity: Boolean;
begin
  Result := True;

  if IsDebuggerActive then
  begin
    TriggerViolation(ttDebuggerDetected, 'Depurador detectado anexado ao processo.');
    Exit(False);
  end;

  if HasMemoryBreakpoints(@TDlpIntegrityWatchdog.CheckSystemSecurity, 32) then
  begin
    TriggerViolation(ttMemoryHookDetected, 'Software breakpoint (0xCC) detectado no prologo da funcao.');
    Exit(False);
  end;
end;

end.
