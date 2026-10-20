{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 03: Mecanismo de Streaming e Persistência (LFM)
  Componente: TLazBinaryBlobContainer
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Componente não-visual que demonstra a implementação profunda de
             streaming customizado no arquivo .lfm utilizando o subsistema
             TFiler, TReader, TWriter, DefineProperties e compressão zlib nativa.
==============================================================================}
unit LazBinaryBlobContainer;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  zstream;

type
  { Modo de compressão para persistência do blob no LFM }
  TLazBlobCompressionMode = (
    bcmNone,        // Salva os bytes puros
    bcmZLibFast,    // Compressão rápida
    bcmZLibMax      // Compressão máxima
  );

  { Evento disparado quando o blob é atualizado ou desserializado do LFM }
  TOnBlobDataChanged = procedure(Sender: TObject; ADataSize: Int64;
    ACompressedSize: Int64) of object;

  {============================================================================
    Classe: TLazBinaryBlobContainer
    Componente não-visual que implementa DefineProperties para persistência
    customizada de payloads binários compactados no arquivo de formulário .lfm.
  ============================================================================}
  TLazBinaryBlobContainer = class(TComponent)
  private
    FRawDataStream: TMemoryStream;
    FDescription: string;
    FCompressionMode: TLazBlobCompressionMode;
    FLastDecompressedSize: Int64;
    FLastPersistedSize: Int64;
    FOnBlobDataChanged: TOnBlobDataChanged;

    procedure SetDescription(const AValue: string);
    procedure SetCompressionMode(const AValue: TLazBlobCompressionMode);
    function HasDataToStore: Boolean;

    { Métodos assessores de streaming para o TFiler }
    procedure ReadBlobData(AStream: TStream);
    procedure WriteBlobData(AStream: TStream);
  protected
    { Ponto de entrada canônico da RTL para persistência customizada }
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoBlobDataChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Manipulação do payload binário em tempo de execução }
    procedure Clear;
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToStream(AStream: TStream);
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    procedure SetDataAsString(const AContent: string);
    function GetDataAsString: string;

    { Métricas do payload }
    property RawDataSize: Int64 read FLastDecompressedSize;
    property PersistedSize: Int64 read FLastPersistedSize;
  published
    property Description: string read FDescription write SetDescription;
    property CompressionMode: TLazBlobCompressionMode read FCompressionMode write SetCompressionMode default bcmZLibMax;
    property OnBlobDataChanged: TOnBlobDataChanged read FOnBlobDataChanged write FOnBlobDataChanged;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazBinaryBlobContainer]);
end;

{ TLazBinaryBlobContainer }

constructor TLazBinaryBlobContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRawDataStream := TMemoryStream.Create;
  FDescription := 'Binary Blob Container';
  FCompressionMode := bcmZLibMax;
  FLastDecompressedSize := 0;
  FLastPersistedSize := 0;
end;

destructor TLazBinaryBlobContainer.Destroy;
begin
  FreeAndNil(FRawDataStream);
  inherited Destroy;
end;

procedure TLazBinaryBlobContainer.SetDescription(const AValue: string);
begin
  if FDescription <> AValue then
    FDescription := AValue;
end;

procedure TLazBinaryBlobContainer.SetCompressionMode(const AValue: TLazBlobCompressionMode);
begin
  if FCompressionMode <> AValue then
    FCompressionMode := AValue;
end;

function TLazBinaryBlobContainer.HasDataToStore: Boolean;
begin
  Result := Assigned(FRawDataStream) and (FRawDataStream.Size > 0);
end;

procedure TLazBinaryBlobContainer.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);

  { Define a propriedade virtual binária 'CustomBlobPayload' no arquivo .lfm }
  Filer.DefineBinaryProperty('CustomBlobPayload', @ReadBlobData, @WriteBlobData, HasDataToStore);
end;

procedure TLazBinaryBlobContainer.ReadBlobData(AStream: TStream);
var
  ModeByte: Byte;
  OrigSize: Int64;
  Decompressor: TDecompressionStream;
  Buffer: array[0..4095] of Byte;
  BytesRead: Integer;
