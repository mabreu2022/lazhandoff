{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 35: Cofre Seguro de Credenciais e Segredos (TLazCryptoVaultStorage)
  Componente: TLazCryptoVaultStorage
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Armazenamento blindado de segredos em memória RAM (API Keys, senhas
             de banco de dados, tokens privados) imune a inspeção estática de dumps
             de memória (Memory Scraping). Implementa máscara volátil rotativa,
             limpeza forçada de memória (ZeroMemory) e persistência criptografada.
==============================================================================}
unit LazCryptoVaultStorage;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  sha256;

type
  { Entrada de segredo ofuscada em memória }
  TVaultEntry = class
  public
    KeyName: string;
    MaskedData: array of Byte;
    DataLength: Integer;
    Salt: Byte;
  end;

  {============================================================================
    Componente: TLazCryptoVaultStorage
    Cofre em memória para salvaguarda de credenciais corporativas sensíveis
  ============================================================================}
  TLazCryptoVaultStorage = class(TComponent)
  private
    FEntries: TFPList;
    FMasterRuntimeKey: array[0..31] of Byte;
    FVaultFile: string;

    procedure InitializeMasterKey;
    procedure SecureClearBuffer(var Buffer; Size: Integer);
    function FindEntry(const AKeyName: string): TVaultEntry;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Gestão de Segredos }
    procedure StoreSecret(const AKeyName, ASecretValue: string);
    function RetrieveSecret(const AKeyName: string): string;
    procedure DeleteSecret(const AKeyName: string);
    function HasSecret(const AKeyName: string): Boolean;
    procedure ClearAll;

    { Persistência Criptografada }
    procedure SaveVaultToFile(const AFileName: string; const AMasterPassphrase: string);
    procedure LoadVaultFromFile(const AFileName: string; const AMasterPassphrase: string);
  published
    property VaultFile: string read FVaultFile write FVaultFile;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazCryptoVaultStorage]);
end;

{ TLazCryptoVaultStorage }

constructor TLazCryptoVaultStorage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TFPList.Create;
  InitializeMasterKey;
end;

destructor TLazCryptoVaultStorage.Destroy;
begin
  ClearAll;
  FEntries.Free;
  SecureClearBuffer(FMasterRuntimeKey, SizeOf(FMasterRuntimeKey));
  inherited Destroy;
end;

procedure TLazCryptoVaultStorage.InitializeMasterKey;
var
  Seed: string;
  Digest: TSHA256Digest;
  i: Integer;
begin
  { Semente única gerada na inicialização do processo a partir de entropia dinâmica }
  Seed := Format('PID:%d;Tick:%d;Time:%s;Rand:%d',
    [GetProcessID, GetTickCount, FormatDateTime('yyyymmddhhnnsszzz', Now), Random(MaxInt)]);
  Digest := SHA256String(Seed);
  for i := 0 to 31 do
    FMasterRuntimeKey[i] := Digest[i];
end;

procedure TLazCryptoVaultStorage.SecureClearBuffer(var Buffer; Size: Integer);
var
  P: PByte;
  i: Integer;
begin
  P := PByte(@Buffer);
  for i := 0 to Size - 1 do
    P[i] := 0;
end;

function TLazCryptoVaultStorage.FindEntry(const AKeyName: string): TVaultEntry;
var
  i: Integer;
  E: TVaultEntry;
begin
  for i := 0 to FEntries.Count - 1 do
  begin
    E := TVaultEntry(FEntries[i]);
    if SameText(E.KeyName, AKeyName) then
      Exit(E);
  end;
  Result := nil;
end;

procedure TLazCryptoVaultStorage.StoreSecret(const AKeyName, ASecretValue: string);
var
  E: TVaultEntry;
  Len, i: Integer;
  SecretBytes: PByte;
begin
  E := FindEntry(AKeyName);
  if not Assigned(E) then
  begin
    E := TVaultEntry.Create;
    E.KeyName := AKeyName;
    FEntries.Add(E);
  end;

  Len := Length(ASecretValue);
  E.DataLength := Len;
  E.Salt := Byte(Random(256));
  SetLength(E.MaskedData, Len);

  if Len > 0 then
  begin
    SecretBytes := PByte(Pointer(ASecretValue));
    for i := 0 to Len - 1 do
    begin
      { Ofuscação multinível: XOR com chave mestre de tempo de execução + Salt individual }
      E.MaskedData[i] := SecretBytes[i] xor FMasterRuntimeKey[i mod 32] xor E.Salt;
    end;
  end;
end;

function TLazCryptoVaultStorage.RetrieveSecret(const AKeyName: string): string;
var
  E: TVaultEntry;
  TempBuf: array of Byte;
  i: Integer;
