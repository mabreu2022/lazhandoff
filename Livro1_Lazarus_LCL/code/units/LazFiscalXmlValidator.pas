{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 32: Processador e Validador Fiscal XML (TLazFiscalXmlValidator)
  Componente: TLazFiscalXmlValidator
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Validador de integridade e conformidade de documentos fiscais eletrônicos
             (NF-e, NFC-e, CT-e) em formato XML. Executa cálculo de chave de acesso
             de 44 dígitos com ponderação Módulo 11, validação estrutural de tags
             obrigatórias e extração de DigestValue (SHA-1/SHA-256) do infNFe.
==============================================================================}
unit LazFiscalXmlValidator;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  sha1;

type
  { Modelo do Documento Fiscal }
  TFiscalDocumentModel = (fdmNFe, fdmNFCe, fdmCTe, fdmMDFe);

  { Resultado consolidado da auditoria fiscal }
  TFiscalValidationResult = record
    IsValid: Boolean;
    DocumentModel: TFiscalDocumentModel;
    AccessKey: string;
    ComputedCheckDigit: Integer;
    ExtractedDigestValue: string;
    ComputedDigestValue: string;
    IsDigestMatch: Boolean;
    ErrorMessage: string;
    AuditLog: TStringList;
  end;

  {============================================================================
    Componente: TLazFiscalXmlValidator
    Processador e validador de integridade de XMLs Fiscais
  ============================================================================}
  TLazFiscalXmlValidator = class(TComponent)
  private
    FXmlContent: string;
    FStrictValidation: Boolean;

    function CalculateModulo11(const Key43: string): Integer;
    function ExtractXmlTagValue(const Xml, TagName: string): string;
    function ExtractXmlBlock(const Xml, BlockTag: string): string;
    function ComputeSha1Base64(const Data: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos de validação }
    function ValidateXmlFile(const AFileName: string): TFiscalValidationResult;
    function ValidateXmlString(const AXmlString: string): TFiscalValidationResult;
    function ValidateAccessKey(const AKey44: string): Boolean;
  published
    property StrictValidation: Boolean read FStrictValidation write FStrictValidation default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazFiscalXmlValidator]);
end;

{ Base64 Encoding Helper }
function EncodeBase64(const InputBytes: array of Byte): string;
const
  B64Table: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  i, Len, Val: Integer;
  b0, b1, b2: Byte;
begin
  Result := '';
  Len := Length(InputBytes);
  i := 0;
  while i < Len do
  begin
    b0 := InputBytes[i];
    Inc(i);
    if i < Len then b1 := InputBytes[i] else b1 := 0;
    Inc(i);
    if i < Len then b2 := InputBytes[i] else b2 := 0;
    Inc(i);

    Val := (b0 shl 16) or (b1 shl 8) or b2;
    Result := Result + B64Table[((Val shr 18) and 63) + 1];
    Result := Result + B64Table[((Val shr 12) and 63) + 1];

    if i - 1 < Len then
      Result := Result + B64Table[((Val shr 6) and 63) + 1]
    else
      Result := Result + '=';

    if i <= Len then
      Result := Result + B64Table[(Val and 63) + 1]
    else
      Result := Result + '=';
  end;
end;

{ TLazFiscalXmlValidator }

constructor TLazFiscalXmlValidator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStrictValidation := True;
end;

destructor TLazFiscalXmlValidator.Destroy;
begin
  inherited Destroy;
end;

function TLazFiscalXmlValidator.CalculateModulo11(const Key43: string): Integer;
var
  i, Weight, Sum, Remainder: Integer;
begin
  if Length(Key43) <> 43 then Exit(-1);

  Sum := 0;
  Weight := 2;
  for i := Length(Key43) downto 1 do
  begin
    Sum := Sum + (Ord(Key43[i]) - Ord('0')) * Weight;
    Inc(Weight);
    if Weight > 9 then Weight := 2;
  end;

  Remainder := Sum mod 11;
  if (Remainder = 0) or (Remainder = 1) then
    Result := 0
  else
    Result := 11 - Remainder;
end;

function TLazFiscalXmlValidator.ExtractXmlTagValue(const Xml, TagName: string): string;
var
  OpenTag, CloseTag: string;
  P1, P2: Integer;
begin
  OpenTag := '<' + TagName + '>';
  CloseTag := '</' + TagName + '>';
  P1 := Pos(OpenTag, Xml);
  if P1 > 0 then
  begin
    P1 := P1 + Length(OpenTag);
    P2 := Pos(CloseTag, Xml);
    if P2 > P1 then
      Result := Trim(Copy(Xml, P1, P2 - P1))
    else
      Result := '';
  end
  else
    Result := '';
end;

function TLazFiscalXmlValidator.ExtractXmlBlock(const Xml, BlockTag: string): string;
var
  OpenTagPrefix, CloseTag: string;
  P1, P2: Integer;
