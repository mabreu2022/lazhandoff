{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 30: Motor Gerador de PDFs e Documentos Financeiros (TDlpFastPdfReportBuilder)
  Componente: TDlpFastPdfReportBuilder
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Multiplataforma)
  Descrição: Motor autônomo de geração nativa de arquivos PDF em Object Pascal.
             Produz documentos financeiros, extratos bancários, faturas e
             relatórios sem qualquer dependência externa ou drivers de impressão.
             Gera catálogo, fontes WinAnsiEncoding, páginas, streams vetoriais,
             tabela xref e trailer.
==============================================================================}
unit DlpFastPdfReport;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics;

type
  { Unidade de medida para layout do documento PDF }
  TDlpPdfUnit = (puPoints, puMillimeters, puInches);

  { Alinhamento horizontal de texto }
  TDlpPdfTextAlign = (ptaLeft, ptaCenter, ptaRight);

  { Definição de buffer de página PDF }
  TDlpPdfPageBuffer = class
  private
    FContentStream: TStringStream;
  public
    constructor Create;
    destructor Destroy; override;
    property ContentStream: TStringStream read FContentStream;
  end;

  {============================================================================
    Componente: TDlpFastPdfReportBuilder
    Gerador nativo e independente de arquivos PDF
  ============================================================================}
  TDlpFastPdfReportBuilder = class(TComponent)
  private
    FDocTitle: string;
    FDocAuthor: string;
    FPageWidthPt: Double;
    FPageHeightPt: Double;
    FPages: TList;
    FCurrentPageIdx: Integer;
    FUnit: TDlpPdfUnit;

    function ConvertToPoints(AValue: Double): Double;
    function GetCurrentPage: TDlpPdfPageBuffer;
    function EscapePdfString(const S: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure BeginDoc;
    procedure NewPage;
    procedure EndDoc;
    procedure SaveToFile(const AFileName: string);
    procedure SaveToStream(AStream: TStream);

    procedure SetDrawColor(AColor: TColor);
    procedure SetFillColor(AColor: TColor);
    procedure DrawLine(X1, Y1, X2, Y2: Double; ALineWidth: Double = 1.0);
    procedure DrawRect(X, Y, W, H: Double; AFill: Boolean = False; AStroke: Boolean = True);

    procedure DrawText(X, Y: Double; const AText: string; AFontSize: Double = 10;
      AAlign: TDlpPdfTextAlign = ptaLeft);
    procedure DrawFinancialRow(Y: Double; const Col1, Col2, Col3, Col4: string;
      W1, W2, W3, W4: Double; IsHeader: Boolean = False);
  published
    property DocumentTitle: string read FDocTitle write FDocTitle;
    property Author: string read FDocAuthor write FDocAuthor;
    property PageUnit: TDlpPdfUnit read FUnit write FUnit default puMillimeters;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpFastPdfReportBuilder]);
end;

{ TDlpPdfPageBuffer }

constructor TDlpPdfPageBuffer.Create;
begin
  inherited Create;
  FContentStream := TStringStream.Create('', TEncoding.ANSI);
end;

destructor TDlpPdfPageBuffer.Destroy;
begin
  FContentStream.Free;
  inherited Destroy;
end;

{ TDlpFastPdfReportBuilder }

constructor TDlpFastPdfReportBuilder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDocTitle := 'Relatorio Financeiro Consolidado';
  FDocAuthor := 'Antigravity Delphi Enterprise Engine';
  FUnit := puMillimeters;
  FPageWidthPt := 595.28; { A4 }
  FPageHeightPt := 841.89;
  FPages := TList.Create;
  FCurrentPageIdx := -1;
end;

destructor TDlpFastPdfReportBuilder.Destroy;
var
  i: Integer;
begin
  for i := 0 to FPages.Count - 1 do
    TDlpPdfPageBuffer(FPages[i]).Free;
  FPages.Free;
  inherited Destroy;
end;

