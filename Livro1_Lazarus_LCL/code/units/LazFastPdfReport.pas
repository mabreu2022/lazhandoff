{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 30: Motor Gerador de PDFs e Documentos Financeiros (TLazFastPdfReportBuilder)
  Componente: TLazFastPdfReportBuilder
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Motor de geração direta de documentos PDF nativos (versão 1.4/1.7)
             sem dependência de DLLs externas ou ActiveX. Suporta textos, tabelas
             financeiras com zebrado, linhas, caixas retangulares, quebras de
             página e geração de árvore de objetos com tabela xref e trailer.
==============================================================================}
unit LazFastPdfReport;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Graphics;

type
  { Unidade de medida para layout do documento PDF }
  TPdfUnit = (puPoints, puMillimeters, puInches);

  { Alinhamento horizontal de texto }
  TPdfTextAlign = (ptaLeft, ptaCenter, ptaRight);

  { Definição de uma página no buffer do PDF }
  TPdfPageBuffer = class
  private
    FContentStream: TStringStream;
  public
    constructor Create;
    destructor Destroy; override;
    property ContentStream: TStringStream read FContentStream;
  end;

  {============================================================================
    Componente: TLazFastPdfReportBuilder
    Gerador nativo e independente de arquivos PDF
  ============================================================================}
  TLazFastPdfReportBuilder = class(TComponent)
  private
    FDocTitle: string;
    FDocAuthor: string;
    FPageWidthPt: Double;
    FPageHeightPt: Double;
    FPages: TFPList;
    FCurrentPageIdx: Integer;
    FUnit: TPdfUnit;

    function ConvertToPoints(AValue: Double): Double;
    function GetCurrentPage: TPdfPageBuffer;
    function EscapePdfString(const S: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos de controle de documento }
    procedure BeginDoc;
    procedure NewPage;
    procedure EndDoc;
    procedure SaveToFile(const AFileName: string);
    procedure SaveToStream(AStream: TStream);

    { Métodos gráficos de desenho primitivo }
    procedure SetDrawColor(AColor: TColor);
    procedure SetFillColor(AColor: TColor);
    procedure DrawLine(X1, Y1, X2, Y2: Double; ALineWidth: Double = 1.0);
    procedure DrawRect(X, Y, W, H: Double; AFill: Boolean = False; AStroke: Boolean = True);

    { Métodos de renderização de texto e tipografia }
    procedure DrawText(X, Y: Double; const AText: string; AFontSize: Double = 10;
      AAlign: TPdfTextAlign = ptaLeft);
    procedure DrawFinancialRow(Y: Double; const Col1, Col2, Col3, Col4: string;
      W1, W2, W3, W4: Double; IsHeader: Boolean = False);
  published
    property DocumentTitle: string read FDocTitle write FDocTitle;
    property Author: string read FDocAuthor write FDocAuthor;
    property PageUnit: TPdfUnit read FUnit write FUnit default puMillimeters;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazFastPdfReportBuilder]);
end;

{ TPdfPageBuffer }

constructor TPdfPageBuffer.Create;
begin
  inherited Create;
  FContentStream := TStringStream.Create('');
end;

destructor TPdfPageBuffer.Destroy;
begin
  FContentStream.Free;
  inherited Destroy;
end;

{ TLazFastPdfReportBuilder }

constructor TLazFastPdfReportBuilder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDocTitle := 'Extrato Financeiro Consolidado';
  FDocAuthor := 'Antigravity Enterprise Engine';
  FUnit := puMillimeters;
  { Tamanho A4 padrão em pontos (72 dpi): 595.28 x 841.89 }
  FPageWidthPt := 595.28;
  FPageHeightPt := 841.89;
  FPages := TFPList.Create;
  FCurrentPageIdx := -1;
end;

destructor TLazFastPdfReportBuilder.Destroy;
var
  i: Integer;
begin
  for i := 0 to FPages.Count - 1 do
    TPdfPageBuffer(FPages[i]).Free;
  FPages.Free;
  inherited Destroy;
end;

function TLazFastPdfReportBuilder.ConvertToPoints(AValue: Double): Double;
begin
  case FUnit of
    puMillimeters: Result := AValue * 72.0 / 25.4;
    puInches:      Result := AValue * 72.0;
  else
    Result := AValue; { puPoints }
  end;
end;

function TLazFastPdfReportBuilder.GetCurrentPage: TPdfPageBuffer;
begin
  if (FCurrentPageIdx < 0) or (FCurrentPageIdx >= FPages.Count) then
    NewPage;
  Result := TPdfPageBuffer(FPages[FCurrentPageIdx]);
