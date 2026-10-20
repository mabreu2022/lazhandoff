{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 43: Parser de Respostas Estruturadas JSON (TDlpAiStructuredExtractor)
  Componente: TDlpAiStructuredExtractor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / macOS)
  Descrição: Extrator estruturado e sanitizador de JSON gerado por modelos de IA.
             Remove blocos Markdown decorativos (```json), corrige imperfeições
             sintáticas de modelos generativos (vírgulas pendentes) e faz a hidratação
             direta para records fortemente tipados em Delphi.
==============================================================================}
unit DlpAiStructuredExtractor;

interface

uses
  System.SysUtils,
  System.Classes;

type
  { Registro fortemente tipado de análise semântica de cliente }
  TDlpCustomerIntentRecord = record
    Intent: string;
    Confidence: Double;
    Sentiment: string;
    NeedsHumanAgent: Boolean;
    Summary: string;
    ExtractedEntities: TStrings;
  end;

  {============================================================================
    Componente: TDlpAiStructuredExtractor
    Higienizador e extrator de JSON emitido por LLMs
  ============================================================================}
  TDlpAiStructuredExtractor = class(TComponent)
  private
    FStrictValidation: Boolean;

    function CleanMarkdownFences(const RawText: string): string;
    function RepairJsonSyntax(const CleanJson: string): string;
    function ExtractField(const Json, FieldName: string): string;
    function ExtractBoolField(const Json, FieldName: string): Boolean;
    function ExtractFloatField(const Json, FieldName: string): Double;
  public
    constructor Create(AOwner: TComponent); override;

    function SanitizeAiJson(const RawAiOutput: string): string;
    function ParseCustomerIntent(const RawAiOutput: string): TDlpCustomerIntentRecord;
    function TryExtractKeyValue(const RawAiOutput, Key: string; out Value: string): Boolean;
  published
    property StrictValidation: Boolean read FStrictValidation write FStrictValidation default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpAiStructuredExtractor]);
end;

{ TDlpAiStructuredExtractor }

constructor TDlpAiStructuredExtractor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStrictValidation := False;
end;

function TDlpAiStructuredExtractor.CleanMarkdownFences(const RawText: string): string;
var
  PStart, PEnd: Integer;
  S: string;
begin
  S := RawText;
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

function TDlpAiStructuredExtractor.RepairJsonSyntax(const CleanJson: string): string;
var
  S: string;
begin
  S := CleanJson;
  S := StringReplace(S, #39, '"', [rfReplaceAll]);
  S := StringReplace(S, ', }', '}', [rfReplaceAll]);
  S := StringReplace(S, ',}', '}', [rfReplaceAll]);
  S := StringReplace(S, ', ]', ']', [rfReplaceAll]);
  S := StringReplace(S, ',]', ']', [rfReplaceAll]);
  Result := S;
end;

function TDlpAiStructuredExtractor.SanitizeAiJson(const RawAiOutput: string): string;
begin
  Result := RepairJsonSyntax(CleanMarkdownFences(RawAiOutput));
end;

function TDlpAiStructuredExtractor.ExtractField(const Json, FieldName: string): string;
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
    while (PEnd <= Length(Json)) and not (CharInSet(Json[PEnd], [',', '}', #10, #13, ' '])) do Inc(PEnd);
    Result := Copy(Json, P, PEnd - P);
  end;
end;

function TDlpAiStructuredExtractor.ExtractBoolField(const Json, FieldName: string): Boolean;
var
  V: string;
begin
  V := LowerCase(Trim(ExtractField(Json, FieldName)));
  Result := (V = 'true') or (V = '1') or (V = 'yes');
end;

function TDlpAiStructuredExtractor.ExtractFloatField(const Json, FieldName: string): Double;
var
  V: string;
  FS: TFormatSettings;
begin
  V := Trim(ExtractField(Json, FieldName));
  FS := TFormatSettings.Invariant;
  V := StringReplace(V, ',', '.', [rfReplaceAll]);
  Result := StrToFloatDef(V, 0.0, FS);
end;

function TDlpAiStructuredExtractor.ParseCustomerIntent(const RawAiOutput: string): TDlpCustomerIntentRecord;
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

function TDlpAiStructuredExtractor.TryExtractKeyValue(const RawAiOutput, Key: string;
  out Value: string): Boolean;
var
  CleanJson: string;
begin
  CleanJson := SanitizeAiJson(RawAiOutput);
  Value := ExtractField(CleanJson, Key);
  Result := (Value <> '');
end;

end.
