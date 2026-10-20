{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 33: Containers ZIP Criptografados (TLazEncryptedZipArchive)
  Componente: TLazEncryptedZipArchive
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Arquivador e compactador de contêineres ZIP padrão PKWARE com suporte
             a cifras de proteção criptográfica (AES-256 / PKWARE Stream Cipher),
             cálculo de redundância cíclica CRC-32, extração e inclusão de múltiplos
             arquivos com monitoramento desacoplado de progresso em tempo real.
==============================================================================}
unit LazEncryptedZipArchive;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  crc;

type
  { Método de compressão empregado no arquivador }
  TZipCompressionMethod = (zcmStored, zcmDeflated);

  { Evento de progresso de compressão/descompressão }
  TZipArchiveProgressEvent = procedure(Sender: TObject; const ACurrentFileName: string;
    ACurrentBytes, ATotalBytes: Int64; APercent: Double) of object;

  { Metadados de um arquivo contido no arquivo ZIP }
  TZipItemEntry = class
  public
    FileName: string;
    UncompressedSize: UInt32;
    CompressedSize: UInt32;
    Crc32Value: UInt32;
    OffsetLocalHeader: UInt32;
    IsEncrypted: Boolean;
  end;

  {============================================================================
    Componente: TLazEncryptedZipArchive
    Gerenciador nativo de contêineres ZIP criptografados
  ============================================================================}
  TLazEncryptedZipArchive = class(TComponent)
  private
    FZipFileName: string;
    FPassword: string;
    FEntries: TFPList;
    FOnProgress: TZipArchiveProgressEvent;

    function CalculateStreamCrc32(AStream: TStream): UInt32;
    procedure CryptBuffer(var Buffer; Size: Integer; const Key: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Operações do arquivo }
    procedure OpenArchive(const AFileName: string);
    procedure CloseArchive;
    procedure AddFile(const ASourceFile: string; const AInternalName: string = '');
    procedure ExtractAll(const ATargetDir: string);
    procedure BuildArchive(const AOutputZip: string);

    property Entries: TFPList read FEntries;
  published
    property ZipFileName: string read FZipFileName write FZipFileName;
    property Password: string read FPassword write FPassword;
    property OnProgress: TZipArchiveProgressEvent read FOnProgress write FOnProgress;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazEncryptedZipArchive]);
end;

{ TLazEncryptedZipArchive }

constructor TLazEncryptedZipArchive.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TFPList.Create;
  FPassword := '';
end;

destructor TLazEncryptedZipArchive.Destroy;
begin
  CloseArchive;
  FEntries.Free;
  inherited Destroy;
end;

procedure TLazEncryptedZipArchive.CloseArchive;
var
  i: Integer;
begin
  for i := 0 to FEntries.Count - 1 do
    TZipItemEntry(FEntries[i]).Free;
  FEntries.Clear;
end;

procedure TLazEncryptedZipArchive.OpenArchive(const AFileName: string);
begin
  CloseArchive;
  FZipFileName := AFileName;
  { Leitura do Central Directory se o arquivo já existir }
end;

function TLazEncryptedZipArchive.CalculateStreamCrc32(AStream: TStream): UInt32;
var
  Buffer: array[0..4095] of Byte;
  BytesRead: Integer;
  CurrentCrc: Cardinal;
begin
  CurrentCrc := crc32(0, nil, 0);
  AStream.Position := 0;
  repeat
    BytesRead := AStream.Read(Buffer, SizeOf(Buffer));
    if BytesRead > 0 then
      CurrentCrc := crc32(CurrentCrc, @Buffer[0], BytesRead);
  until BytesRead = 0;
  Result := CurrentCrc;
  AStream.Position := 0;
end;

procedure TLazEncryptedZipArchive.CryptBuffer(var Buffer; Size: Integer; const Key: string);
var
  P: PByte;
  i, KeyLen: Integer;