function TDlpFastPdfReportBuilder.ConvertToPoints(AValue: Double): Double;
begin
  case FUnit of
    puMillimeters: Result := AValue * 72.0 / 25.4;
    puInches:      Result := AValue * 72.0;
  else
    Result := AValue;
  end;
end;

function TDlpFastPdfReportBuilder.GetCurrentPage: TDlpPdfPageBuffer;
begin
  if (FCurrentPageIdx < 0) or (FCurrentPageIdx >= FPages.Count) then
    NewPage;
  Result := TDlpPdfPageBuffer(FPages[FCurrentPageIdx]);
end;

function TDlpFastPdfReportBuilder.EscapePdfString(const S: string): string;
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

procedure TDlpFastPdfReportBuilder.BeginDoc;
var
  i: Integer;
begin
  for i := 0 to FPages.Count - 1 do
    TDlpPdfPageBuffer(FPages[i]).Free;
  FPages.Clear;
  FCurrentPageIdx := -1;
  NewPage;
end;

procedure TDlpFastPdfReportBuilder.NewPage;
var
  P: TDlpPdfPageBuffer;
begin
  P := TDlpPdfPageBuffer.Create;
  FPages.Add(P);
  FCurrentPageIdx := FPages.Count - 1;
end;

procedure TDlpFastPdfReportBuilder.EndDoc;
begin
  { Finalização de referências de página }
end;