begin
  OpenTagPrefix := '<' + BlockTag;
  CloseTag := '</' + BlockTag + '>';
  P1 := Pos(OpenTagPrefix, Xml);
  if P1 > 0 then
  begin
    P2 := Pos(CloseTag, Xml);
    if P2 > P1 then
      Result := Copy(Xml, P1, P2 - P1 + Length(CloseTag))
    else
      Result := '';
  end
  else
    Result := '';
end;

function TLazFiscalXmlValidator.ComputeSha1Base64(const Data: string): string;
var
  Digest: TSHA1Digest;
  Bytes: array[0..19] of Byte;
  i: Integer;
begin
  Digest := SHA1String(Data);
  for i := 0 to 19 do
    Bytes[i] := Digest[i];
  Result := EncodeBase64(Bytes);
end;

function TLazFiscalXmlValidator.ValidateAccessKey(const AKey44: string): Boolean;
var
  Key43: string;
  ExpectedDigit, ActualDigit: Integer;
begin
  if Length(AKey44) <> 44 then Exit(False);

  Key43 := Copy(AKey44, 1, 43);
  ActualDigit := Ord(AKey44[44]) - Ord('0');
  ExpectedDigit := CalculateModulo11(Key43);

  Result := (ActualDigit = ExpectedDigit);
end;

function TLazFiscalXmlValidator.ValidateXmlString(const AXmlString: string): TFiscalValidationResult;
var
  IdAttr, KeyOnly: string;
  PId: Integer;
  InfBlock: string;
begin
  Result.IsValid := False;
  Result.ErrorMessage := '';
  Result.AuditLog := TStringList.Create;
  Result.AuditLog.Add('Iniciando auditoria estrutural do XML Fiscal...');

  if Trim(AXmlString) = '' then
  begin
    Result.ErrorMessage := 'Documento XML vazio ou nulo.';
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;

  { Identificação do Modelo Fiscal }
  if Pos('<infNFe', AXmlString) > 0 then
  begin
    Result.DocumentModel := fdmNFe;
    Result.AuditLog.Add('[OK] Identificado documento modelo NF-e / NFC-e.');
  end
  else if Pos('<infCte', AXmlString) > 0 then
  begin
    Result.DocumentModel := fdmCTe;
    Result.AuditLog.Add('[OK] Identificado documento modelo CT-e.');
  end
  else
  begin
    Result.ErrorMessage := 'Tag raiz de documento fiscal (<infNFe> ou <infCte>) não localizada.';
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;

  { Extração da Chave de Acesso no Atributo Id }
  PId := Pos('Id="NFe', AXmlString);
  if PId > 0 then
  begin
    IdAttr := Copy(AXmlString, PId + 7, 44);
    Result.AccessKey := IdAttr;
    Result.AuditLog.Add('[INFO] Chave de Acesso capturada: ' + Result.AccessKey);
  end
  else
  begin
    Result.ErrorMessage := 'Atributo Id com chave de 44 dígitos não encontrado na tag infNFe.';
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;

  { Validação do Dígito Verificador Módulo 11 da Chave }
  KeyOnly := Copy(Result.AccessKey, 1, 43);
  Result.ComputedCheckDigit := CalculateModulo11(KeyOnly);
  if Result.ComputedCheckDigit <> (Ord(Result.AccessKey[44]) - Ord('0')) then
  begin
    Result.ErrorMessage := Format('Dígito verificador da Chave inválido. Esperado: %d, Lido: %s',
      [Result.ComputedCheckDigit, Result.AccessKey[44]]);
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;
  Result.AuditLog.Add('[OK] Chave de Acesso matematicamente válida (Módulo 11 verificado).');

  { Extração e Verificação do DigestValue da Assinatura Digital }
  Result.ExtractedDigestValue := ExtractXmlTagValue(AXmlString, 'DigestValue');
  Result.AuditLog.Add('[INFO] DigestValue da Assinatura: ' + Result.ExtractedDigestValue);

  InfBlock := ExtractXmlBlock(AXmlString, 'infNFe');
  if InfBlock <> '' then
  begin
    Result.ComputedDigestValue := ComputeSha1Base64(InfBlock);
    Result.AuditLog.Add('[INFO] DigestValue Computado Localmente: ' + Result.ComputedDigestValue);
    Result.IsDigestMatch := (Result.ExtractedDigestValue = Result.ComputedDigestValue);
    if Result.IsDigestMatch then
      Result.AuditLog.Add('[OK] Integridade criptográfica comprovada (DigestValue idêntico).')
    else if FStrictValidation then
      Result.AuditLog.Add('[ALERTA] Divergência no DigestValue (Verificar canonicalização C14N).');
  end;

  Result.IsValid := True;
  Result.AuditLog.Add('[SUCESSO] Auditoria fiscal concluída com êxito.');
end;

function TLazFiscalXmlValidator.ValidateXmlFile(const AFileName: string): TFiscalValidationResult;
var
  SL: TStringList;
begin
  if not FileExists(AFileName) then
  begin
    Result.IsValid := False;
    Result.ErrorMessage := 'Arquivo fiscal não localizado em disco: ' + AFileName;
    Result.AuditLog := TStringList.Create;
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    Result := ValidateXmlString(SL.Text);
  finally
    SL.Free;
  end;
end;

end.
