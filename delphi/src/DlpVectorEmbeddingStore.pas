{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 44: Motor de Busca Vetorial e Embeddings (TDlpVectorEmbeddingStore)
  Componente: TDlpVectorEmbeddingStore
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / macOS)
  Descrição: Banco de dados vetorial de alta densidade em memória para busca semântica
             e arquiteturas RAG (Retrieval-Augmented Generation). Suporta embeddings
             de 384 a 1536 dimensões, produto escalar com normalização de módulo,
             similaridade por cosseno e ranking Top-K acelerado para catálogo
             de produtos e atendimento inteligente.
==============================================================================}
unit DlpVectorEmbeddingStore;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math;

type
  { Vetor denso de dimensões de embeddings }
  TDlpEmbeddingVector = TArray<Single>;

  { Documento indexado na base vetorial }
  TDlpVectorDocument = class
  public
    DocId: string;
    Title: string;
    Content: string;
    Vector: TDlpEmbeddingVector;
    Magnitude: Single;
  end;

  { Resultado de similaridade semântica }
  TDlpSimilarityResult = record
    DocId: string;
    Title: string;
    Content: string;
    Score: Single;
  end;

  TDlpSimilarityResultArray = TArray<TDlpSimilarityResult>;

  {============================================================================
    Componente: TDlpVectorEmbeddingStore
    Banco de dados vetorial em memória para Object Pascal
  ============================================================================}
  TDlpVectorEmbeddingStore = class(TComponent)
  private
    FDimensions: Integer;
    FDocuments: TList;

    function ComputeMagnitude(const V: TDlpEmbeddingVector): Single;
    function ComputeCosineSimilarity(const V1, V2: TDlpEmbeddingVector; Mag1, Mag2: Single): Single;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddDocument(const ADocId, ATitle, AContent: string; const AVector: TDlpEmbeddingVector);
    procedure Clear;
    function Count: Integer;

    function SearchTopK(const AQueryVector: TDlpEmbeddingVector; TopK: Integer = 5): TDlpSimilarityResultArray;

    procedure SaveToStream(AStream: TStream);
    procedure LoadFromStream(AStream: TStream);
  published
    property Dimensions: Integer read FDimensions write FDimensions default 384;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpVectorEmbeddingStore]);
end;

{ TDlpVectorEmbeddingStore }

constructor TDlpVectorEmbeddingStore.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDimensions := 384;
  FDocuments := TList.Create;
end;

destructor TDlpVectorEmbeddingStore.Destroy;
begin
  Clear;
  FDocuments.Free;
  inherited Destroy;
end;

procedure TDlpVectorEmbeddingStore.Clear;
var
  i: Integer;
begin
  for i := 0 to FDocuments.Count - 1 do
    TDlpVectorDocument(FDocuments[i]).Free;
  FDocuments.Clear;
end;

function TDlpVectorEmbeddingStore.Count: Integer;
begin
  Result := FDocuments.Count;
end;

function TDlpVectorEmbeddingStore.ComputeMagnitude(const V: TDlpEmbeddingVector): Single;
var
  SumSq: Single;
  i, Len: Integer;
begin
  SumSq := 0.0;
  Len := Length(V);
  for i := 0 to Len - 1 do
    SumSq := SumSq + (V[i] * V[i]);
  Result := Sqrt(SumSq);
end;

function TDlpVectorEmbeddingStore.ComputeCosineSimilarity(const V1, V2: TDlpEmbeddingVector;
  Mag1, Mag2: Single): Single;
var
  Dot, Denominator: Single;
  i, Len: Integer;
begin
  Len := Length(V1);
  if (Len <> Length(V2)) or (Len = 0) then Exit(0.0);

  Dot := 0.0;
  for i := 0 to Len - 1 do
    Dot := Dot + (V1[i] * V2[i]);

  Denominator := Mag1 * Mag2;
  if Denominator > 0.000001 then
    Result := Dot / Denominator
  else
    Result := 0.0;
end;

procedure TDlpVectorEmbeddingStore.AddDocument(const ADocId, ATitle, AContent: string;
  const AVector: TDlpEmbeddingVector);
var
  Doc: TDlpVectorDocument;
  i: Integer;
begin
  Doc := TDlpVectorDocument.Create;
  Doc.DocId := ADocId;
  Doc.Title := ATitle;
  Doc.Content := AContent;
  SetLength(Doc.Vector, Length(AVector));
  for i := 0 to High(AVector) do
    Doc.Vector[i] := AVector[i];

  Doc.Magnitude := ComputeMagnitude(Doc.Vector);
  FDocuments.Add(Doc);
end;

function TDlpVectorEmbeddingStore.SearchTopK(const AQueryVector: TDlpEmbeddingVector;
  TopK: Integer): TDlpSimilarityResultArray;
var
  QueryMag: Single;
  Scores: TArray<Single>;
  Indices: TArray<Integer>;
  i, j, TotalDocs, BestIdx: Integer;
  Sim, TempScore: Single;
  TempIdx, MaxK: Integer;
  Doc: TDlpVectorDocument;
