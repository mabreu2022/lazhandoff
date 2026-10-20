{==============================================================================
  Implementação de SHA-256 conforme FIPS PUB 180-4
  Compatível com Free Pascal / Lazarus
==============================================================================}
unit sha256;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  TSHA256Digest = array[0..31] of Byte;
  PSHA256Digest = ^TSHA256Digest;

  TSHA256Context = record
    State: array[0..7] of Cardinal;
    Count: QWord;
    Buffer: array[0..63] of Byte;
  end;
  PSHA256Context = ^TSHA256Context;

procedure SHA256Init(var Context: TSHA256Context);
procedure SHA256Update(var Context: TSHA256Context; const Buffer; Count: PtrUInt);
procedure SHA256Final(var Context: TSHA256Context; out Digest: TSHA256Digest);

function SHA256Buffer(const Buffer; Count: PtrUInt): TSHA256Digest;
function SHA256String(const S: string): TSHA256Digest;
function SHA256Stream(AStream: TStream): TSHA256Digest;
function SHA256File(const Filename: string): TSHA256Digest;
function SHA256Print(const Digest: TSHA256Digest): string;

implementation

const
  K256: array[0..63] of Cardinal = (
    $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5, $3956c25b, $59f111f1, $923f82a4, $ab1c5ed5,
    $d807aa98, $12835b01, $243185be, $550c7dc3, $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174,
    $e49b69c1, $efbe4786, $0fc19dc6, $240ca1cc, $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da,
    $983e5152, $a831c66d, $b00327c8, $bf597fc7, $c6e00bf3, $d5a79147, $06ca6351, $14292967,
    $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13, $650a7354, $766a0abb, $81c2c92e, $92722c85,
    $a2bfe8a1, $a81a664b, $c24b8b70, $c76c51a3, $d192e819, $d6990624, $f40e3585, $106aa070,
    $19a4c116, $1e376c08, $2748774c, $34b0bcb5, $391c0cb3, $4ed8aa4a, $5b9cca4f, $682e6ff3,
    $748f82ee, $78a5636f, $84c87814, $8cc70208, $90befffa, $a4506ceb, $bef9a3f7, $c67178f2
  );

function ROR(x: Cardinal; n: Byte): Cardinal; inline;
begin
  Result := (x shr n) or (x shl (32 - n));
end;

function Ch(x, y, z: Cardinal): Cardinal; inline;
begin
  Result := (x and y) xor ((not x) and z);
end;

function Maj(x, y, z: Cardinal): Cardinal; inline;
begin
  Result := (x and y) xor (x and z) xor (y and z);
end;

function Sigma0(x: Cardinal): Cardinal; inline;
begin
  Result := ROR(x, 2) xor ROR(x, 13) xor ROR(x, 22);
end;

function Sigma1(x: Cardinal): Cardinal; inline;
begin
  Result := ROR(x, 6) xor ROR(x, 11) xor ROR(x, 25);
end;

function Gamma0(x: Cardinal): Cardinal; inline;
begin
  Result := ROR(x, 7) xor ROR(x, 18) xor (x shr 3);
end;

function Gamma1(x: Cardinal): Cardinal; inline;
begin
  Result := ROR(x, 17) xor ROR(x, 19) xor (x shr 10);
end;

procedure Transform(var State: array of Cardinal; const Block: array of Byte);
var
  W: array[0..63] of Cardinal;
  a, b, c, d, e, f, g, h: Cardinal;
  T1, T2: Cardinal;
  i: Integer;
begin
  for i := 0 to 15 do
    W[i] := (Cardinal(Block[i * 4]) shl 24) or
            (Cardinal(Block[i * 4 + 1]) shl 16) or
            (Cardinal(Block[i * 4 + 2]) shl 8) or
            (Cardinal(Block[i * 4 + 3]));

  for i := 16 to 63 do
    W[i] := Gamma1(W[i - 2]) + W[i - 7] + Gamma0(W[i - 15]) + W[i - 16];

  a := State[0];
  b := State[1];
  c := State[2];
  d := State[3];
  e := State[4];
  f := State[5];
  g := State[6];
  h := State[7];

  for i := 0 to 63 do
  begin
    T1 := h + Sigma1(e) + Ch(e, f, g) + K256[i] + W[i];
    T2 := Sigma0(a) + Maj(a, b, c);
    h := g;
    g := f;
    f := e;
    e := d + T1;
    d := c;
    c := b;
    b := a;
    a := T1 + T2;
  end;

  Inc(State[0], a);
  Inc(State[1], b);
  Inc(State[2], c);
  Inc(State[3], d);
  Inc(State[4], e);
  Inc(State[5], f);
  Inc(State[6], g);
  Inc(State[7], h);
