{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 43: Parser de Respostas Estruturadas JSON (TLazAiStructuredExtractor)
  Componente: TLazAiStructuredExtractor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Extrator e sanitizador de saídas estruturadas de Inteligência Artificial.
             Elimina formatação Markdown envolvente (code fences ```json), repara
             inconsistências comuns de LLMs (vírgulas pendentes, aspas simples)
             e hidrata registros e classes Object Pascal com tipagem estrita.
==============================================================================}
unit LazAiStructuredExtractor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  { Resultado estruturado de análise de sentimento e intenção }
  TCustomerIntentRecord = record
    Intent: string;
    Confidence: Double;
    Sentiment: string;
    NeedsHumanAgent: Boolean;
    Summary: string;
    ExtractedEntities: TStringList;
  end;

  {============================================================================
    Componente: TLazAiStructuredExtractor
    Parser e higienizador de JSON emitido por LLMs
  ============================================================================}
  TLazAiStructuredExtractor = class(TComponent)
  private
    FStrictValidation: Boolean;

    function CleanMarkdownFences(const RawText: string): string;
    function RepairJsonSyntax(const CleanJson: string): string;
    function ExtractField(const Json, FieldName: string): string;
    function ExtractBoolField(const Json, FieldName: string): Boolean;
    function ExtractFloatField(const Json, FieldName: string): Double;
  public
    constructor Create(AOwner: TComponent); override;

    { Extração e tipagem }
    function SanitizeAiJson(const RawAiOutput: string): string;
    function ParseCustomerIntent(const RawAiOutput: string): TCustomerIntentRecord;
    function TryExtractKeyValue(const RawAiOutput, Key: string; out Value: string): Boolean;
  published
    property StrictValidation: Boolean read FStrictValidation write FStrictValidation default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazAiStructuredExtractor]);
end;

{ TLazAiStructuredExtractor }

constructor TLazAiStructuredExtractor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStrictValidation := False;
end;

function TLazAiStructuredExtractor.CleanMarkdownFences(const RawText: string): string;
var
  PStart, PEnd: Integer;
  S: string;
begin
  S := RawText;
  { Remove delimitadores ```json ... ``` ou ``` ... ``` }
  PStart := Pos('```json', S);
  if PStart > 0 then
    PStart := PStart + 7
  else
  begin
    PStart := Pos('```', S);
    if PStart > 0 then
      PStart := PStart + 3;
  end;

  if PStart > 0 then
  begin
    PEnd := Pos('```', Copy(S, PStart, Length(S)));
    if PEnd > 0 then
      S := Copy(S, PStart, PEnd - 1)
    else
      S := Copy(S, PStart, Length(S));
  end;

  { Localiza a primeira abertura de chave '{' e o último fechamento '}' }
  PStart := Pos('{', S);
  if PStart > 0 then
  begin
    for PEnd := Length(S) downto PStart do
    begin
      if S[PEnd] = '}' then
      begin
        Result := Trim(Copy(S, PStart, PEnd - PStart + 1));
        Exit;
      end;
    end;
  end;

  Result := Trim(S);
end;

function TLazAiStructuredExtractor.RepairJsonSyntax(const CleanJson: string): string;
var
  S: string;
begin
  S := CleanJson;
  { Substituição de aspas simples externas por aspas duplas padrão JSON }
  S := StringReplace(S, #39, '"', [rfReplaceAll]);

  { Correção de vírgulas trailing antes de fechar chaves }
  S := StringReplace(S, ', }', '}', [rfReplaceAll]);
  S := StringReplace(S, ',}', '}', [rfReplaceAll]);
  S := StringReplace(S, ', ]', ']', [rfReplaceAll]);
  S := StringReplace(S, ',]', ']', [rfReplaceAll]);

  Result := S;
end;

function TLazAiStructuredExtractor.SanitizeAiJson(const RawAiOutput: string): string;
begin
  Result := RepairJsonSyntax(CleanMarkdownFences(RawAiOutput));
end;

function TLazAiStructuredExtractor.ExtractField(const Json, FieldName: string): string;
var
  P, PEnd: Integer;
  Target: string;
begin
  Target := '"' + FieldName + '":';
  P := Pos(Target, Json);
  if P = 0 then Exit('');

  P := P + Length(Target);
  while (P <= Length(Json)) and (Json[P] = ' ') do Inc(P);

  if (P <= Length(Json)) and (Json[P] = '"') then
  begin
    Inc(P);
    PEnd := P;
    while (PEnd <= Length(Json)) and (Json[PEnd] <> '"') do
    begin
      if (Json[PEnd] = '\') and (PEnd < Length(Json)) then
        Inc(PEnd, 2)
      else
        Inc(PEnd);
    end;
    Result := Copy(Json, P, PEnd - P);
  end
  else
  begin
    PEnd := P;
    while (PEnd <= Length(Json)) and not (Json[PEnd] in [',', '}', #10, #13, ' ']) do Inc(PEnd);
    Result := Copy(Json, P, PEnd - P);
  end;
end;

function TLazAiStructuredExtractor.ExtractBoolField(const Json, FieldName: string): Boolean;
var
  V: string;
begin
  V := LowerCase(Trim(ExtractField(Json, FieldName)));
  Result := (V = 'true') or (V = '1') or (V = 'yes');
end;

function TLazAiStructuredExtractor.ExtractFloatField(const Json, FieldName: string): Double;
var
  V: string;
begin
  V := Trim(ExtractField(Json, FieldName));
  V := StringReplace(V, ',', '.', [rfReplaceAll]);
  Result := StrToFloatDef(V, 0.0);
end;

function TLazAiStructuredExtractor.ParseCustomerIntent(const RawAiOutput: string): TCustomerIntentRecord;
var
  CleanJson: string;
begin
  CleanJson := SanitizeAiJson(RawAiOutput);

  Result.Intent := ExtractField(CleanJson, 'intent');
  Result.Confidence := ExtractFloatField(CleanJson, 'confidence');
  Result.Sentiment := ExtractField(CleanJson, 'sentiment');
  Result.NeedsHumanAgent := ExtractBoolField(CleanJson, 'needs_human_agent');
  Result.Summary := ExtractField(CleanJson, 'summary');

  Result.ExtractedEntities := TStringList.Create;
  Result.ExtractedEntities.Add('raw_json=' + CleanJson);
end;

function TLazAiStructuredExtractor.TryExtractKeyValue(const RawAiOutput, Key: string;
  out Value: string): Boolean;
var
  CleanJson: string;
begin
  CleanJson := SanitizeAiJson(RawAiOutput);
  Value := ExtractField(CleanJson, Key);
  Result := (Value <> '');
end;

end.