begin
  FRawDataStream.Clear;

  if AStream.Size = 0 then
    Exit;

  { 1. Lê o byte de cabeçalho com o modo de compressão original }
  AStream.ReadBuffer(ModeByte, SizeOf(Byte));
  { 2. Lê o tamanho original descomprimido }
  AStream.ReadBuffer(OrigSize, SizeOf(Int64));

  FLastDecompressedSize := OrigSize;
  FLastPersistedSize := AStream.Size;

  case TLazBlobCompressionMode(ModeByte) of
    bcmNone:
      begin
        { Carrega os dados diretamente sem descompressão }
        FRawDataStream.CopyFrom(AStream, AStream.Size - AStream.Position);
      end;

    bcmZLibFast, bcmZLibMax:
      begin
        { Descomprime o payload utilizando zstream nativo do FPC }
        Decompressor := TDecompressionStream.Create(AStream);
        try
          repeat
            BytesRead := Decompressor.Read(Buffer, SizeOf(Buffer));
            if BytesRead > 0 then
              FRawDataStream.WriteBuffer(Buffer, BytesRead);
          until BytesRead = 0;
        finally
          Decompressor.Free;
        end;
      end;
  end;

  FRawDataStream.Position := 0;
  DoBlobDataChanged;
end;

procedure TLazBinaryBlobContainer.WriteBlobData(AStream: TStream);
var
  ModeByte: Byte;
  OrigSize: Int64;
  Compressor: TCompressionStream;
  ZLevel: Tcompressionlevel;
  StartPos: Int64;
begin
  if not HasDataToStore then
    Exit;

  StartPos := AStream.Position;

  { 1. Escreve cabeçalho: Modo de Compressão e Tamanho Original }
  ModeByte := Byte(FCompressionMode);
  AStream.WriteBuffer(ModeByte, SizeOf(Byte));

  OrigSize := FRawDataStream.Size;
  AStream.WriteBuffer(OrigSize, SizeOf(Int64));

  FRawDataStream.Position := 0;

  case FCompressionMode of
    bcmNone:
      begin
        AStream.CopyFrom(FRawDataStream, FRawDataStream.Size);
      end;

    bcmZLibFast, bcmZLibMax:
      begin
        if FCompressionMode = bcmZLibFast then
          ZLevel := clfastest
        else
          ZLevel := clmax;

        { Comprime o payload binário gravando diretamente no fluxo de saída do LFM }
        Compressor := TCompressionStream.Create(ZLevel, AStream);
        try
          Compressor.CopyFrom(FRawDataStream, FRawDataStream.Size);
        finally
          Compressor.Free;
        end;
      end;
  end;

  FLastDecompressedSize := OrigSize;
  FLastPersistedSize := AStream.Position - StartPos;
  FRawDataStream.Position := 0;
end;

procedure TLazBinaryBlobContainer.Clear;
begin
  FRawDataStream.Clear;
  FLastDecompressedSize := 0;
  FLastPersistedSize := 0;
  DoBlobDataChanged;
end;

procedure TLazBinaryBlobContainer.LoadFromStream(AStream: TStream);
begin
  FRawDataStream.Clear;
  if Assigned(AStream) and (AStream.Size > 0) then
  begin
    AStream.Position := 0;
    FRawDataStream.CopyFrom(AStream, AStream.Size);
    FRawDataStream.Position := 0;
    FLastDecompressedSize := FRawDataStream.Size;
    FLastPersistedSize := 0;
  end;
  DoBlobDataChanged;
end;

procedure TLazBinaryBlobContainer.SaveToStream(AStream: TStream);
begin
  if Assigned(AStream) and (FRawDataStream.Size > 0) then
  begin
    FRawDataStream.Position := 0;
    AStream.CopyFrom(FRawDataStream, FRawDataStream.Size);
    FRawDataStream.Position := 0;
  end;
end;

procedure TLazBinaryBlobContainer.LoadFromFile(const AFileName: string);
var
  FS: TFileStream;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Arquivo não encontrado para carga de blob: %s', [AFileName]);

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TLazBinaryBlobContainer.SaveToFile(const AFileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TLazBinaryBlobContainer.SetDataAsString(const AContent: string);
var
  SS: TStringStream;
begin
  SS := TStringStream.Create(AContent);
  try
    LoadFromStream(SS);
  finally
    SS.Free;
  end;
end;

function TLazBinaryBlobContainer.GetDataAsString: string;
var
  SS: TStringStream;
begin
  if FRawDataStream.Size = 0 then
    Exit('');

  SS := TStringStream.Create('');
  try
    SaveToStream(SS);
    Result := SS.DataString;
  finally
    SS.Free;
  end;
end;

procedure TLazBinaryBlobContainer.DoBlobDataChanged;
begin
  if Assigned(FOnBlobDataChanged) then
    FOnBlobDataChanged(Self, FLastDecompressedSize, FLastPersistedSize);
end;

end.
