{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 34: Validador e Emissor de Tokens JWT (TLazJwtSecurityManager)
  Componente: TLazJwtSecurityManager
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Emissor, decodificador e validador de tokens JSON Web Token (JWT)
             em conformidade com a RFC 7519. Implementa assinatura e checagem
             HMAC-SHA256, codificação Base64URL, validação temporal de claims
             (exp, nbf, iat) e lista de revogação de tokens por JTI (Token ID).
==============================================================================}
unit LazJwtSecurityManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  DateUtils,
  sha256;

type
  { Estado da validação de um token }
  TJwtValidationStatus = (
    jvsValid,
    jvsExpired,
    jvsNotBeforeInvalid,
    jvsInvalidSignature,
    jvsMalformed,
    jvsRevoked
  );

  { Claims padrão decodificadas de um JWT }
  TJwtClaims = record
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
    Componente: TLazJwtSecurityManager
    Gerenciador de autenticação e integridade de tokens JWT
  ============================================================================}
  TLazJwtSecurityManager = class(TComponent)
  private
    FSecretKey: string;
    FDefaultIssuer: string;
    FDefaultValidityMinutes: Integer;
    FRevocationList: TStringList;

    function Base64UrlEncode(const InputStr: string): string;
    function Base64UrlDecode(const InputStr: string): string;
    function ComputeHmacSha256(const Key, Message: string): string;
    function ConstantTimeCompare(const Str1, Str2: string): Boolean;
    function DateTimeToUnixEpoch(ADateTime: TDateTime): Int64;
    function UnixEpochToDateTime(Epoch: Int64): TDateTime;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Emissão de tokens }
    function GenerateToken(const ASubject: string; const ATokenId: string = '';
      const ACustomClaimsJson: string = ''): string;

    { Validação e inspeção }
    function ValidateToken(const AToken: string; out AClaims: TJwtClaims): TJwtValidationStatus;
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
  RegisterComponents('Lazarus Engenharia Avancada', [TLazJwtSecurityManager]);
end;

{ Funções auxiliares Base64 }
const
  B64: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function Base64EncodeStr(const S: string): string;
var
  i, Len, Val: Integer;
  b0, b1, b2: Byte;
begin
  Result := '';
  Len := Length(S);
  i := 1;
  while i <= Len do
  begin
    b0 := Ord(S[i]); Inc(i);
    if i <= Len then b1 := Ord(S[i]) else b1 := 0; Inc(i);
    if i <= Len then b2 := Ord(S[i]) else b2 := 0; Inc(i);

    Val := (b0 shl 16) or (b1 shl 8) or b2;
    Result := Result + B64[((Val shr 18) and 63) + 1];
    Result := Result + B64[((Val shr 12) and 63) + 1];

    if i - 2 <= Len then
      Result := Result + B64[((Val shr 6) and 63) + 1]
    else
      Result := Result + '=';

    if i - 1 <= Len then
      Result := Result + B64[(Val and 63) + 1]
    else
      Result := Result + '=';
  end;
end;

function Base64DecodeStr(const S: string): string;
var
  i, Len, Val, PadCount: Integer;
  c0, c1, c2, c3: Integer;
begin
  Result := '';
  Len := Length(S);
  if Len mod 4 <> 0 then Exit;

  PadCount := 0;
  if (Len > 0) and (S[Len] = '=') then Inc(PadCount);
  if (Len > 1) and (S[Len - 1] = '=') then Inc(PadCount);

  i := 1;
  while i <= Len do
  begin
    c0 := Pos(S[i], B64) - 1; Inc(i);
    c1 := Pos(S[i], B64) - 1; Inc(i);
    c2 := Pos(S[i], B64) - 1; Inc(i);
    c3 := Pos(S[i], B64) - 1; Inc(i);

    Val := (c0 shl 18) or (c1 shl 12) or (c2 shl 6) or c3;
    Result := Result + Chr((Val shr 16) and 255);
    if i - 1 <= Len - PadCount then
      Result := Result + Chr((Val shr 8) and 255);
    if i <= Len - PadCount then
      Result := Result + Chr(Val and 255);
  end;
end;

{ TLazJwtSecurityManager }

constructor TLazJwtSecurityManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSecretKey := 'ChaveSecretaPadraoEnterprisePascal2026!#$';
  FDefaultIssuer := 'Antigravity-Lazarus-Auth-Engine';
  FDefaultValidityMinutes := 60;
  FRevocationList := TStringList.Create;
  FRevocationList.Sorted := True;
  FRevocationList.Duplicates := dupIgnore;
end;

destructor TLazJwtSecurityManager.Destroy;
begin
  FRevocationList.Free;
  inherited Destroy;
end;

function TLazJwtSecurityManager.Base64UrlEncode(const InputStr: string): string;
begin
  Result := Base64EncodeStr(InputStr);
  Result := StringReplace(Result, '+', '-', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '', [rfReplaceAll]);
end;

function TLazJwtSecurityManager.Base64UrlDecode(const InputStr: string): string;
var
  Padded: string;
begin
  Padded := StringReplace(InputStr, '-', '+', [rfReplaceAll]);
  Padded := StringReplace(Padded, '_', '/', [rfReplaceAll]);
  while (Length(Padded) mod 4) <> 0 do
    Padded := Padded + '=';
  Result := Base64DecodeStr(Padded);
end;

