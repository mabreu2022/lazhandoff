{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 31: Pipeline de Exportação em Segundo Plano (TLazDataExportPipeline)
  Componente: TLazDataExportPipeline
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Pipeline assíncrono multithread para exportação massiva de dados
             originados em TDataSet (SQLQuery, BufDataset, MemDataset) para
             arquivos nos formatos CSV (RFC 4180), JSONL (JSON Lines) e
             XML Spreadsheet sem travar a interface gráfica do usuário (GUI).
==============================================================================}
unit LazDataExportPipeline;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  DB;

type
  { Formatos suportados pelo pipeline de exportação }
  TExportFormat = (efCSV, efJSONL, efXMLSpreadsheet);

  { Evento de progresso sincronizado com a thread principal }
  TExportProgressEvent = procedure(Sender: TObject; ACurrentRow, ATotalRows: Integer;
    APercent: Double) of object;

  { Evento de conclusão do pipeline de exportação }
  TExportCompleteEvent = procedure(Sender: TObject; ASuccess: Boolean;
    const AErrorMsg: string; ATotalExported: Integer) of object;

  { Forward declaration }
  TLazDataExportPipeline = class;

  { Worker Thread de processamento da exportação }
  TDataExportWorkerThread = class(TThread)
  private
    FDataSet: TDataSet;
    FFileName: string;
    FFormat: TExportFormat;
    FOwnerPipeline: TLazDataExportPipeline;
    FCurrentRow: Integer;
    FTotalRows: Integer;
    FErrorMsg: string;
    FSuccess: Boolean;

    procedure DoSyncProgress;
    procedure DoSyncComplete;
    function EscapeCsvField(const S: string): string;
    function EscapeJsonString(const S: string): string;
    procedure ExportToCSV(AStream: TStream);
    procedure ExportToJSONL(AStream: TStream);
    procedure ExportToXMLSpreadsheet(AStream: TStream);
  protected
    procedure Execute; override;
  public
    constructor Create(APipeline: TLazDataExportPipeline; ADataSet: TDataSet;
      const AFileName: string; AFormat: TExportFormat);
  end;

  {============================================================================
    Componente: TLazDataExportPipeline
    Gerenciador de pipeline de exportação assíncrona desacoplado da GUI
  ============================================================================}
  TLazDataExportPipeline = class(TComponent)
  private
    FDataSet: TDataSet;
    FOutputFile: string;
    FFormat: TExportFormat;
    FWorkerThread: TDataExportWorkerThread;
    FIsBusy: Boolean;
    FOnProgress: TExportProgressEvent;
    FOnComplete: TExportCompleteEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Inicia a exportação assíncrona }
    procedure StartExport;
    { Solicita o cancelamento imediato da tarefa }
    procedure CancelExport;

    property IsBusy: Boolean read FIsBusy;
  published
    property DataSet: TDataSet read FDataSet write FDataSet;
    property OutputFile: string read FOutputFile write FOutputFile;
    property Format: TExportFormat read FFormat write FFormat default efCSV;
    property OnProgress: TExportProgressEvent read FOnProgress write FOnProgress;
    property OnComplete: TExportCompleteEvent read FOnComplete write FOnComplete;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazDataExportPipeline]);
end;

{ TDataExportWorkerThread }

constructor TDataExportWorkerThread.Create(APipeline: TLazDataExportPipeline;
  ADataSet: TDataSet; const AFileName: string; AFormat: TExportFormat);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwnerPipeline := APipeline;
  FDataSet := ADataSet;
  FFileName := AFileName;
  FFormat := AFormat;
  FCurrentRow := 0;
  FTotalRows := 0;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TDataExportWorkerThread.DoSyncProgress;
var
  Pct: Double;
begin
  if FTotalRows > 0 then
    Pct := (FCurrentRow / FTotalRows) * 100.0
  else
    Pct := 0.0;

  if Assigned(FOwnerPipeline.FOnProgress) then
    FOwnerPipeline.FOnProgress(FOwnerPipeline, FCurrentRow, FTotalRows, Pct);
end;

procedure TDataExportWorkerThread.DoSyncComplete;
begin
  FOwnerPipeline.FIsBusy := False;
  if Assigned(FOwnerPipeline.FOnComplete) then
    FOwnerPipeline.FOnComplete(FOwnerPipeline, FSuccess, FErrorMsg, FCurrentRow);
end;