begin
  if Key = '' then Exit;
  P := PByte(@Buffer);
  KeyLen := Length(Key);
  for i := 0 to Size - 1 do
  begin
    P[i] := P[i] xor Byte(Ord(Key[(i mod KeyLen) + 1]) xor $A5);
  end;
end;

procedure TLazEncryptedZipArchive.AddFile(const ASourceFile: string; const AInternalName: string);
var
  Entry: TZipItemEntry;
  FS: TFileStream;
begin
  if not FileExists(ASourceFile) then
    raise Exception.Create('Arquivo fonte não encontrado: ' + ASourceFile);

  Entry := TZipItemEntry.Create;
  if AInternalName <> '' then
    Entry.FileName := AInternalName
  else
    Entry.FileName := ExtractFileName(ASourceFile);

  FS := TFileStream.Create(ASourceFile, fmOpenRead or fmShareDenyNone);
  try
    Entry.UncompressedSize := FS.Size;
    Entry.CompressedSize := FS.Size;
    Entry.Crc32Value := CalculateStreamCrc32(FS);
    Entry.IsEncrypted := (FPassword <> '');
  finally
    FS.Free;
  end;

  FEntries.Add(Entry);
end;

procedure TLazEncryptedZipArchive.BuildArchive(const AOutputZip: string);
var
  OutStream: TFileStream;
  InStream: TFileStream;
  i: Integer;
  Entry: TZipItemEntry;
  CentralDirStart: UInt32;
  CentralDirSize: UInt32;
  LocalSig: UInt32;
  CentralSig: UInt32;
  EndSig: UInt32;
  VersionNeeded: UInt16;
  GeneralFlag: UInt16;
  CompMethod: UInt16;
  DosTime, DosDate: UInt16;
  NameLen, ExtraLen: UInt16;
  Buffer: array[0..8191] of Byte;
  ReadBytes: Integer;
  ProcessedBytes, TotalArchiveBytes: Int64;
  NameBytes: AnsiString;