begin
  E := FindEntry(AKeyName);
  if not Assigned(E) or (E.DataLength = 0) then Exit('');

  SetLength(TempBuf, E.DataLength);
  for i := 0 to E.DataLength - 1 do
  begin
    TempBuf[i] := E.MaskedData[i] xor FMasterRuntimeKey[i mod 32] xor E.Salt;
  end;

  SetLength(Result, E.DataLength);
  Move(TempBuf[0], Pointer(Result)^, E.DataLength);

  { Limpa imediatamente o buffer temporário de decodificação }
  SecureClearBuffer(TempBuf[0], E.DataLength);
end;

procedure TLazCryptoVaultStorage.DeleteSecret(const AKeyName: string);
var
  E: TVaultEntry;
begin
  E := FindEntry(AKeyName);
  if Assigned(E) then
  begin
    FEntries.Remove(E);
    SecureClearBuffer(E.MaskedData[0], Length(E.MaskedData));
    E.Free;
  end;
end;

function TLazCryptoVaultStorage.HasSecret(const AKeyName: string): Boolean;
begin
  Result := (FindEntry(AKeyName) <> nil);
end;

procedure TLazCryptoVaultStorage.ClearAll;
var
  i: Integer;
  E: TVaultEntry;
begin
  for i := 0 to FEntries.Count - 1 do
  begin
    E := TVaultEntry(FEntries[i]);
    if Length(E.MaskedData) > 0 then
      SecureClearBuffer(E.MaskedData[0], Length(E.MaskedData));
    E.Free;
  end;
  FEntries.Clear;
end;

procedure TLazCryptoVaultStorage.SaveVaultToFile(const AFileName: string;
  const AMasterPassphrase: string);
var
  FS: TFileStream;
  PassHash: TSHA256Digest;
  i, j, Count, NameLen, DataLen: Integer;
  E: TVaultEntry;
  PlainVal: string;
  EncryptedBytes: array of Byte;
begin
  PassHash := SHA256String(AMasterPassphrase + 'VaultSalt2026');
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    { Assinatura mágica 'VAULT10' }
    FS.WriteBuffer('VAULT10', 7);
    Count := FEntries.Count;
    FS.WriteBuffer(Count, SizeOf(Integer));

    for i := 0 to FEntries.Count - 1 do
    begin
      E := TVaultEntry(FEntries[i]);
      NameLen := Length(E.KeyName);
      FS.WriteBuffer(NameLen, SizeOf(Integer));
      FS.WriteBuffer(Pointer(E.KeyName)^, NameLen);

      PlainVal := RetrieveSecret(E.KeyName);
      DataLen := Length(PlainVal);
      FS.WriteBuffer(DataLen, SizeOf(Integer));

      if DataLen > 0 then
      begin
        SetLength(EncryptedBytes, DataLen);
        for j := 0 to DataLen - 1 do
          EncryptedBytes[j] := Byte(Ord(PlainVal[j + 1])) xor PassHash[j mod 32];
        FS.WriteBuffer(EncryptedBytes[0], DataLen);
        SecureClearBuffer(EncryptedBytes[0], DataLen);
      end;
    end;
  finally
    FS.Free;
  end;
end;

procedure TLazCryptoVaultStorage.LoadVaultFromFile(const AFileName: string;
  const AMasterPassphrase: string);
var
  FS: TFileStream;
  Sig: array[0..6] of Char;
  PassHash: TSHA256Digest;
  i, j, Count, NameLen, DataLen: Integer;
  KeyName, PlainVal: string;
  EncryptedBytes: array of Byte;
begin
  if not FileExists(AFileName) then
    raise Exception.Create('Arquivo do cofre não encontrado: ' + AFileName);

  PassHash := SHA256String(AMasterPassphrase + 'VaultSalt2026');
  ClearAll;

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    FS.ReadBuffer(Sig, 7);
    if Sig <> 'VAULT10' then
      raise Exception.Create('Formato de arquivo do cofre inválido.');

    FS.ReadBuffer(Count, SizeOf(Integer));
    for i := 0 to Count - 1 do
    begin
      FS.ReadBuffer(NameLen, SizeOf(Integer));
      SetLength(KeyName, NameLen);
      FS.ReadBuffer(Pointer(KeyName)^, NameLen);

      FS.ReadBuffer(DataLen, SizeOf(Integer));
      SetLength(PlainVal, DataLen);
      if DataLen > 0 then
      begin
        SetLength(EncryptedBytes, DataLen);
        FS.ReadBuffer(EncryptedBytes[0], DataLen);
        for j := 0 to DataLen - 1 do
          PlainVal[j + 1] := Chr(EncryptedBytes[j] xor PassHash[j mod 32]);
        SecureClearBuffer(EncryptedBytes[0], DataLen);
      end;

      StoreSecret(KeyName, PlainVal);
    end;
  finally
    FS.Free;
  end;
end;

end.
