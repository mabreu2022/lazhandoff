{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 34: Validador e Emissor de Tokens JWT (TDlpJwtSecurityManager)
  Componente: TDlpJwtSecurityManager
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Linux / macOS)
  Descrição: Emissor e validador de tokens JSON Web Token (JWT) padrão RFC 7519.
             Cálculo de assinatura criptográfica HMAC-SHA256, codificação Base64URL
             sem preenchimento, decodificação de claims estruturadas (sub, iss, exp,
             iat, jti) e lista de revogação de tokens em memória.
==============================================================================}
unit DlpJwtSecurityManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  System.Hash,
  System.NetEncoding;

type
  { Estado da validação do token JWT }
  TDlpJwtValidationStatus = (
    jvsValid,
    jvsExpired,
    jvsNotBeforeInvalid,
    jvsInvalidSignature,
    jvsMalformed,
    jvsRevoked
  );

  { Estrutura com metadados de claims do JWT }
  TDlpJwtClaims = record
    Subject: string;
    Issuer: string;
    Audience: string;
    TokenId: string;
    IssuedAt: TDateTime;
    ExpiresAt: TDateTime;
    NotBefore: TDateTime;
    CustomJsonPayload: string;
  end;

  {============================================================================
    Componente: TDlpJwtSecurityManager
    Gerenciador de autenticação e integridade de tokens JWT
  ============================================================================}
  TDlpJwtSecurityManager = class(TComponent)
  private
    FSecretKey: string;
    FDefaultIssuer: string;
    FDefaultValidityMinutes: Integer;
    FRevocationList: TStringList;

    function Base64UrlEncode(const InputBytes: TBytes): string;
    function Base64UrlDecode(const InputStr: string): string;
    function ComputeHmacSha256(const Key, Message: string): string;
    function ConstantTimeCompare(const Str1, Str2: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GenerateToken(const ASubject: string; const ATokenId: string = '';
      const ACustomClaimsJson: string = ''): string;

    function ValidateToken(const AToken: string; out AClaims: TDlpJwtClaims): TDlpJwtValidationStatus;
    procedure RevokeToken(const ATokenId: string);
    function IsTokenRevoked(const ATokenId: string): Boolean;
    procedure ClearRevocations;
  published
    property SecretKey: string read FSecretKey write FSecretKey;
    property DefaultIssuer: string read FDefaultIssuer write FDefaultIssuer;
    property DefaultValidityMinutes: Integer read FDefaultValidityMinutes
      write FDefaultValidityMinutes default 60;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpJwtSecurityManager]);
end;

{ TDlpJwtSecurityManager }

constructor TDlpJwtSecurityManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSecretKey := 'ChaveSecretaDelphi12AthensEnterprise2026!#$';
  FDefaultIssuer := 'Antigravity-Delphi-Auth-Engine';
  FDefaultValidityMinutes := 60;
  FRevocationList := TStringList.Create;
  FRevocationList.Sorted := True;
  FRevocationList.Duplicates := dupIgnore;
end;

destructor TDlpJwtSecurityManager.Destroy;
begin
  FRevocationList.Free;
  inherited Destroy;
end;

function TDlpJwtSecurityManager.Base64UrlEncode(const InputBytes: TBytes): string;
begin
  Result := TNetEncoding.Base64URL.EncodeBytesToString(InputBytes);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '', [rfReplaceAll]);
end;

function TDlpJwtSecurityManager.Base64UrlDecode(const InputStr: string): string;
var
  Padded: string;
  Bytes: TBytes;
begin
  Padded := InputStr;
  while (Length(Padded) mod 4) <> 0 do
    Padded := Padded + '=';
  Bytes := TNetEncoding.Base64URL.DecodeStringToBytes(Padded);
  Result := TEncoding.UTF8.GetString(Bytes);
end;

function TDlpJwtSecurityManager.ComputeHmacSha256(const Key, Message: string): string;
var
  KeyBytes, MsgBytes, HashBytes: TBytes;
  K0, Ipad, Opad: TBytes;
  InnerMsg, OuterMsg: TBytes;
  InnerHash, OuterHash: TBytes;
  i, KeyLen: Integer;
begin
  KeyBytes := TEncoding.UTF8.GetBytes(Key);
  MsgBytes := TEncoding.UTF8.GetBytes(Message);

  SetLength(K0, 64);
  FillChar(K0[0], 64, 0);
  KeyLen := Length(KeyBytes);

  if KeyLen > 64 then
  begin
    HashBytes := THashSHA2.GetHashBytes(KeyBytes);
    Move(HashBytes[0], K0[0], 32);
  end
  else
    Move(KeyBytes[0], K0[0], KeyLen);

  SetLength(Ipad, 64);
  SetLength(Opad, 64);
  for i := 0 to 63 do
  begin
    Ipad[i] := K0[i] xor $36;
    Opad[i] := K0[i] xor $5C;
  end;

  SetLength(InnerMsg, 64 + Length(MsgBytes));
  Move(Ipad[0], InnerMsg[0], 64);
  Move(MsgBytes[0], InnerMsg[64], Length(MsgBytes));
  InnerHash := THashSHA2.GetHashBytes(InnerMsg);

  SetLength(OuterMsg, 64 + 32);
  Move(Opad[0], OuterMsg[0], 64);
  Move(InnerHash[0], OuterMsg[64], 32);
  OuterHash := THashSHA2.GetHashBytes(OuterMsg);

  Result := Base64UrlEncode(OuterHash);
end;