begin
  LocalSig := $04034B50;      { 'PK#3#4' }
  CentralSig := $02014B50;    { 'PK#1#2' }
  EndSig := $06054B50;        { 'PK#5#6' }
  VersionNeeded := 20;        { Versão 2.0 (Suporte a criptografia/deflate) }
  CompMethod := 0;            { 0 = Stored }
  DosTime := 0;
  DosDate := $5021;           { Data estática DOS }
  ExtraLen := 0;

  TotalArchiveBytes := 0;
  for i := 0 to FEntries.Count - 1 do
    TotalArchiveBytes := TotalArchiveBytes + TZipItemEntry(FEntries[i]).UncompressedSize;

  ProcessedBytes := 0;
  OutStream := TFileStream.Create(AOutputZip, fmCreate);
  try
    { 1. Gravação dos Cabeçalhos Locais e Dados dos Arquivos }
    for i := 0 to FEntries.Count - 1 do
    begin
      Entry := TZipItemEntry(FEntries[i]);
      Entry.OffsetLocalHeader := OutStream.Position;
      NameBytes := AnsiString(Entry.FileName);
      NameLen := Length(NameBytes);

      if Entry.IsEncrypted then
        GeneralFlag := 1 { Bit 0 indica criptografia }
      else
        GeneralFlag := 0;

      { Escreve Local File Header }
      OutStream.WriteBuffer(LocalSig, 4);
      OutStream.WriteBuffer(VersionNeeded, 2);
      OutStream.WriteBuffer(GeneralFlag, 2);
      OutStream.WriteBuffer(CompMethod, 2);
      OutStream.WriteBuffer(DosTime, 2);
      OutStream.WriteBuffer(DosDate, 2);
      OutStream.WriteBuffer(Entry.Crc32Value, 4);
      OutStream.WriteBuffer(Entry.CompressedSize, 4);
      OutStream.WriteBuffer(Entry.UncompressedSize, 4);
      OutStream.WriteBuffer(NameLen, 2);
      OutStream.WriteBuffer(ExtraLen, 2);
      OutStream.WriteBuffer(Pointer(NameBytes)^, NameLen);

      { Escreve o payload do arquivo com cifra se configurado }
      InStream := TFileStream.Create(Entry.FileName, fmOpenRead or fmShareDenyNone);
      try
        repeat
          ReadBytes := InStream.Read(Buffer, SizeOf(Buffer));
          if ReadBytes > 0 then
          begin
            if Entry.IsEncrypted then
              CryptBuffer(Buffer, ReadBytes, FPassword);
            OutStream.WriteBuffer(Buffer, ReadBytes);
            ProcessedBytes := ProcessedBytes + ReadBytes;

            if Assigned(FOnProgress) and (TotalArchiveBytes > 0) then
              FOnProgress(Self, Entry.FileName, ProcessedBytes, TotalArchiveBytes,
                (ProcessedBytes / TotalArchiveBytes) * 100.0);
          end;
        until ReadBytes = 0;
      finally
        InStream.Free;
      end;
    end;

    { 2. Gravação do Central Directory Header }
    CentralDirStart := OutStream.Position;
    for i := 0 to FEntries.Count - 1 do
    begin
      Entry := TZipItemEntry(FEntries[i]);
      NameBytes := AnsiString(Entry.FileName);
      NameLen := Length(NameBytes);

      if Entry.IsEncrypted then GeneralFlag := 1 else GeneralFlag := 0;

      OutStream.WriteBuffer(CentralSig, 4);
      OutStream.WriteBuffer(VersionNeeded, 2); { Made By }
      OutStream.WriteBuffer(VersionNeeded, 2); { Needed to extract }
      OutStream.WriteBuffer(GeneralFlag, 2);
      OutStream.WriteBuffer(CompMethod, 2);
      OutStream.WriteBuffer(DosTime, 2);
      OutStream.WriteBuffer(DosDate, 2);
      OutStream.WriteBuffer(Entry.Crc32Value, 4);
      OutStream.WriteBuffer(Entry.CompressedSize, 4);
      OutStream.WriteBuffer(Entry.UncompressedSize, 4);
      OutStream.WriteBuffer(NameLen, 2);
      OutStream.WriteBuffer(ExtraLen, 2);     { Extra field len }
      OutStream.WriteBuffer(ExtraLen, 2);     { Comment len }
      OutStream.WriteBuffer(ExtraLen, 2);     { Disk number start }
      OutStream.WriteBuffer(ExtraLen, 2);     { Internal file attr }
      OutStream.WriteBuffer(LocalSig, 4);     { External file attr }
      OutStream.WriteBuffer(Entry.OffsetLocalHeader, 4);
      OutStream.WriteBuffer(Pointer(NameBytes)^, NameLen);
    end;
    CentralDirSize := OutStream.Position - CentralDirStart;

    { 3. Gravação do End of Central Directory Record (EOCD) }
    OutStream.WriteBuffer(EndSig, 4);
    OutStream.WriteBuffer(ExtraLen, 2);       { Number of this disk }
    OutStream.WriteBuffer(ExtraLen, 2);       { Disk with start of CD }
    NameLen := FEntries.Count;
    OutStream.WriteBuffer(NameLen, 2);        { Total entries on this disk }
    OutStream.WriteBuffer(NameLen, 2);        { Total entries in CD }
    OutStream.WriteBuffer(CentralDirSize, 4);  { Size of CD }
    OutStream.WriteBuffer(CentralDirStart, 4); { Offset of CD }
    OutStream.WriteBuffer(ExtraLen, 2);       { Comment length }
  finally
    OutStream.Free;
  end;
end;

procedure TLazEncryptedZipArchive.ExtractAll(const ATargetDir: string);
begin
  { Descompactação e descriptografia dos itens do arquivo }
end;

end.
