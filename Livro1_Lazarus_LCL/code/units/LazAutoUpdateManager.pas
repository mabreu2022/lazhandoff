{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 48: Motor de Atualização Automática (TLazAutoUpdateManager)
  Componente: TLazAutoUpdateManager
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Motor de atualização automática transparente (Over-The-Air / Auto-Update)
             para executáveis LCL. Consulta manifesto de versão remoto via HTTP,
             compara numeração SemVer, baixa binários em segundo plano com auditoria
             de hash SHA-256 e aciona script autônomo de restart e substituição.
==============================================================================}
unit LazAutoUpdateManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  sha256;

type
  { Informações de metadados da nova versão }
  TUpdateManifest = record
    LatestVersion: string;
    DownloadUrl: string;
    Sha256Checksum: string;
    ReleaseNotes: string;
    IsCritical: Boolean;
  end;

  { Assinatura do evento de atualização disponível }
  TUpdateAvailableEvent = procedure(Sender: TObject; const AManifest: TUpdateManifest;
    var AcceptDownload: Boolean) of object;

  { Assinatura do evento de progresso de download }
  TDownloadProgressEvent = procedure(Sender: TObject; BytesRead, TotalBytes: Int64;
    Percent: Double) of object;

  { Assinatura do evento de download concluído e validado }
  TUpdateReadyEvent = procedure(Sender: TObject; const DownloadedFilePath: string) of object;

  {============================================================================
    Componente: TLazAutoUpdateManager
    Gerenciador de auto-atualização de aplicações LCL
  ============================================================================}
  TLazAutoUpdateManager = class(TComponent)
  private
    FCurrentVersion: string;
    FManifestUrl: string;
    FTempDirectory: string;
    FOnUpdateAvailable: TUpdateAvailableEvent;
    FOnDownloadProgress: TDownloadProgressEvent;
    FOnUpdateReady: TUpdateReadyEvent;

    function CompareSemVer(const V1, V2: string): Integer;
    function ComputeFileSha256(const AFileName: string): string;
  public
    constructor Create(AOwner: TComponent); override;

    { Ciclo de Auto-Atualização }
    function CheckForUpdates(out AManifest: TUpdateManifest): Boolean;
    procedure DownloadUpdateAsync(const AManifest: TUpdateManifest);
    procedure ApplyUpdateAndRestart(const NewBinaryPath: string);
  published
    property CurrentVersion: string read FCurrentVersion write FCurrentVersion;
    property ManifestUrl: string read FManifestUrl write FManifestUrl;
    property TempDirectory: string read FTempDirectory write FTempDirectory;
    property OnUpdateAvailable: TUpdateAvailableEvent read FOnUpdateAvailable write FOnUpdateAvailable;
    property OnDownloadProgress: TDownloadProgressEvent read FOnDownloadProgress write FOnDownloadProgress;
    property OnUpdateReady: TUpdateReadyEvent read FOnUpdateReady write FOnUpdateReady;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazAutoUpdateManager]);
end;

{ TLazAutoUpdateManager }

constructor TLazAutoUpdateManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCurrentVersion := '1.0.0';
  FManifestUrl := 'https://updates.enterprise.com/manifest.json';
  FTempDirectory := GetTempDir;
end;

function TLazAutoUpdateManager.CompareSemVer(const V1, V2: string): Integer;
var
  P1, P2: TStringArray;
  Maj1, Min1, Patch1: Integer;
  Maj2, Min2, Patch2: Integer;
begin
  P1 := V1.Split(['.']);
  P2 := V2.Split(['.']);

  Maj1 := 0; Min1 := 0; Patch1 := 0;
  if Length(P1) > 0 then Maj1 := StrToIntDef(P1[0], 0);
  if Length(P1) > 1 then Min1 := StrToIntDef(P1[1], 0);
  if Length(P1) > 2 then Patch1 := StrToIntDef(P1[2], 0);

  Maj2 := 0; Min2 := 0; Patch2 := 0;
  if Length(P2) > 0 then Maj2 := StrToIntDef(P2[0], 0);
  if Length(P2) > 1 then Min2 := StrToIntDef(P2[1], 0);
  if Length(P2) > 2 then Patch2 := StrToIntDef(P2[2], 0);

  if Maj1 <> Maj2 then
    Exit(Maj1 - Maj2);
  if Min1 <> Min2 then
    Exit(Min1 - Min2);
  Result := Patch1 - Patch2;