end;

function TLazFastPdfReportBuilder.EscapePdfString(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    case S[i] of
      '(': Result := Result + '\(';
      ')': Result := Result + '\)';
      '\': Result := Result + '\\';
    else
      Result := Result + S[i];
    end;
  end;
end;

procedure TLazFastPdfReportBuilder.BeginDoc;
var
  i: Integer;
begin
  for i := 0 to FPages.Count - 1 do
    TPdfPageBuffer(FPages[i]).Free;
  FPages.Clear;
  FCurrentPageIdx := -1;
  NewPage;
end;

procedure TLazFastPdfReportBuilder.NewPage;
var
  P: TPdfPageBuffer;
begin
  P := TPdfPageBuffer.Create;
  FPages.Add(P);
  FCurrentPageIdx := FPages.Count - 1;
end;

procedure TLazFastPdfReportBuilder.EndDoc;
begin
  { Fechamento e consolidação de buffers de página }
end;

procedure TLazFastPdfReportBuilder.SetDrawColor(AColor: TColor);
var
  R, G, B: Double;
  Cmd: string;
begin
  R := Red(AColor) / 255.0;
  G := Green(AColor) / 255.0;
  B := Blue(AColor) / 255.0;
  Cmd := Format('%.3f %.3f %.3f RG'#10, [R, G, B], FormatSettings);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TLazFastPdfReportBuilder.SetFillColor(AColor: TColor);
var
  R, G, B: Double;
  Cmd: string;
begin
  R := Red(AColor) / 255.0;
  G := Green(AColor) / 255.0;
  B := Blue(AColor) / 255.0;
  Cmd := Format('%.3f %.3f %.3f rg'#10, [R, G, B], FormatSettings);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TLazFastPdfReportBuilder.DrawLine(X1, Y1, X2, Y2: Double; ALineWidth: Double);
var
  Px1, Py1, Px2, Py2, Plw: Double;
  Cmd: string;
begin
  Px1 := ConvertToPoints(X1);
  Py1 := FPageHeightPt - ConvertToPoints(Y1);
  Px2 := ConvertToPoints(X2);
  Py2 := FPageHeightPt - ConvertToPoints(Y2);
  Plw := ConvertToPoints(ALineWidth);

  Cmd := Format('%.2f w %.2f %.2f m %.2f %.2f l S'#10,
    [Plw, Px1, Py1, Px2, Py2], FormatSettings);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TLazFastPdfReportBuilder.DrawRect(X, Y, W, H: Double; AFill: Boolean; AStroke: Boolean);
var
  Px, Py, Pw, Ph: Double;
  Op, Cmd: string;
begin
  Px := ConvertToPoints(X);
  Pw := ConvertToPoints(W);
  Ph := ConvertToPoints(H);
  Py := FPageHeightPt - ConvertToPoints(Y) - Ph;

  if AFill and AStroke then
    Op := 'B'
  else if AFill then
    Op := 'f'
  else
    Op := 'S';

  Cmd := Format('%.2f %.2f %.2f %.2f re %s'#10, [Px, Py, Pw, Ph, Op], FormatSettings);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TLazFastPdfReportBuilder.DrawText(X, Y: Double; const AText: string;
  AFontSize: Double; AAlign: TPdfTextAlign);
var
  Px, Py: Double;
  EscText, Cmd: string;
  EstimatedW: Double;
begin
  Px := ConvertToPoints(X);
  Py := FPageHeightPt - ConvertToPoints(Y) - AFontSize;
  EscText := EscapePdfString(AText);

  { Estimativa básica de largura com base na média tipográfica da Helvetica (0.52em) }
  EstimatedW := Length(AText) * AFontSize * 0.52;
  if AAlign = ptaCenter then
    Px := Px - (EstimatedW / 2)
  else if AAlign = ptaRight then
    Px := Px - EstimatedW;

  Cmd := Format('BT /F1 %.2f Tf %.2f %.2f Td (%s) Tj ET'#10,
    [AFontSize, Px, Py, EscText], FormatSettings);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TLazFastPdfReportBuilder.DrawFinancialRow(Y: Double; const Col1, Col2, Col3, Col4: string;
  W1, W2, W3, W4: Double; IsHeader: Boolean);
var
  CurrX: Double;
begin
  if IsHeader then
  begin
    SetFillColor($00F0E6D8); { Cinza/azulado suave para cabeçalho }
    DrawRect(15, Y - 1, W1 + W2 + W3 + W4, 7, True, False);
    SetDrawColor(clBlack);
  end;

  CurrX := 15;
  DrawText(CurrX + 1, Y + 4, Col1, 9, ptaLeft);
  CurrX := CurrX + W1;
  DrawText(CurrX + 1, Y + 4, Col2, 9, ptaLeft);
  CurrX := CurrX + W2;
  DrawText(CurrX + W3 - 2, Y + 4, Col3, 9, ptaRight);
  CurrX := CurrX + W3;
  DrawText(CurrX + W4 - 2, Y + 4, Col4, 9, ptaRight);

  { Linha divisória inferior }
  SetDrawColor($00E0E0E0);
  DrawLine(15, Y + 6, 15 + W1 + W2 + W3 + W4, Y + 6, 0.2);
end;

procedure TLazFastPdfReportBuilder.SaveToStream(AStream: TStream);
var
  Offsets: array of Int64;
  ObjCount: Integer;
  OutStr: string;
  XrefPos: Int64;
  i, PageObjStart: Integer;
  PageKids: string;
  PageBuf: TPdfPageBuffer;

  procedure WriteStr(const S: string);
  begin
    AStream.WriteBuffer(Pointer(S)^, Length(S));
  end;

  procedure RegisterObj(ObjIndex: Integer);
  begin
    Offsets[ObjIndex] := AStream.Position;
    WriteStr(Format('%d 0 obj'#10, [ObjIndex], FormatSettings));
  end;

begin
  { Header do PDF }
  WriteStr('%PDF-1.4'#10'%'#226#227#207#211#10);

  { Cálculo de objetos:
    1: Catálogo
    2: Pages
    3: Font Helvetica
    4..4+N-1: Page Objects
    4+N..4+2N-1: Content Streams }
  ObjCount := 3 + (FPages.Count * 2);
  SetLength(Offsets, ObjCount + 1);

  { Objeto 1: Catálogo }
  RegisterObj(1);
  WriteStr('<< /Type /Catalog /Pages 2 0 R >>'#10'endobj'#10);

  { Monta lista de referências de páginas para Objeto 2 }
  PageKids := '[';
  for i := 0 to FPages.Count - 1 do
    PageKids := PageKids + Format('%d 0 R ', [4 + i], FormatSettings);
  PageKids := PageKids + ']';

  { Objeto 2: Árvore Pages }
  RegisterObj(2);
  WriteStr(Format('<< /Type /Pages /Count %d /Kids %s >>'#10'endobj'#10,
    [FPages.Count, PageKids], FormatSettings));

  { Objeto 3: Fonte Padrão Type1 Helvetica }
  RegisterObj(3);
  WriteStr('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>'#10'endobj'#10);

  PageObjStart := 4;
  { Objetos de Página }
  for i := 0 to FPages.Count - 1 do
  begin
    RegisterObj(PageObjStart + i);
    OutStr := Format('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %.2f %.2f] ' +
      '/Resources << /Font << /F1 3 0 R >> >> /Contents %d 0 R >>'#10'endobj'#10,
      [FPageWidthPt, FPageHeightPt, PageObjStart + FPages.Count + i], FormatSettings);
    WriteStr(OutStr);
  end;

  { Objetos de Conteúdo (Stream) de cada Página }
  for i := 0 to FPages.Count - 1 do
  begin
    PageBuf := TPdfPageBuffer(FPages[i]);
    RegisterObj(PageObjStart + FPages.Count + i);
    WriteStr(Format('<< /Length %d >>'#10'stream'#10', [PageBuf.ContentStream.Size], FormatSettings));
    AStream.CopyFrom(PageBuf.ContentStream, 0);
    WriteStr(#10'endstream'#10'endobj'#10);
  end;

  { Tabela XREF }
  XrefPos := AStream.Position;
  WriteStr(Format('xref'#10'0 %d'#10'0000000000 65535 f '#10, [ObjCount + 1], FormatSettings));
  for i := 1 to ObjCount do
  begin
    WriteStr(Format('%.10d 00000 n '#10, [Offsets[i]], FormatSettings));
  end;

  { Trailer }
  WriteStr(Format('trailer'#10'<< /Size %d /Root 1 0 R >>'#10'startxref'#10'%d'#10'%%%%EOF'#10,
    [ObjCount + 1, XrefPos], FormatSettings));
end;

procedure TLazFastPdfReportBuilder.SaveToFile(const AFileName: string);
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

end.