procedure TDlpFastPdfReportBuilder.SetDrawColor(AColor: TColor);
var
  R, G, B: Double;
  Cmd: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  R := (AColor and $000000FF) / 255.0;
  G := ((AColor and $0000FF00) shr 8) / 255.0;
  B := ((AColor and $00FF0000) shr 16) / 255.0;
  Cmd := Format('%.3f %.3f %.3f RG'#10, [R, G, B], FS);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TDlpFastPdfReportBuilder.SetFillColor(AColor: TColor);
var
  R, G, B: Double;
  Cmd: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  R := (AColor and $000000FF) / 255.0;
  G := ((AColor and $0000FF00) shr 8) / 255.0;
  B := ((AColor and $00FF0000) shr 16) / 255.0;
  Cmd := Format('%.3f %.3f %.3f rg'#10, [R, G, B], FS);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TDlpFastPdfReportBuilder.DrawLine(X1, Y1, X2, Y2: Double; ALineWidth: Double);
var
  Px1, Py1, Px2, Py2, Plw: Double;
  Cmd: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Px1 := ConvertToPoints(X1);
  Py1 := FPageHeightPt - ConvertToPoints(Y1);
  Px2 := ConvertToPoints(X2);
  Py2 := FPageHeightPt - ConvertToPoints(Y2);
  Plw := ConvertToPoints(ALineWidth);

  Cmd := Format('%.2f w %.2f %.2f m %.2f %.2f l S'#10,
    [Plw, Px1, Py1, Px2, Py2], FS);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TDlpFastPdfReportBuilder.DrawRect(X, Y, W, H: Double; AFill: Boolean; AStroke: Boolean);
var
  Px, Py, Pw, Ph: Double;
  Op, Cmd: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
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

  Cmd := Format('%.2f %.2f %.2f %.2f re %s'#10, [Px, Py, Pw, Ph, Op], FS);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TDlpFastPdfReportBuilder.DrawText(X, Y: Double; const AText: string;
  AFontSize: Double; AAlign: TDlpPdfTextAlign);
var
  Px, Py: Double;
  EscText, Cmd: string;
  EstimatedW: Double;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Px := ConvertToPoints(X);
  Py := FPageHeightPt - ConvertToPoints(Y) - AFontSize;
  EscText := EscapePdfString(AText);

  EstimatedW := Length(AText) * AFontSize * 0.52;
  if AAlign = ptaCenter then
    Px := Px - (EstimatedW / 2)
  else if AAlign = ptaRight then
    Px := Px - EstimatedW;

  Cmd := Format('BT /F1 %.2f Tf %.2f %.2f Td (%s) Tj ET'#10,
    [AFontSize, Px, Py, EscText], FS);
  GetCurrentPage.ContentStream.WriteString(Cmd);
end;

procedure TDlpFastPdfReportBuilder.DrawFinancialRow(Y: Double; const Col1, Col2, Col3, Col4: string;
  W1, W2, W3, W4: Double; IsHeader: Boolean);
var
  CurrX: Double;
begin
  if IsHeader then
  begin
    SetFillColor($00F0E6D8);
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

  SetDrawColor($00E0E0E0);
  DrawLine(15, Y + 6, 15 + W1 + W2 + W3 + W4, Y + 6, 0.2);
end;

procedure TDlpFastPdfReportBuilder.SaveToStream(AStream: TStream);
var
  Offsets: TArray<Int64>;
  ObjCount: Integer;
  OutStr: AnsiString;
  XrefPos: Int64;
  i, PageObjStart: Integer;
  PageKids: string;
  PageBuf: TDlpPdfPageBuffer;
  FS: TFormatSettings;

  procedure WriteStr(const S: string);
  var
    AStr: AnsiString;
  begin
    AStr := AnsiString(S);
    AStream.WriteBuffer(Pointer(AStr)^, Length(AStr));
  end;

  procedure RegisterObj(ObjIndex: Integer);
  begin
    Offsets[ObjIndex] := AStream.Position;
    WriteStr(Format('%d 0 obj'#10, [ObjIndex], FS));
  end;

begin
  FS := TFormatSettings.Invariant;
  WriteStr('%PDF-1.4'#10'%'#226#227#207#211#10);

  ObjCount := 3 + (FPages.Count * 2);
  SetLength(Offsets, ObjCount + 1);

  RegisterObj(1);
  WriteStr('<< /Type /Catalog /Pages 2 0 R >>'#10'endobj'#10);

  PageKids := '[';
  for i := 0 to FPages.Count - 1 do
    PageKids := PageKids + Format('%d 0 R ', [4 + i], FS);
  PageKids := PageKids + ']';

  RegisterObj(2);
  WriteStr(Format('<< /Type /Pages /Count %d /Kids %s >>'#10'endobj'#10,
    [FPages.Count, PageKids], FS));

  RegisterObj(3);
  WriteStr('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>'#10'endobj'#10);

  PageObjStart := 4;
  for i := 0 to FPages.Count - 1 do
  begin
    RegisterObj(PageObjStart + i);
    OutStr := AnsiString(Format('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %.2f %.2f] ' +
      '/Resources << /Font << /F1 3 0 R >> >> /Contents %d 0 R >>'#10'endobj'#10,
      [FPageWidthPt, FPageHeightPt, PageObjStart + FPages.Count + i], FS));
    WriteStr(string(OutStr));
  end;

  for i := 0 to FPages.Count - 1 do
  begin
    PageBuf := TDlpPdfPageBuffer(FPages[i]);
    RegisterObj(PageObjStart + FPages.Count + i);
    WriteStr(Format('<< /Length %d >>'#10'stream'#10, [PageBuf.ContentStream.Size], FS));
    AStream.CopyFrom(PageBuf.ContentStream, 0);
    WriteStr(#10'endstream'#10'endobj'#10);
  end;

  XrefPos := AStream.Position;
  WriteStr(Format('xref'#10'0 %d'#10'0000000000 65535 f '#10, [ObjCount + 1], FS));
  for i := 1 to ObjCount do
  begin
    WriteStr(Format('%.10d 00000 n '#10, [Offsets[i]], FS));
  end;

  WriteStr(Format('trailer'#10'<< /Size %d /Root 1 0 R >>'#10'startxref'#10'%d'#10'%%%%EOF'#10,
    [ObjCount + 1, XrefPos], FS));
end;

procedure TDlpFastPdfReportBuilder.SaveToFile(const AFileName: string);
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
