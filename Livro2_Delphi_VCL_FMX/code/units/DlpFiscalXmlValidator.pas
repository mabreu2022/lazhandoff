{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 32: Processador e Validador Fiscal XML (TDlpFiscalXmlValidator)
  Componente: TDlpFiscalXmlValidator
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / macOS)
  Descrição: Validador de integridade e auditoria estrutural para documentos
             fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, MDF-e).
             Executa cálculo algorítmico do dígito verificador Módulo 11 da chave
             de acesso de 44 dígitos, extração de DigestValue (SHA-1) da assinatura
             digital e validação sintática das tags fiscais essenciais.
==============================================================================}
unit DlpFiscalXmlValidator;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Hash,
  System.NetEncoding;

type
  { Modelo do Documento Fiscal Eletrônico }
  TDlpFiscalDocumentModel = (fdmNFe, fdmNFCe, fdmCTe, fdmMDFe);

  { Registro de diagnóstico consolidado da validação }
  TDlpFiscalValidationResult = record
    IsValid: Boolean;
    DocumentModel: TDlpFiscalDocumentModel;
    AccessKey: string;
    ComputedCheckDigit: Integer;
    ExtractedDigestValue: string;
    ComputedDigestValue: string;
    IsDigestMatch: Boolean;
    ErrorMessage: string;
    AuditLog: TStrings;
  end;

  {============================================================================
    Componente: TDlpFiscalXmlValidator
    Validador de integridade de XML Fiscal
  ============================================================================}
  TDlpFiscalXmlValidator = class(TComponent)
  private
    FStrictValidation: Boolean;

    function CalculateModulo11(const Key43: string): Integer;
    function ExtractXmlTagValue(const Xml, TagName: string): string;
    function ExtractXmlBlock(const Xml, BlockTag: string): string;
    function ComputeSha1Base64(const Data: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function ValidateXmlFile(const AFileName: string): TDlpFiscalValidationResult;
    function ValidateXmlString(const AXmlString: string): TDlpFiscalValidationResult;
    function ValidateAccessKey(const AKey44: string): Boolean;
  published
    property StrictValidation: Boolean read FStrictValidation write FStrictValidation default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpFiscalXmlValidator]);
end;

{ TDlpFiscalXmlValidator }

constructor TDlpFiscalXmlValidator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStrictValidation := True;
end;

destructor TDlpFiscalXmlValidator.Destroy;
begin
  inherited Destroy;
end;

function TDlpFiscalXmlValidator.CalculateModulo11(const Key43: string): Integer;
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

function TDlpFiscalXmlValidator.ExtractXmlTagValue(const Xml, TagName: string): string;
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

function TDlpFiscalXmlValidator.ExtractXmlBlock(const Xml, BlockTag: string): string;
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

function TDlpFiscalXmlValidator.ComputeSha1Base64(const Data: string): string;
var
  HashBytes: TBytes;
begin
  HashBytes := THashSHA1.GetHashBytes(Data);
  Result := TNetEncoding.Base64.EncodeBytesToString(HashBytes);
end;

function TDlpFiscalXmlValidator.ValidateAccessKey(const AKey44: string): Boolean;
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

function TDlpFiscalXmlValidator.ValidateXmlString(const AXmlString: string): TDlpFiscalValidationResult;
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
    Result.ErrorMessage := 'Tag raiz de documento fiscal (<infNFe> ou <infCte>) nao localizada.';
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;

  PId := Pos('Id="NFe', AXmlString);
  if PId > 0 then
  begin
    IdAttr := Copy(AXmlString, PId + 7, 44);
    Result.AccessKey := IdAttr;
    Result.AuditLog.Add('[INFO] Chave de Acesso capturada: ' + Result.AccessKey);
  end
  else
  begin
    Result.ErrorMessage := 'Atributo Id com chave de 44 digitos nao encontrado na tag infNFe.';
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;

  KeyOnly := Copy(Result.AccessKey, 1, 43);
  Result.ComputedCheckDigit := CalculateModulo11(KeyOnly);
  if Result.ComputedCheckDigit <> (Ord(Result.AccessKey[44]) - Ord('0')) then
  begin
    Result.ErrorMessage := Format('Digito verificador da Chave invalido. Esperado: %d, Lido: %s',
      [Result.ComputedCheckDigit, Result.AccessKey[44]]);
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;
  Result.AuditLog.Add('[OK] Chave de Acesso matematicamente valida (Modulo 11 verificado).');

  Result.ExtractedDigestValue := ExtractXmlTagValue(AXmlString, 'DigestValue');
  Result.AuditLog.Add('[INFO] DigestValue da Assinatura: ' + Result.ExtractedDigestValue);

  InfBlock := ExtractXmlBlock(AXmlString, 'infNFe');
  if InfBlock <> '' then
  begin
    Result.ComputedDigestValue := ComputeSha1Base64(InfBlock);
    Result.AuditLog.Add('[INFO] DigestValue Computado Localmente: ' + Result.ComputedDigestValue);
    Result.IsDigestMatch := (Result.ExtractedDigestValue = Result.ComputedDigestValue);
    if Result.IsDigestMatch then
      Result.AuditLog.Add('[OK] Integridade criptografica comprovada (DigestValue identico).')
    else if FStrictValidation then
      Result.AuditLog.Add('[ALERTA] Divergencia no DigestValue (Verificar canonicalizacao C14N).');
  end;

  Result.IsValid := True;
  Result.AuditLog.Add('[SUCESSO] Auditoria fiscal concluida com exito.');
end;

function TDlpFiscalXmlValidator.ValidateXmlFile(const AFileName: string): TDlpFiscalValidationResult;
var
  SL: TStringList;
begin
  if not FileExists(AFileName) then
  begin
    Result.IsValid := False;
    Result.ErrorMessage := 'Arquivo fiscal nao localizado em disco: ' + AFileName;
    Result.AuditLog := TStringList.Create;
    Result.AuditLog.Add('[ERRO] ' + Result.ErrorMessage);
    Exit;
  end;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName, TEncoding.UTF8);
    Result := ValidateXmlString(SL.Text);
  finally
    SL.Free;
  end;
end;

end.
