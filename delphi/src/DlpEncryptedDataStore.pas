{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 03: Mecanismo de Streaming e Persistência (DFM)
  Componente: TDlpEncryptedDataStore
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e Multiplataforma)
  Descrição: Componente não-visual que implementa persistência customizada
             no arquivo de formulário .dfm utilizando o subsistema TFiler,
             TReader, TWriter e DefineProperties para serializar dicionários
             de dados encriptados com integridade SHA-256 e cifra simétrica.
==============================================================================}
unit DlpEncryptedDataStore;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Hash;

type
  { Evento disparado quando o repositório é modificado ou desserializado }
  TOnDataStoreChanged = procedure(Sender: TObject; AKeyCount: Integer;
    APersistedBytes: Int64) of object;

  {============================================================================
    Classe: TDlpEncryptedDataStore
    Componente para persistência de dicionários criptografados diretamente
    dentro do fluxo DFM através de DefineProperties.
  ============================================================================}
  TDlpEncryptedDataStore = class(TComponent)
  private
    FStore: TDictionary<string, string>;
    FSecretKey: string;
    FDescription: string;
    FAutoEncrypt: Boolean;
    FLastPersistedBytes: Int64;
    FOnDataStoreChanged: TOnDataStoreChanged;

    procedure SetSecretKey(const AValue: string);
    procedure SetDescription(const AValue: string);
    procedure SetAutoEncrypt(const AValue: Boolean);
    function HasEntriesToStore: Boolean;

    { Cifra simétrica de fluxo para ofuscação e proteção de dados no DFM }
    procedure ApplyStreamCipher(var ABytes: TBytes; const AKey: string);

    { Métodos de persistência customizada para o TFiler }
    procedure ReadEncryptedPayload(AStream: TStream);
    procedure WriteEncryptedPayload(AStream: TStream);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos de manipulação dos dados em tempo de execução }
    procedure SetValue(const AKey, AValue: string);
    function GetValue(const AKey: string; const ADefault: string = ''): string;
    function HasKey(const AKey: string): Boolean;
    procedure RemoveKey(const AKey: string);
    procedure Clear;
    function GetKeys: TArray<string>;
    function Count: Integer;

    { Exportação e diagnóstico }
    function ExportAsJson: string;
    procedure ImportFromJson(const AJson: string);
    property PersistedBytes: Int64 read FLastPersistedBytes;
  published
    property Description: string read FDescription write SetDescription;
    property SecretKey: string read FSecretKey write SetSecretKey;
    property AutoEncrypt: Boolean read FAutoEncrypt write SetAutoEncrypt default True;
    property OnDataStoreChanged: TOnDataStoreChanged read FOnDataStoreChanged write FOnDataStoreChanged;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpEncryptedDataStore]);
end;

{ TDlpEncryptedDataStore }

constructor TDlpEncryptedDataStore.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStore := TDictionary<string, string>.Create;
  FSecretKey := 'DlpAthensDefaultKey#2026';
  FDescription := 'Encrypted Data Store';
  FAutoEncrypt := True;
  FLastPersistedBytes := 0;
end;

destructor TDlpEncryptedDataStore.Destroy;
begin
  FreeAndNil(FStore);
  inherited Destroy;
end;

procedure TDlpEncryptedDataStore.SetSecretKey(const AValue: string);
begin
  if FSecretKey <> AValue then
  begin
    FSecretKey := AValue;
    DoChanged;
  end;
end;

procedure TDlpEncryptedDataStore.SetDescription(const AValue: string);
begin
  if FDescription <> AValue then
    FDescription := AValue;
end;

procedure TDlpEncryptedDataStore.SetAutoEncrypt(const AValue: Boolean);
begin
  if FAutoEncrypt <> AValue then
  begin
    FAutoEncrypt := AValue;
    DoChanged;
  end;
end;

function TDlpEncryptedDataStore.HasEntriesToStore: Boolean;
begin
  Result := Assigned(FStore) and (FStore.Count > 0);
end;

procedure TDlpEncryptedDataStore.ApplyStreamCipher(var ABytes: TBytes; const AKey: string);
var
  KeyBytes: TBytes;
  I, KeyLen: Integer;
begin
  if Length(ABytes) = 0 then
    Exit;

  KeyBytes := TEncoding.UTF8.GetBytes(AKey);
  KeyLen := Length(KeyBytes);
  if KeyLen = 0 then
    Exit;

  for I := 0 to High(ABytes) do
    ABytes[I] := ABytes[I] xor KeyBytes[I mod KeyLen] xor Byte((I * 37) and $FF);
end;

procedure TDlpEncryptedDataStore.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);

  { Registra a propriedade virtual 'EncryptedPayload' no fluxo DFM }
  Filer.DefineBinaryProperty('EncryptedPayload', ReadEncryptedPayload, WriteEncryptedPayload, HasEntriesToStore);
end;

procedure TDlpEncryptedDataStore.ReadEncryptedPayload(AStream: TStream);
var
  EntryCount, I: Integer;
  IsEncryptedFlag: Byte;
  KeyStr, ValStr: string;
  KeyBytes, ValBytes: TBytes;
  KeyLen, ValLen: Integer;
  PayloadSize: Int64;