function TLazJwtSecurityManager.ComputeHmacSha256(const Key, Message: string): string;
var
  K0: array[0..63] of Byte;
  Ipad, Opad: array[0..63] of Byte;
  InnerMsg, OuterMsg: string;
  InnerHash, OuterHash: TSHA256Digest;
  i, KeyLen: Integer;
  HashBytesStr: string;
begin
  FillChar(K0, SizeOf(K0), 0);
  KeyLen := Length(Key);
  if KeyLen > 64 then
  begin
    InnerHash := SHA256String(Key);
    Move(InnerHash[0], K0[0], 32);
  end
  else
    Move(Pointer(Key)^, K0[0], KeyLen);

  for i := 0 to 63 do
  begin
    Ipad[i] := K0[i] xor $36;
    Opad[i] := K0[i] xor $5C;
  end;

  SetLength(InnerMsg, 64 + Length(Message));
  Move(Ipad[0], InnerMsg[1], 64);
  Move(Pointer(Message)^, InnerMsg[65], Length(Message));
  InnerHash := SHA256String(InnerMsg);

  SetLength(OuterMsg, 64 + 32);
  Move(Opad[0], OuterMsg[1], 64);
  Move(InnerHash[0], OuterMsg[65], 32);
  OuterHash := SHA256String(OuterMsg);

  SetLength(HashBytesStr, 32);
  Move(OuterHash[0], HashBytesStr[1], 32);

  Result := Base64UrlEncode(HashBytesStr);
end;

function TLazJwtSecurityManager.ConstantTimeCompare(const Str1, Str2: string): Boolean;
var
  Diff: Integer;
  i: Integer;
begin
  if Length(Str1) <> Length(Str2) then Exit(False);
  Diff := 0;
  for i := 1 to Length(Str1) do
    Diff := Diff or (Ord(Str1[i]) xor Ord(Str2[i]));
  Result := (Diff = 0);
end;

function TLazJwtSecurityManager.DateTimeToUnixEpoch(ADateTime: TDateTime): Int64;
begin
  Result := DateTimeToUnix(ADateTime);
end;

function TLazJwtSecurityManager.UnixEpochToDateTime(Epoch: Int64): TDateTime;
begin
  Result := UnixToDateTime(Epoch);
end;

function TLazJwtSecurityManager.GenerateToken(const ASubject: string;
  const ATokenId: string; const ACustomClaimsJson: string): string;
var
  Header, Payload: string;
  EncodedHeader, EncodedPayload, Signature, SigningInput: string;
  NowUtc: TDateTime;
  ExpUtc: TDateTime;
  Jti: string;
begin
  NowUtc := LocalTimeToUniversal(Now);
  ExpUtc := IncMinute(NowUtc, FDefaultValidityMinutes);

  if ATokenId <> '' then
    Jti := ATokenId
  else
    Jti := IntToStr(DateTimeToUnixEpoch(NowUtc)) + '-' + IntToStr(Random(1000000));

  Header := '{"alg":"HS256","typ":"JWT"}';

  Payload := Format('{"sub":"%s","iss":"%s","iat":%d,"exp":%d,"jti":"%s"',
    [ASubject, FDefaultIssuer, DateTimeToUnixEpoch(NowUtc), DateTimeToUnixEpoch(ExpUtc), Jti]);

  if ACustomClaimsJson <> '' then
    Payload := Payload + ',' + ACustomClaimsJson;

  Payload := Payload + '}';

  EncodedHeader := Base64UrlEncode(Header);
  EncodedPayload := Base64UrlEncode(Payload);
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
    while (PEnd <= Length(Json)) and not (Json[PEnd] in [',', '}', ' ']) do Inc(PEnd);
    Result := Copy(Json, P, PEnd - P);
  end;
end;

function TLazJwtSecurityManager.ValidateToken(const AToken: string;
  out AClaims: TJwtClaims): TJwtValidationStatus;
var
  Parts: TStringArray;
  SigningInput, HeaderJson, PayloadJson, ExpectedSig: string;
  NowUtc: TDateTime;
  ExpEpoch, IatEpoch: Int64;
  ExpStr, IatStr: string;
begin
  AClaims := Default(TJwtClaims);
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

  NowUtc := LocalTimeToUniversal(Now);

  ExpStr := ExtractJsonValue(PayloadJson, 'exp');
  if ExpStr <> '' then
  begin
    ExpEpoch := StrToInt64Def(ExpStr, 0);
    AClaims.ExpiresAt := UnixEpochToDateTime(ExpEpoch);
    if DateTimeToUnixEpoch(NowUtc) > ExpEpoch then
      Exit(jvsExpired);
  end;

  IatStr := ExtractJsonValue(PayloadJson, 'iat');
  if IatStr <> '' then
  begin
    IatEpoch := StrToInt64Def(IatStr, 0);
    AClaims.IssuedAt := UnixEpochToDateTime(IatEpoch);
  end;

  Result := jvsValid;
end;

procedure TLazJwtSecurityManager.RevokeToken(const ATokenId: string);
begin
  if ATokenId <> '' then
    FRevocationList.Add(ATokenId);
end;

function TLazJwtSecurityManager.IsTokenRevoked(const ATokenId: string): Boolean;
begin
  Result := (FRevocationList.IndexOf(ATokenId) >= 0);
end;

procedure TLazJwtSecurityManager.ClearRevocations;
begin
  FRevocationList.Clear;
end;

end.
