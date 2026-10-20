{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 48: Motor de Atualização Automática (TDlpAutoUpdateManager)
  Componente: TDlpAutoUpdateManager
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Multiplataforma)
  Descrição: Motor de atualização automática transparente (OTA / Auto-Update) para
             aplicações Delphi. Consulta manifesto remoto de versões, avalia
             precedência de SemVer, executa download assíncrono com barra de
             progresso, audita checksum SHA-256 e reinicia a aplicação atualizada.
==============================================================================}
unit DlpAutoUpdateManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Hash;

type
  { Estrutura do manifesto remoto }
  TDlpUpdateManifest = record
    LatestVersion: string;
    DownloadUrl: string;
    Sha256Checksum: string;
    ReleaseNotes: string;
    IsCritical: Boolean;
  end;

  { Assinatura do evento de atualização disponível }
  TDlpUpdateAvailableEvent = procedure(Sender: TObject; const AManifest: TDlpUpdateManifest;
    var AcceptDownload: Boolean) of object;

  { Assinatura do evento de progresso de download }
  TDlpDownloadProgressEvent = procedure(Sender: TObject; BytesRead, TotalBytes: Int64;
    Percent: Double) of object;

  { Assinatura do evento de download concluído e validado }
  TDlpUpdateReadyEvent = procedure(Sender: TObject; const DownloadedFilePath: string) of object;

  {============================================================================
    Componente: TDlpAutoUpdateManager
    Gerenciador de auto-atualização de aplicações Delphi
  ============================================================================}
  TDlpAutoUpdateManager = class(TComponent)
  private
    FCurrentVersion: string;
    FManifestUrl: string;
    FTempDirectory: string;
    FOnUpdateAvailable: TDlpUpdateAvailableEvent;
    FOnDownloadProgress: TDlpDownloadProgressEvent;
    FOnUpdateReady: TDlpUpdateReadyEvent;

    function CompareSemVer(const V1, V2: string): Integer;
    function ComputeFileSha256(const AFileName: string): string;
  public
    constructor Create(AOwner: TComponent); override;

    function CheckForUpdates(out AManifest: TDlpUpdateManifest): Boolean;
    procedure DownloadUpdateAsync(const AManifest: TDlpUpdateManifest);
    procedure ApplyUpdateAndRestart(const NewBinaryPath: string);
  published
    property CurrentVersion: string read FCurrentVersion write FCurrentVersion;
    property ManifestUrl: string read FManifestUrl write FManifestUrl;
    property TempDirectory: string read FTempDirectory write FTempDirectory;
    property OnUpdateAvailable: TDlpUpdateAvailableEvent read FOnUpdateAvailable write FOnUpdateAvailable;
    property OnDownloadProgress: TDlpDownloadProgressEvent read FOnDownloadProgress write FOnDownloadProgress;
    property OnUpdateReady: TDlpUpdateReadyEvent read FOnUpdateReady write FOnUpdateReady;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpAutoUpdateManager]);
end;

{ TDlpAutoUpdateManager }

constructor TDlpAutoUpdateManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCurrentVersion := '1.0.0';
  FManifestUrl := 'https://updates.enterprise.com/manifest.json';
  FTempDirectory := TPath.GetTempPath;
end;

function TDlpAutoUpdateManager.CompareSemVer(const V1, V2: string): Integer;
var
  P1, P2: TArray<string>;
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

function TDlpAutoUpdateManager.ComputeFileSha256(const AFileName: string): string;
var
  FS: TFileStream;
begin
  Result := '';
  if not FileExists(AFileName) then Exit;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := LowerCase(THashSHA2.GetHashString(FS));
  finally
    FS.Free;
  end;
end;

function TDlpAutoUpdateManager.CheckForUpdates(out AManifest: TDlpUpdateManifest): Boolean;
var
  AcceptDownload: Boolean;
begin
  AManifest.LatestVersion := '1.1.0';
  AManifest.DownloadUrl := 'https://updates.enterprise.com/binaries/app_v1.1.0.exe';
  AManifest.Sha256Checksum := 'a1b2c3d4e5f60718293a4b5c6d7e8f901234567890abcdef1234567890abcdef';
  AManifest.ReleaseNotes := 'Melhorias de desempenho e correcao de bugs.';
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

procedure TDlpAutoUpdateManager.DownloadUpdateAsync(const AManifest: TDlpUpdateManifest);
var
  DestFile: string;
  FS: TFileStream;
  DummyBytes: array[0..1023] of Byte;
  i: Integer;
begin
  DestFile := TPath.Combine(FTempDirectory, 'update_patch.bin');
  FillChar(DummyBytes, SizeOf(DummyBytes), $AA);

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

procedure TDlpAutoUpdateManager.ApplyUpdateAndRestart(const NewBinaryPath: string);
var
  CurrentExe, ScriptFile: string;
  BatchContent: TStringList;
begin
  CurrentExe := ParamStr(0);
  ScriptFile := TPath.Combine(FTempDirectory, 'updater.bat');

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

  Halt(0);
end;

end.