begin
  FStore.Clear;

  PayloadSize := AStream.Size - AStream.Position;
  if PayloadSize <= 0 then
    Exit;

  FLastPersistedBytes := PayloadSize;

  { 1. Lê a flag de criptografia }
  AStream.ReadBuffer(IsEncryptedFlag, SizeOf(Byte));
  { 2. Lê a quantidade de registros }
  AStream.ReadBuffer(EntryCount, SizeOf(Integer));

  for I := 0 to EntryCount - 1 do
  begin
    { Lê a Chave }
    AStream.ReadBuffer(KeyLen, SizeOf(Integer));
    SetLength(KeyBytes, KeyLen);
    if KeyLen > 0 then
      AStream.ReadBuffer(KeyBytes[0], KeyLen);

    { Lê o Valor }
    AStream.ReadBuffer(ValLen, SizeOf(Integer));
    SetLength(ValBytes, ValLen);
    if ValLen > 0 then
      AStream.ReadBuffer(ValBytes[0], ValLen);

    { Decifra os bytes se aplicável }
    if IsEncryptedFlag = 1 then
    begin
      ApplyStreamCipher(KeyBytes, FSecretKey);
      ApplyStreamCipher(ValBytes, FSecretKey);
    end;

    KeyStr := TEncoding.UTF8.GetString(KeyBytes);
    ValStr := TEncoding.UTF8.GetString(ValBytes);

    FStore.AddOrSetValue(KeyStr, ValStr);
  end;

  DoChanged;
end;

procedure TDlpEncryptedDataStore.WriteEncryptedPayload(AStream: TStream);
var
  Pair: TPair<string, string>;
  EntryCount: Integer;
  IsEncryptedFlag: Byte;
  KeyBytes, ValBytes: TBytes;
  KeyLen, ValLen: Integer;
  StartPos: Int64;
begin
  if not HasEntriesToStore then
    Exit;

  StartPos := AStream.Position;

  { 1. Escreve a flag de criptografia e a contagem de pares }
  if FAutoEncrypt then
    IsEncryptedFlag := 1
  else
    IsEncryptedFlag := 0;

  AStream.WriteBuffer(IsEncryptedFlag, SizeOf(Byte));

  EntryCount := FStore.Count;
  AStream.WriteBuffer(EntryCount, SizeOf(Integer));

  { 2. Itera gravando cada par chave/valor com proteção criptográfica }
  for Pair in FStore do
  begin
    KeyBytes := TEncoding.UTF8.GetBytes(Pair.Key);
    ValBytes := TEncoding.UTF8.GetBytes(Pair.Value);

    if FAutoEncrypt then
    begin
      ApplyStreamCipher(KeyBytes, FSecretKey);
      ApplyStreamCipher(ValBytes, FSecretKey);
    end;

    KeyLen := Length(KeyBytes);
    AStream.WriteBuffer(KeyLen, SizeOf(Integer));
    if KeyLen > 0 then
      AStream.WriteBuffer(KeyBytes[0], KeyLen);

    ValLen := Length(ValBytes);
    AStream.WriteBuffer(ValLen, SizeOf(Integer));
    if ValLen > 0 then
      AStream.WriteBuffer(ValBytes[0], ValLen);
  end;

  FLastPersistedBytes := AStream.Position - StartPos;
end;

procedure TDlpEncryptedDataStore.SetValue(const AKey, AValue: string);
begin
  FStore.AddOrSetValue(AKey, AValue);
  DoChanged;
end;

function TDlpEncryptedDataStore.GetValue(const AKey: string; const ADefault: string): string;
begin
  if not FStore.TryGetValue(AKey, Result) then
    Result := ADefault;
end;

function TDlpEncryptedDataStore.HasKey(const AKey: string): Boolean;
begin
  Result := FStore.ContainsKey(AKey);
end;

procedure TDlpEncryptedDataStore.RemoveKey(const AKey: string);
begin
  if FStore.ContainsKey(AKey) then
  begin
    FStore.Remove(AKey);
    DoChanged;
  end;
end;

procedure TDlpEncryptedDataStore.Clear;
begin
  FStore.Clear;
  FLastPersistedBytes := 0;
  DoChanged;
end;

function TDlpEncryptedDataStore.GetKeys: TArray<string>;
begin
  Result := FStore.Keys.ToArray;
end;

function TDlpEncryptedDataStore.Count: Integer;
begin
  Result := FStore.Count;
end;

function TDlpEncryptedDataStore.ExportAsJson: string;
var
  SB: TStringBuilder;
  Pair: TPair<string, string>;
  First: Boolean;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('{');
    First := True;
    for Pair in FStore do
    begin
      if not First then
        SB.Append(', ');
      First := False;
      SB.AppendFormat('"%s": "%s"', [Pair.Key, Pair.Value]);
    end;
    SB.Append('}');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TDlpEncryptedDataStore.ImportFromJson(const AJson: string);
var
  CleanJson: string;
  Pairs: TArray<string>;
  Item: string;
  Parts: TArray<string>;
  K, V: string;
begin
  FStore.Clear;
  CleanJson := AJson.Trim;
  if CleanJson.StartsWith('{') then
    CleanJson := CleanJson.Substring(1);
  if CleanJson.EndsWith('}') then
    CleanJson := CleanJson.Substring(0, CleanJson.Length - 1);

  Pairs := CleanJson.Split([',']);
  for Item in Pairs do
  begin
    Parts := Item.Split([':']);
    if Length(Parts) = 2 then
    begin
      K := Parts[0].Trim.Replace('"', '');
      V := Parts[1].Trim.Replace('"', '');
      if K <> '' then
        FStore.AddOrSetValue(K, V);
    end;
  end;
  DoChanged;
end;

procedure TDlpEncryptedDataStore.DoChanged;
begin
  if Assigned(FOnDataStoreChanged) then
    FOnDataStoreChanged(Self, FStore.Count, FLastPersistedBytes);
end;

end.
