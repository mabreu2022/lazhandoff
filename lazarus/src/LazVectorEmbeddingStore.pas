{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 44: Motor de Busca Vetorial e Embeddings (TLazVectorEmbeddingStore)
  Componente: TLazVectorEmbeddingStore
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Banco de dados vetorial em memória para busca semântica e RAG local
             (Retrieval-Augmented Generation). Armazena vetores densos de ponto
             flutuante (384 a 1536 dimensões), executa cálculo otimizado de
             similaridade por cosseno e retorna o ranking dos Top-K vizinhos mais
             próximos para cadastros de produtos, FAQs e bases de conhecimento.
==============================================================================}
unit LazVectorEmbeddingStore;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Math;

type
  { Vetor denso de dimensões de embeddings }
  TEmbeddingVector = array of Single;

  { Registro de um documento indexado no espaço vetorial }
  TVectorDocument = class
  public
    DocId: string;
    Title: string;
    Content: string;
    Vector: TEmbeddingVector;
    Magnitude: Single;
  end;

  { Resultado de uma busca por similaridade semântica }
  TSimilarityResult = record
    DocId: string;
    Title: string;
    Content: string;
    Score: Single; { 0.0 a 1.0 (onde 1.0 é identidade perfeita) }
  end;

  TSimilarityResultArray = array of TSimilarityResult;

  {============================================================================
    Componente: TLazVectorEmbeddingStore
    Motor vetorial de alta performance em memória
  ============================================================================}
  TLazVectorEmbeddingStore = class(TComponent)
  private
    FDimensions: Integer;
    FDocuments: TFPList;

    function ComputeMagnitude(const V: TEmbeddingVector): Single;
    function ComputeCosineSimilarity(const V1, V2: TEmbeddingVector; Mag1, Mag2: Single): Single;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Gestão de Documentos Vetoriais }
    procedure AddDocument(const ADocId, ATitle, AContent: string; const AVector: TEmbeddingVector);
    procedure Clear;
    function Count: Integer;

    { Busca Semântica Top-K }
    function SearchTopK(const AQueryVector: TEmbeddingVector; TopK: Integer = 5): TSimilarityResultArray;

    { Persistência Binária }
    procedure SaveToStream(AStream: TStream);
    procedure LoadFromStream(AStream: TStream);
  published
    property Dimensions: Integer read FDimensions write FDimensions default 384;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazVectorEmbeddingStore]);
end;

{ TLazVectorEmbeddingStore }

constructor TLazVectorEmbeddingStore.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDimensions := 384; { Dimensão padrão de modelos populares como all-MiniLM-L6-v2 }
  FDocuments := TFPList.Create;
end;

destructor TLazVectorEmbeddingStore.Destroy;
begin
  Clear;
  FDocuments.Free;
  inherited Destroy;
end;

procedure TLazVectorEmbeddingStore.Clear;
var
  i: Integer;
begin
  for i := 0 to FDocuments.Count - 1 do
    TVectorDocument(FDocuments[i]).Free;
  FDocuments.Clear;
end;

function TLazVectorEmbeddingStore.Count: Integer;
begin
  Result := FDocuments.Count;
end;

function TLazVectorEmbeddingStore.ComputeMagnitude(const V: TEmbeddingVector): Single;
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

function TLazVectorEmbeddingStore.ComputeCosineSimilarity(const V1, V2: TEmbeddingVector;
  Mag1, Mag2: Single): Single;
var
  Dot: Single;
  i, Len: Integer;
  Denominator: Single;
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

procedure TLazVectorEmbeddingStore.AddDocument(const ADocId, ATitle, AContent: string;
  const AVector: TEmbeddingVector);
var
  Doc: TVectorDocument;
  i: Integer;
begin
  Doc := TVectorDocument.Create;
  Doc.DocId := ADocId;
  Doc.Title := ATitle;
  Doc.Content := AContent;
  SetLength(Doc.Vector, Length(AVector));
  for i := 0 to High(AVector) do
    Doc.Vector[i] := AVector[i];

  Doc.Magnitude := ComputeMagnitude(Doc.Vector);
  FDocuments.Add(Doc);
end;