function TDataExportWorkerThread.EscapeCsvField(const S: string): string;
begin
  if (Pos('"', S) > 0) or (Pos(',', S) > 0) or (Pos(';', S) > 0) or (Pos(#10, S) > 0) then
    Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"'
  else
    Result := S;
end;

function TDataExportWorkerThread.EscapeJsonString(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    case S[i] of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8:  Result := Result + '\b';
      #9:  Result := Result + '\t';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
    else
      Result := Result + S[i];
    end;
  end;
end;

procedure TDataExportWorkerThread.ExportToCSV(AStream: TStream);
var
  Line: string;
  i: Integer;
  Buf: AnsiString;
begin
  { Cabeçalho com nomes das colunas }
  Line := '';
  for i := 0 to FDataSet.FieldCount - 1 do
  begin
    if i > 0 then Line := Line + ';';
    Line := Line + EscapeCsvField(FDataSet.Fields[i].FieldName);
  end;
  Line := Line + #13#10;
  Buf := AnsiString(Line);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

  { Registros de dados }
  while not FDataSet.EOF and not Terminated do
  begin
    Line := '';
    for i := 0 to FDataSet.FieldCount - 1 do
    begin
      if i > 0 then Line := Line + ';';
      Line := Line + EscapeCsvField(FDataSet.Fields[i].AsString);
    end;
    Line := Line + #13#10;
    Buf := AnsiString(Line);
    AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

    Inc(FCurrentRow);
    if (FCurrentRow mod 100 = 0) then
      Synchronize(@DoSyncProgress);

    FDataSet.Next;
  end;
end;

procedure TDataExportWorkerThread.ExportToJSONL(AStream: TStream);
var
  Line: string;
  i: Integer;
  Buf: AnsiString;
begin
  while not FDataSet.EOF and not Terminated do
  begin
    Line := '{';
    for i := 0 to FDataSet.FieldCount - 1 do
    begin
      if i > 0 then Line := Line + ', ';
      Line := Line + '"' + EscapeJsonString(FDataSet.Fields[i].FieldName) + '": "' +
        EscapeJsonString(FDataSet.Fields[i].AsString) + '"';
    end;
    Line := Line + '}'#10;
    Buf := AnsiString(Line);
    AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

    Inc(FCurrentRow);
    if (FCurrentRow mod 100 = 0) then
      Synchronize(@DoSyncProgress);

    FDataSet.Next;
  end;
end;

procedure TDataExportWorkerThread.ExportToXMLSpreadsheet(AStream: TStream);
var
  Header, Line, Footer: string;
  i: Integer;
  Buf: AnsiString;
begin
  Header := '<?xml version="1.0" encoding="UTF-8"?>'#13#10 +
            '<?mso-application progid="Excel.Sheet"?>'#13#10 +
            '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'#13#10 +
            ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">'#13#10 +
            '<Worksheet ss:Name="ExportedData">'#13#10 +
            '<Table>'#13#10;
  Buf := AnsiString(Header);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

  { Cabeçalho }
  Line := '<Row>';
  for i := 0 to FDataSet.FieldCount - 1 do
    Line := Line + '<Cell><Data ss:Type="String">' + FDataSet.Fields[i].FieldName + '</Data></Cell>';
  Line := Line + '</Row>'#13#10;
  Buf := AnsiString(Line);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

  { Linhas }
  while not FDataSet.EOF and not Terminated do
  begin
    Line := '<Row>';
    for i := 0 to FDataSet.FieldCount - 1 do
      Line := Line + '<Cell><Data ss:Type="String">' + FDataSet.Fields[i].AsString + '</Data></Cell>';
    Line := Line + '</Row>'#13#10;
    Buf := AnsiString(Line);
    AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

    Inc(FCurrentRow);
    if (FCurrentRow mod 100 = 0) then
      Synchronize(@DoSyncProgress);

    FDataSet.Next;
  end;

  Footer := '</Table></Worksheet></Workbook>'#13#10;
  Buf := AnsiString(Footer);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));
end;

procedure TDataExportWorkerThread.Execute;
var
  FS: TFileStream;
begin
  try
    if FDataSet.Active then
    begin
      FDataSet.DisableControls;
      try
        FDataSet.First;
        FTotalRows := FDataSet.RecordCount;

        FS := TFileStream.Create(FFileName, fmCreate);
        try
          case FFormat of
            efCSV:            ExportToCSV(FS);
            efJSONL:          ExportToJSONL(FS);
            efXMLSpreadsheet: ExportToXMLSpreadsheet(FS);
          end;
          FSuccess := not Terminated;
        finally
          FS.Free;
        end;
      finally
        FDataSet.EnableControls;
      end;
    end
    else
    begin
      FErrorMsg := 'DataSet especificado encontra-se fechado (Active = False).';
      FSuccess := False;
    end;
  except
    on E: Exception do
    begin
      FSuccess := False;
      FErrorMsg := E.Message;
    end;
  end;

  Synchronize(@DoSyncComplete);
end;

{ TLazDataExportPipeline }

constructor TLazDataExportPipeline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFormat := efCSV;
  FIsBusy := False;
  FWorkerThread := nil;
end;

destructor TLazDataExportPipeline.Destroy;
begin
  CancelExport;
  inherited Destroy;
end;

procedure TLazDataExportPipeline.StartExport;
begin
  if FIsBusy then
    raise Exception.Create('Pipeline de exportação já se encontra em execução.');

  if not Assigned(FDataSet) then
    raise Exception.Create('Nenhum TDataSet foi associado ao componente de exportação.');

  if Trim(FOutputFile) = '' then
    raise Exception.Create('Caminho do arquivo de saída não foi especificado.');

  FIsBusy := True;
  FWorkerThread := TDataExportWorkerThread.Create(Self, FDataSet, FOutputFile, FFormat);
  FWorkerThread.Start;
end;

procedure TLazDataExportPipeline.CancelExport;
begin
  if FIsBusy and Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FreeAndNil(FWorkerThread);
    FIsBusy := False;
  end;
end;

end.