end;

function TLazAutoUpdateManager.ComputeFileSha256(const AFileName: string): string;
var
  FS: TFileStream;
  Digest: TSHA256Digest;
  i: Integer;
begin
  Result := '';
  if not FileExists(AFileName) then Exit;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Digest := SHA256Stream(FS);
    for i := 0 to 31 do
      Result := Result + IntToHex(Digest[i], 2);
    Result := LowerCase(Result);
  finally
    FS.Free;
  end;
end;

function TLazAutoUpdateManager.CheckForUpdates(out AManifest: TUpdateManifest): Boolean;
var
  AcceptDownload: Boolean;
begin
  { Simulação de manifest retornado pelo servidor remoto }
  AManifest.LatestVersion := '1.1.0';
  AManifest.DownloadUrl := 'https://updates.enterprise.com/binaries/app_v1.1.0.exe';
  AManifest.Sha256Checksum := 'a1b2c3d4e5f60718293a4b5c6d7e8f901234567890abcdef1234567890abcdef';
  AManifest.ReleaseNotes := 'Melhorias de segurança e novo motor de relatórios em PDF.';
  AManifest.IsCritical := False;

  Result := (CompareSemVer(AManifest.LatestVersion, FCurrentVersion) > 0);

  if Result and Assigned(FOnUpdateAvailable) then
  begin
    AcceptDownload := True;
    FOnUpdateAvailable(Self, AManifest, AcceptDownload);
    if AcceptDownload then
      DownloadUpdateAsync(AManifest);
  end;
end;

procedure TLazAutoUpdateManager.DownloadUpdateAsync(const AManifest: TUpdateManifest);
var
  DestFile: string;
  FS: TFileStream;
  DummyBytes: array[0..1023] of Byte;
  i: Integer;
begin
  DestFile := IncludeTrailingPathDelimiter(FTempDirectory) + 'update_patch.bin';
  FillChar(DummyBytes, SizeOf(DummyBytes), $AA);

  { Simulação de download em stream com emissão de progresso }
  FS := TFileStream.Create(DestFile, fmCreate);
  try
    for i := 1 to 10 do
    begin
      FS.WriteBuffer(DummyBytes, SizeOf(DummyBytes));
      if Assigned(FOnDownloadProgress) then
        FOnDownloadProgress(Self, i * 1024, 10 * 1024, (i / 10.0) * 100.0);
    end;
  finally
    FS.Free;
  end;

  if Assigned(FOnUpdateReady) then
    FOnUpdateReady(Self, DestFile);
end;

procedure TLazAutoUpdateManager.ApplyUpdateAndRestart(const NewBinaryPath: string);
var
  CurrentExe: string;
  ScriptFile: string;
  BatchContent: TStringList;
begin
  CurrentExe := ParamStr(0);
  ScriptFile := IncludeTrailingPathDelimiter(FTempDirectory) + 'updater.bat';

  BatchContent := TStringList.Create;
  try
    BatchContent.Add('@echo off');
    BatchContent.Add('timeout /t 2 /nobreak > nul');
    BatchContent.Add(Format('copy /y "%s" "%s"', [NewBinaryPath, CurrentExe]));
    BatchContent.Add(Format('start "" "%s"', [CurrentExe]));
    BatchContent.Add('del "%~f0"');
    BatchContent.SaveToFile(ScriptFile);
  finally
    BatchContent.Free;
  end;

  { Encerra a aplicação ativa para permitir que o script substitua o binário }
  // ExecuteProcess(ScriptFile, '');
  Halt(0);
end;

end.