function TDlpJwtSecurityManager.ConstantTimeCompare(const Str1, Str2: string): Boolean;
var
  Diff, i: Integer;
begin
  if Length(Str1) <> Length(Str2) then Exit(False);
  Diff := 0;
  for i := 1 to Length(Str1) do
    Diff := Diff or (Ord(Str1[i]) xor Ord(Str2[i]));
  Result := (Diff = 0);
end;

function TDlpJwtSecurityManager.GenerateToken(const ASubject: string;
  const ATokenId: string; const ACustomClaimsJson: string): string;
var
  Header, Payload: string;
  EncodedHeader, EncodedPayload, Signature, SigningInput: string;
  NowUtc, ExpUtc: TDateTime;
  Jti: string;
begin
  NowUtc := TTimeZone.Local.ToUniversalTime(Now);
  ExpUtc := IncMinute(NowUtc, FDefaultValidityMinutes);

  if ATokenId <> '' then
    Jti := ATokenId
  else
    Jti := DateTimeToUnix(NowUtc).ToString + '-' + Random(1000000).ToString;

  Header := '{"alg":"HS256","typ":"JWT"}';
  Payload := Format('{"sub":"%s","iss":"%s","iat":%d,"exp":%d,"jti":"%s"',
    [ASubject, FDefaultIssuer, DateTimeToUnix(NowUtc), DateTimeToUnix(ExpUtc), Jti]);

  if ACustomClaimsJson <> '' then
    Payload := Payload + ',' + ACustomClaimsJson;

  Payload := Payload + '}';

  EncodedHeader := Base64UrlEncode(TEncoding.UTF8.GetBytes(Header));
  EncodedPayload := Base64UrlEncode(TEncoding.UTF8.GetBytes(Payload));
  SigningInput := EncodedHeader + '.' + EncodedPayload;

  Signature := ComputeHmacSha256(FSecretKey, SigningInput);
  Result := SigningInput + '.' + Signature;
end;

function ExtractJsonValue(const Json, Key: string): string;
var
  P, PEnd: Integer;
  Pattern: string;
begin
  Pattern := '"' + Key + '":';
  P := Pos(Pattern, Json);
  if P = 0 then Exit('');
  P := P + Length(Pattern);
  while (P <= Length(Json)) and (Json[P] = ' ') do Inc(P);

  if (P <= Length(Json)) and (Json[P] = '"') then
  begin
    Inc(P);
    PEnd := P;
    while (PEnd <= Length(Json)) and (Json[PEnd] <> '"') do Inc(PEnd);
    Result := Copy(Json, P, PEnd - P);
  end
  else
  begin
    PEnd := P;
    while (PEnd <= Length(Json)) and not (CharInSet(Json[PEnd], [',', '}', ' '])) do Inc(PEnd);
    Result := Copy(Json, P, PEnd - P);
  end;
end;

function TDlpJwtSecurityManager.ValidateToken(const AToken: string;
  out AClaims: TDlpJwtClaims): TDlpJwtValidationStatus;
var
  Parts: TArray<string>;
  SigningInput, HeaderJson, PayloadJson, ExpectedSig: string;
  NowUtc: TDateTime;
  ExpEpoch, IatEpoch: Int64;
  ExpStr, IatStr: string;
begin
  AClaims := Default(TDlpJwtClaims);
  Parts := AToken.Split(['.']);
  if Length(Parts) <> 3 then
    Exit(jvsMalformed);

  SigningInput := Parts[0] + '.' + Parts[1];
  ExpectedSig := ComputeHmacSha256(FSecretKey, SigningInput);

  if not ConstantTimeCompare(Parts[2], ExpectedSig) then
    Exit(jvsInvalidSignature);

  HeaderJson := Base64UrlDecode(Parts[0]);
  PayloadJson := Base64UrlDecode(Parts[1]);

  AClaims.CustomJsonPayload := PayloadJson;
  AClaims.Subject := ExtractJsonValue(PayloadJson, 'sub');
  AClaims.Issuer := ExtractJsonValue(PayloadJson, 'iss');
  AClaims.TokenId := ExtractJsonValue(PayloadJson, 'jti');

  if (AClaims.TokenId <> '') and IsTokenRevoked(AClaims.TokenId) then
    Exit(jvsRevoked);

  NowUtc := TTimeZone.Local.ToUniversalTime(Now);

  ExpStr := ExtractJsonValue(PayloadJson, 'exp');
  if ExpStr <> '' then
  begin
    ExpEpoch := StrToInt64Def(ExpStr, 0);
    AClaims.ExpiresAt := UnixToDateTime(ExpEpoch);
    if DateTimeToUnix(NowUtc) > ExpEpoch then
      Exit(jvsExpired);
  end;

  IatStr := ExtractJsonValue(PayloadJson, 'iat');
  if IatStr <> '' then
  begin
    IatEpoch := StrToInt64Def(IatStr, 0);
    AClaims.IssuedAt := UnixToDateTime(IatEpoch);
  end;

  Result := jvsValid;
end;

procedure TDlpJwtSecurityManager.RevokeToken(const ATokenId: string);
begin
  if ATokenId <> '' then
    FRevocationList.Add(ATokenId);
end;

function TDlpJwtSecurityManager.IsTokenRevoked(const ATokenId: string): Boolean;
begin
  Result := (FRevocationList.IndexOf(ATokenId) >= 0);
end;

procedure TDlpJwtSecurityManager.ClearRevocations;
begin
  FRevocationList.Clear;
end;

end.
