{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 35: Cofre Seguro de Credenciais e Segredos (TDlpCryptoVaultStorage)
  Componente: TDlpCryptoVaultStorage
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / macOS)
  Descrição: Armazenamento blindado de chaves criptográficas, tokens de API e senhas
             em memória volátil com proteção ativa contra análise de despejo (dump)
             de processo. Aplica máscara dinâmica baseada em entropia de execução,
             limpeza garantida de buffers efêmeros e persistência em cofre cifrado.
==============================================================================}
unit DlpCryptoVaultStorage;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Hash;

type
  { Entrada encapsulada de segredo mascarado }
  TDlpVaultEntry = class
  public
    KeyName: string;
    MaskedData: TBytes;
    DataLength: Integer;
    Salt: Byte;
  end;

  {============================================================================
    Componente: TDlpCryptoVaultStorage
    Cofre de credenciais sensíveis em memória volátil
  ============================================================================}
  TDlpCryptoVaultStorage = class(TComponent)
  private
    FEntries: TList;
    FMasterRuntimeKey: TBytes;
    FVaultFile: string;

    procedure InitializeMasterKey;
    procedure SecureClearBuffer(var Buffer; Size: Integer);
    function FindEntry(const AKeyName: string): TDlpVaultEntry;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure StoreSecret(const AKeyName, ASecretValue: string);
    function RetrieveSecret(const AKeyName: string): string;
    procedure DeleteSecret(const AKeyName: string);
    function HasSecret(const AKeyName: string): Boolean;
    procedure ClearAll;

    procedure SaveVaultToFile(const AFileName: string; const AMasterPassphrase: string);
    procedure LoadVaultFromFile(const AFileName: string; const AMasterPassphrase: string);
  published
    property VaultFile: string read FVaultFile write FVaultFile;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpCryptoVaultStorage]);
end;

{ TDlpCryptoVaultStorage }

constructor TDlpCryptoVaultStorage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TList.Create;
  InitializeMasterKey;
end;

destructor TDlpCryptoVaultStorage.Destroy;
begin
  ClearAll;
  FEntries.Free;
  SecureClearBuffer(FMasterRuntimeKey[0], Length(FMasterRuntimeKey));
  inherited Destroy;
end;

procedure TDlpCryptoVaultStorage.InitializeMasterKey;
var
  Seed: string;
begin
  Seed := Format('PID:%d;Tick:%d;Time:%s;Rand:%d',
    [GetCurrentProcessId, GetTickCount, FormatDateTime('yyyymmddhhnnsszzz', Now), Random(MaxInt)]);
  FMasterRuntimeKey := THashSHA2.GetHashBytes(Seed, THashSHA2.TSHA2Version.SHA256);
end;

procedure TDlpCryptoVaultStorage.SecureClearBuffer(var Buffer; Size: Integer);
var
  P: PByte;
  i: Integer;
begin
  P := PByte(@Buffer);
  for i := 0 to Size - 1 do
    P[i] := 0;
end;

function TDlpCryptoVaultStorage.FindEntry(const AKeyName: string): TDlpVaultEntry;
var
  i: Integer;
  E: TDlpVaultEntry;
begin
  for i := 0 to FEntries.Count - 1 do
  begin
    E := TDlpVaultEntry(FEntries[i]);
    if SameText(E.KeyName, AKeyName) then
      Exit(E);
  end;
  Result := nil;
end;

procedure TDlpCryptoVaultStorage.StoreSecret(const AKeyName, ASecretValue: string);
var
  E: TDlpVaultEntry;
  PlainBytes: TBytes;
  Len, i: Integer;
begin
  E := FindEntry(AKeyName);
  if not Assigned(E) then
  begin
    E := TDlpVaultEntry.Create;
    E.KeyName := AKeyName;
    FEntries.Add(E);
  end;

  PlainBytes := TEncoding.UTF8.GetBytes(ASecretValue);
  Len := Length(PlainBytes);
  E.DataLength := Len;
  E.Salt := Byte(Random(256));
  SetLength(E.MaskedData, Len);

  for i := 0 to Len - 1 do
    E.MaskedData[i] := PlainBytes[i] xor FMasterRuntimeKey[i mod 32] xor E.Salt;

  SecureClearBuffer(PlainBytes[0], Len);
end;

function TDlpCryptoVaultStorage.RetrieveSecret(const AKeyName: string): string;
var
  E: TDlpVaultEntry;
  TempBytes: TBytes;
  i: Integer;
begin
  E := FindEntry(AKeyName);
  if not Assigned(E) or (E.DataLength = 0) then Exit('');

  SetLength(TempBytes, E.DataLength);
  for i := 0 to E.DataLength - 1 do
    TempBytes[i] := E.MaskedData[i] xor FMasterRuntimeKey[i mod 32] xor E.Salt;

  Result := TEncoding.UTF8.GetString(TempBytes);
  SecureClearBuffer(TempBytes[0], E.DataLength);
