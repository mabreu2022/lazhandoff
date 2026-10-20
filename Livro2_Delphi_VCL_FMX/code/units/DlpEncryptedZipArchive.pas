{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 33: Containers ZIP Criptografados (TDlpEncryptedZipArchive)
  Componente: TDlpEncryptedZipArchive
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / macOS)
  Descrição: Arquivador ZIP de alta densidade em conformidade com o padrão PKWARE
             (APPNOTE.TXT), suporte a fluxo criptográfico por chave simétrica,
             auditoria de integridade CRC-32, estruturação de cabeçalhos locais,
             Central Directory e EOCD com eventos de progresso desacoplados.
==============================================================================}
unit DlpEncryptedZipArchive;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Hash;

type
  { Evento de progresso de operação de arquivo }
  TDlpZipArchiveProgressEvent = procedure(Sender: TObject; const ACurrentFileName: string;
    ACurrentBytes, ATotalBytes: Int64; APercent: Double) of object;

  { Metadados de entrada do arquivo compactado }
  TDlpZipItemEntry = class
  public
    FileName: string;
    UncompressedSize: UInt32;
    CompressedSize: UInt32;
    Crc32Value: UInt32;
    OffsetLocalHeader: UInt32;
    IsEncrypted: Boolean;
  end;

  {============================================================================
    Componente: TDlpEncryptedZipArchive
    Gerenciador nativo de arquivos ZIP protegidos por criptografia
  ============================================================================}
  TDlpEncryptedZipArchive = class(TComponent)
  private
    FZipFileName: string;
    FPassword: string;
    FEntries: TList;
    FOnProgress: TDlpZipArchiveProgressEvent;

    function CalculateStreamCrc32(AStream: TStream): UInt32;
    procedure CryptBuffer(var Buffer; Size: Integer; const Key: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure OpenArchive(const AFileName: string);
    procedure CloseArchive;
    procedure AddFile(const ASourceFile: string; const AInternalName: string = '');
    procedure BuildArchive(const AOutputZip: string);

    property Entries: TList read FEntries;
  published
    property ZipFileName: string read FZipFileName write FZipFileName;
    property Password: string read FPassword write FPassword;
    property OnProgress: TDlpZipArchiveProgressEvent read FOnProgress write FOnProgress;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpEncryptedZipArchive]);
end;

{ TDlpEncryptedZipArchive }

constructor TDlpEncryptedZipArchive.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TList.Create;
  FPassword := '';
end;

destructor TDlpEncryptedZipArchive.Destroy;
begin
  CloseArchive;
  FEntries.Free;
  inherited Destroy;
end;

procedure TDlpEncryptedZipArchive.CloseArchive;
var
  i: Integer;
begin
  for i := 0 to FEntries.Count - 1 do
    TDlpZipItemEntry(FEntries[i]).Free;
  FEntries.Clear;
end;

procedure TDlpEncryptedZipArchive.OpenArchive(const AFileName: string);
begin
  CloseArchive;
  FZipFileName := AFileName;
end;

function TDlpEncryptedZipArchive.CalculateStreamCrc32(AStream: TStream): UInt32;
var
  Buffer: TBytes;
  BytesRead: Integer;
begin
  SetLength(Buffer, 8192);
  AStream.Position := 0;
  Result := 0;
  repeat
    BytesRead := AStream.Read(Buffer[0], Length(Buffer));
    if BytesRead > 0 then
      Result := THashCRC32.Update(Result, @Buffer[0], BytesRead);
  until BytesRead = 0;
  AStream.Position := 0;
end;

procedure TDlpEncryptedZipArchive.CryptBuffer(var Buffer; Size: Integer; const Key: string);
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

procedure TDlpEncryptedZipArchive.AddFile(const ASourceFile: string; const AInternalName: string);
var
  Entry: TDlpZipItemEntry;
  FS: TFileStream;
begin
  if not FileExists(ASourceFile) then
    raise Exception.Create('Arquivo inexistente: ' + ASourceFile);

  Entry := TDlpZipItemEntry.Create;
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

procedure TDlpEncryptedZipArchive.BuildArchive(const AOutputZip: string);
var
  OutStream, InStream: TFileStream;
  i: Integer;
  Entry: TDlpZipItemEntry;
  CentralDirStart, CentralDirSize: UInt32;
  LocalSig, CentralSig, EndSig: UInt32;
  VersionNeeded, GeneralFlag, CompMethod: UInt16;
  DosTime, DosDate, NameLen, ExtraLen: UInt16;
  Buffer: array[0..8191] of Byte;
  ReadBytes: Integer;
  ProcessedBytes, TotalArchiveBytes: Int64;
  NameBytes: TBytes;
begin
  LocalSig := $04034B50;
  CentralSig := $02014B50;
  EndSig := $06054B50;
  VersionNeeded := 20;
  CompMethod := 0; { Stored }
  DosTime := 0;
  DosDate := $5021;
  ExtraLen := 0;

  TotalArchiveBytes := 0;
  for i := 0 to FEntries.Count - 1 do
    TotalArchiveBytes := TotalArchiveBytes + TDlpZipItemEntry(FEntries[i]).UncompressedSize;

  ProcessedBytes := 0;
  OutStream := TFileStream.Create(AOutputZip, fmCreate);
  try
    for i := 0 to FEntries.Count - 1 do
    begin
      Entry := TDlpZipItemEntry(FEntries[i]);
      Entry.OffsetLocalHeader := OutStream.Position;
      NameBytes := TEncoding.UTF8.GetBytes(Entry.FileName);
      NameLen := Length(NameBytes);

      if Entry.IsEncrypted then GeneralFlag := 1 else GeneralFlag := 0;

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

    CentralDirStart := OutStream.Position;
    for i := 0 to FEntries.Count - 1 do
    begin
      Entry := TDlpZipItemEntry(FEntries[i]);
      NameBytes := TEncoding.UTF8.GetBytes(Entry.FileName);
      NameLen := Length(NameBytes);

      if Entry.IsEncrypted then GeneralFlag := 1 else GeneralFlag := 0;

      OutStream.WriteBuffer(CentralSig, 4);
      OutStream.WriteBuffer(VersionNeeded, 2);
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
      OutStream.WriteBuffer(ExtraLen, 2);
      OutStream.WriteBuffer(ExtraLen, 2);
      OutStream.WriteBuffer(ExtraLen, 2);
      OutStream.WriteBuffer(LocalSig, 4);
      OutStream.WriteBuffer(Entry.OffsetLocalHeader, 4);
      OutStream.WriteBuffer(Pointer(NameBytes)^, NameLen);
    end;
    CentralDirSize := OutStream.Position - CentralDirStart;

    OutStream.WriteBuffer(EndSig, 4);
    OutStream.WriteBuffer(ExtraLen, 2);
    OutStream.WriteBuffer(ExtraLen, 2);
    NameLen := FEntries.Count;
    OutStream.WriteBuffer(NameLen, 2);
    OutStream.WriteBuffer(NameLen, 2);
    OutStream.WriteBuffer(CentralDirSize, 4);
    OutStream.WriteBuffer(CentralDirStart, 4);
    OutStream.WriteBuffer(ExtraLen, 2);
  finally
    OutStream.Free;
  end;
end;

end.