begin
  TotalDocs := FDocuments.Count;
  if TotalDocs = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  QueryMag := ComputeMagnitude(AQueryVector);
  SetLength(Scores, TotalDocs);
  SetLength(Indices, TotalDocs);

  for i := 0 to TotalDocs - 1 do
  begin
    Doc := TDlpVectorDocument(FDocuments[i]);
    Sim := ComputeCosineSimilarity(AQueryVector, Doc.Vector, QueryMag, Doc.Magnitude);
    Scores[i] := Sim;
    Indices[i] := i;
  end;

  MaxK := Min(TopK, TotalDocs);
  for i := 0 to MaxK - 1 do
  begin
    BestIdx := i;
    for j := i + 1 to TotalDocs - 1 do
    begin
      if Scores[j] > Scores[BestIdx] then
        BestIdx := j;
    end;

    if BestIdx <> i then
    begin
      TempScore := Scores[i];
      Scores[i] := Scores[BestIdx];
      Scores[BestIdx] := TempScore;

      TempIdx := Indices[i];
      Indices[i] := Indices[BestIdx];
      Indices[BestIdx] := TempIdx;
    end;
  end;

  SetLength(Result, MaxK);
  for i := 0 to MaxK - 1 do
  begin
    Doc := TDlpVectorDocument(FDocuments[Indices[i]]);
    Result[i].DocId := Doc.DocId;
    Result[i].Title := Doc.Title;
    Result[i].Content := Doc.Content;
    Result[i].Score := Scores[i];
  end;
end;

procedure TDlpVectorEmbeddingStore.SaveToStream(AStream: TStream);
var
  i, DocCount, StrLen, Dim: Integer;
  Doc: TDlpVectorDocument;
  StrBytes: TBytes;
  Sig: AnsiString;
begin
  Sig := 'VECSTORE';
  AStream.WriteBuffer(Pointer(Sig)^, 8);
  DocCount := FDocuments.Count;
  AStream.WriteBuffer(DocCount, SizeOf(Integer));
  AStream.WriteBuffer(FDimensions, SizeOf(Integer));

  for i := 0 to DocCount - 1 do
  begin
    Doc := TDlpVectorDocument(FDocuments[i]);

    StrBytes := TEncoding.UTF8.GetBytes(Doc.DocId);
    StrLen := Length(StrBytes);
    AStream.WriteBuffer(StrLen, SizeOf(Integer));
    AStream.WriteBuffer(Pointer(StrBytes)^, StrLen);

    StrBytes := TEncoding.UTF8.GetBytes(Doc.Title);
    StrLen := Length(StrBytes);
    AStream.WriteBuffer(StrLen, SizeOf(Integer));
    AStream.WriteBuffer(Pointer(StrBytes)^, StrLen);

    StrBytes := TEncoding.UTF8.GetBytes(Doc.Content);
    StrLen := Length(StrBytes);
    AStream.WriteBuffer(StrLen, SizeOf(Integer));
    AStream.WriteBuffer(Pointer(StrBytes)^, StrLen);

    Dim := Length(Doc.Vector);
    AStream.WriteBuffer(Dim, SizeOf(Integer));
    if Dim > 0 then
      AStream.WriteBuffer(Doc.Vector[0], Dim * SizeOf(Single));
  end;
end;

procedure TDlpVectorEmbeddingStore.LoadFromStream(AStream: TStream);
var
  Sig: array[0..7] of AnsiChar;
  i, DocCount, StrLen, Dim: Integer;
  DocId, Title, Content: string;
  StrBytes: TBytes;
  Vec: TDlpEmbeddingVector;
begin
  Clear;
  AStream.ReadBuffer(Sig, 8);
  if Sig <> 'VECSTORE' then
    raise Exception.Create('Assinatura do arquivo vetorial invalida.');

  AStream.ReadBuffer(DocCount, SizeOf(Integer));
  AStream.ReadBuffer(FDimensions, SizeOf(Integer));

  for i := 0 to DocCount - 1 do
  begin
    AStream.ReadBuffer(StrLen, SizeOf(Integer));
    SetLength(StrBytes, StrLen);
    AStream.ReadBuffer(Pointer(StrBytes)^, StrLen);
    DocId := TEncoding.UTF8.GetString(StrBytes);

    AStream.ReadBuffer(StrLen, SizeOf(Integer));
    SetLength(StrBytes, StrLen);
    AStream.ReadBuffer(Pointer(StrBytes)^, StrLen);
    Title := TEncoding.UTF8.GetString(StrBytes);

    AStream.ReadBuffer(StrLen, SizeOf(Integer));
    SetLength(StrBytes, StrLen);
    AStream.ReadBuffer(Pointer(StrBytes)^, StrLen);
    Content := TEncoding.UTF8.GetString(StrBytes);

    AStream.ReadBuffer(Dim, SizeOf(Integer));
    SetLength(Vec, Dim);
    if Dim > 0 then
      AStream.ReadBuffer(Vec[0], Dim * SizeOf(Single));

    AddDocument(DocId, Title, Content, Vec);
  end;
end;

end.