end;

procedure SHA256Init(var Context: TSHA256Context);
begin
  Context.State[0] := $6a09e667;
  Context.State[1] := $bb67ae85;
  Context.State[2] := $3c6ef372;
  Context.State[3] := $a54ff53a;
  Context.State[4] := $510e527f;
  Context.State[5] := $9b05688c;
  Context.State[6] := $1f83d9ab;
  Context.State[7] := $5be0cd19;
  Context.Count := 0;
  FillChar(Context.Buffer, SizeOf(Context.Buffer), 0);
end;

procedure SHA256Update(var Context: TSHA256Context; const Buffer; Count: PtrUInt);
var
  BufferIndex: Cardinal;
  BufferSpace: Cardinal;
  P: PByte;
  LeftCount: PtrUInt;
begin
  if Count = 0 then Exit;
  P := PByte(@Buffer);
  LeftCount := Count;

  BufferIndex := Cardinal((Context.Count shr 3) and 63);
  Inc(Context.Count, QWord(Count) shl 3);

  BufferSpace := 64 - BufferIndex;
  if LeftCount >= BufferSpace then
  begin
    Move(P^, Context.Buffer[BufferIndex], BufferSpace);
    Transform(Context.State, Context.Buffer);
    Inc(P, BufferSpace);
    Dec(LeftCount, BufferSpace);
    while LeftCount >= 64 do
    begin
      Transform(Context.State, PByteArray(P)^);
      Inc(P, 64);
      Dec(LeftCount, 64);
    end;
    BufferIndex := 0;
  end;

  if LeftCount > 0 then
    Move(P^, Context.Buffer[BufferIndex], LeftCount);
end;

procedure SHA256Final(var Context: TSHA256Context; out Digest: TSHA256Digest);
var
  PadLen: Cardinal;
  BufferIndex: Cardinal;
  Bits: array[0..7] of Byte;
  BitLen: QWord;
  Padding: array[0..63] of Byte;
  i: Integer;
begin
  BitLen := Context.Count;
  for i := 7 downto 0 do
  begin
    Bits[7 - i] := Byte((BitLen shr (i * 8)) and $FF);
  end;

  BufferIndex := Cardinal((Context.Count shr 3) and 63);
  if BufferIndex < 56 then
    PadLen := 56 - BufferIndex
  else
    PadLen := 120 - BufferIndex;

  FillChar(Padding, SizeOf(Padding), 0);
  Padding[0] := $80;
  SHA256Update(Context, Padding, PadLen);
  SHA256Update(Context, Bits, 8);

  for i := 0 to 7 do
  begin
    Digest[i * 4] := Byte((Context.State[i] shr 24) and $FF);
    Digest[i * 4 + 1] := Byte((Context.State[i] shr 16) and $FF);
    Digest[i * 4 + 2] := Byte((Context.State[i] shr 8) and $FF);
    Digest[i * 4 + 3] := Byte(Context.State[i] and $FF);
  end;
end;

function SHA256Buffer(const Buffer; Count: PtrUInt): TSHA256Digest;
var
  Ctx: TSHA256Context;
begin
  SHA256Init(Ctx);
  SHA256Update(Ctx, Buffer, Count);
  SHA256Final(Ctx, Result);
end;

function SHA256String(const S: string): TSHA256Digest;
begin
  if Length(S) = 0 then
    Result := SHA256Buffer('', 0)
  else
    Result := SHA256Buffer(S[1], Length(S));
end;

function SHA256Stream(AStream: TStream): TSHA256Digest;
var
  Ctx: TSHA256Context;
  Buf: array[0..4095] of Byte;
  ReadBytes: Integer;
begin
  SHA256Init(Ctx);
  ReadBytes := AStream.Read(Buf, SizeOf(Buf));
  while ReadBytes > 0 do
  begin
    SHA256Update(Ctx, Buf, ReadBytes);
    ReadBytes := AStream.Read(Buf, SizeOf(Buf));
  end;
  SHA256Final(Ctx, Result);
end;

function SHA256File(const Filename: string): TSHA256Digest;
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    Result := SHA256Stream(FS);
  finally
    FS.Free;
  end;
end;

function SHA256Print(const Digest: TSHA256Digest): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to 31 do
    Result := Result + IntToHex(Digest[i], 2);
  Result := LowerCase(Result);
end;

end.