end;

procedure TDlpCryptoVaultStorage.DeleteSecret(const AKeyName: string);
var
  E: TDlpVaultEntry;
begin
  E := FindEntry(AKeyName);
  if Assigned(E) then
  begin
    FEntries.Remove(E);
    if Length(E.MaskedData) > 0 then
      SecureClearBuffer(E.MaskedData[0], Length(E.MaskedData));
    E.Free;
  end;
end;

function TDlpCryptoVaultStorage.HasSecret(const AKeyName: string): Boolean;
begin
  Result := (FindEntry(AKeyName) <> nil);
end;

procedure TDlpCryptoVaultStorage.ClearAll;
var
  i: Integer;
  E: TDlpVaultEntry;
begin
  for i := 0 to FEntries.Count - 1 do
  begin
    E := TDlpVaultEntry(FEntries[i]);
    if Length(E.MaskedData) > 0 then
      SecureClearBuffer(E.MaskedData[0], Length(E.MaskedData));
    E.Free;
  end;
  FEntries.Clear;
end;

procedure TDlpCryptoVaultStorage.SaveVaultToFile(const AFileName: string;
  const AMasterPassphrase: string);
var
  FS: TFileStream;
  PassHash, EncryptedBytes, KeyBytes: TBytes;
  i, j, Count, NameLen, DataLen: Integer;
  E: TDlpVaultEntry;
  PlainVal: string;
  Sig: AnsiString;
begin
  PassHash := THashSHA2.GetHashBytes(AMasterPassphrase + 'VaultSalt2026', THashSHA2.TSHA2Version.SHA256);
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    Sig := 'VAULT10';
    FS.WriteBuffer(Pointer(Sig)^, 7);
    Count := FEntries.Count;
    FS.WriteBuffer(Count, SizeOf(Integer));

    for i := 0 to FEntries.Count - 1 do
    begin
      E := TDlpVaultEntry(FEntries[i]);
      KeyBytes := TEncoding.UTF8.GetBytes(E.KeyName);
      NameLen := Length(KeyBytes);
      FS.WriteBuffer(NameLen, SizeOf(Integer));
      FS.WriteBuffer(Pointer(KeyBytes)^, NameLen);

      PlainVal := RetrieveSecret(E.KeyName);
      EncryptedBytes := TEncoding.UTF8.GetBytes(PlainVal);
      DataLen := Length(EncryptedBytes);
      FS.WriteBuffer(DataLen, SizeOf(Integer));

      if DataLen > 0 then
      begin
        for j := 0 to DataLen - 1 do
          EncryptedBytes[j] := EncryptedBytes[j] xor PassHash[j mod 32];
        FS.WriteBuffer(Pointer(EncryptedBytes)^, DataLen);
        SecureClearBuffer(EncryptedBytes[0], DataLen);
      end;
    end;
  finally
    FS.Free;
  end;
end;

procedure TDlpCryptoVaultStorage.LoadVaultFromFile(const AFileName: string;
  const AMasterPassphrase: string);
var
  FS: TFileStream;
  Sig: array[0..6] of AnsiChar;
  PassHash, KeyBytes, EncryptedBytes: TBytes;
  i, j, Count, NameLen, DataLen: Integer;
  KeyName, PlainVal: string;
begin
  if not FileExists(AFileName) then
    raise Exception.Create('Arquivo do cofre nao localizado: ' + AFileName);

  PassHash := THashSHA2.GetHashBytes(AMasterPassphrase + 'VaultSalt2026', THashSHA2.TSHA2Version.SHA256);
  ClearAll;

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    FS.ReadBuffer(Sig, 7);
    if Sig <> 'VAULT10' then
      raise Exception.Create('Assinatura do arquivo do cofre invalida.');

    FS.ReadBuffer(Count, SizeOf(Integer));
    for i := 0 to Count - 1 do
    begin
      FS.ReadBuffer(NameLen, SizeOf(Integer));
      SetLength(KeyBytes, NameLen);
      FS.ReadBuffer(Pointer(KeyBytes)^, NameLen);
      KeyName := TEncoding.UTF8.GetString(KeyBytes);

      FS.ReadBuffer(DataLen, SizeOf(Integer));
      SetLength(EncryptedBytes, DataLen);
      if DataLen > 0 then
      begin
        FS.ReadBuffer(Pointer(EncryptedBytes)^, DataLen);
        for j := 0 to DataLen - 1 do
          EncryptedBytes[j] := EncryptedBytes[j] xor PassHash[j mod 32];
        PlainVal := TEncoding.UTF8.GetString(EncryptedBytes);
        SecureClearBuffer(EncryptedBytes[0], DataLen);
      end
      else
        PlainVal := '';

      StoreSecret(KeyName, PlainVal);
    end;
  finally
    FS.Free;
  end;
end;

end.