function TLazVectorEmbeddingStore.SearchTopK(const AQueryVector: TEmbeddingVector;
  TopK: Integer): TSimilarityResultArray;
var
  QueryMag: Single;
  Scores: array of Single;
  Indices: array of Integer;
  i, j, TotalDocs, BestIdx: Integer;
  Sim, TempScore: Single;
  TempIdx: Integer;
  Doc: TVectorDocument;
  MaxK: Integer;
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

  { 1. Calcula a similaridade por cosseno com todos os documentos indexados }
  for i := 0 to TotalDocs - 1 do
  begin
    Doc := TVectorDocument(FDocuments[i]);
    Sim := ComputeCosineSimilarity(AQueryVector, Doc.Vector, QueryMag, Doc.Magnitude);
    Scores[i] := Sim;
    Indices[i] := i;
  end;

  { 2. Seleção Top-K por ordenação parcial (Selection Sort eficiente para K pequeno) }
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

  { 3. Preenchimento do array de resultados }
  SetLength(Result, MaxK);
  for i := 0 to MaxK - 1 do
  begin
    Doc := TVectorDocument(FDocuments[Indices[i]]);
    Result[i].DocId := Doc.DocId;
    Result[i].Title := Doc.Title;
    Result[i].Content := Doc.Content;
    Result[i].Score := Scores[i];
  end;
end;

procedure TLazVectorEmbeddingStore.SaveToStream(AStream: TStream);
var
  i, DocCount, StrLen: Integer;
  Doc: TVectorDocument;
  Dim: Integer;
begin
  AStream.WriteBuffer('VECSTORE', 8);
  DocCount := FDocuments.Count;
  AStream.WriteBuffer(DocCount, SizeOf(Integer));
  AStream.WriteBuffer(FDimensions, SizeOf(Integer));

  for i := 0 to DocCount - 1 do
  begin
    Doc := TVectorDocument(FDocuments[i]);

    StrLen := Length(Doc.DocId);
    AStream.WriteBuffer(StrLen, SizeOf(Integer));
    AStream.WriteBuffer(Pointer(Doc.DocId)^, StrLen);

    StrLen := Length(Doc.Title);
    AStream.WriteBuffer(StrLen, SizeOf(Integer));
    AStream.WriteBuffer(Pointer(Doc.Title)^, StrLen);

    StrLen := Length(Doc.Content);
    AStream.WriteBuffer(StrLen, SizeOf(Integer));
    AStream.WriteBuffer(Pointer(Doc.Content)^, StrLen);

    Dim := Length(Doc.Vector);
    AStream.WriteBuffer(Dim, SizeOf(Integer));
    if Dim > 0 then
      AStream.WriteBuffer(Doc.Vector[0], Dim * SizeOf(Single));
  end;
end;

procedure TLazVectorEmbeddingStore.LoadFromStream(AStream: TStream);
var
  Sig: array[0..7] of Char;
  i, DocCount, StrLen, Dim: Integer;
  DocId, Title, Content: string;
  Vec: TEmbeddingVector;
begin
  Clear;
  AStream.ReadBuffer(Sig, 8);
  if Sig <> 'VECSTORE' then
    raise Exception.Create('Formato de base vetorial inválido.');

  AStream.ReadBuffer(DocCount, SizeOf(Integer));
  AStream.ReadBuffer(FDimensions, SizeOf(Integer));

  for i := 0 to DocCount - 1 do
  begin
    AStream.ReadBuffer(StrLen, SizeOf(Integer));
    SetLength(DocId, StrLen);
    AStream.ReadBuffer(Pointer(DocId)^, StrLen);

    AStream.ReadBuffer(StrLen, SizeOf(Integer));
    SetLength(Title, StrLen);
    AStream.ReadBuffer(Pointer(Title)^, StrLen);

    AStream.ReadBuffer(StrLen, SizeOf(Integer));
    SetLength(Content, StrLen);
    AStream.ReadBuffer(Pointer(Content)^, StrLen);

    AStream.ReadBuffer(Dim, SizeOf(Integer));
    SetLength(Vec, Dim);
    if Dim > 0 then
      AStream.ReadBuffer(Vec[0], Dim * SizeOf(Single));

    AddDocument(DocId, Title, Content, Vec);
  end;
end;

end.
