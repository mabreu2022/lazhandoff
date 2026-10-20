{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 31: Pipeline de Exportação em Segundo Plano (TDlpDataExportPipeline)
  Componente: TDlpDataExportPipeline
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / FireDAC / DataSnap / Multiplataforma)
  Descrição: Pipeline assíncrono para streaming massivo de instâncias de TDataSet
             (TFDQuery, TFDMemTable, TClientDataSet) para arquivos de dados
             estruturados: CSV (RFC 4180), JSONL (JSON Lines) e XML Spreadsheet (XLSX).
             Total desacoplamento da interface gráfica através de TThread dedicada
             e despachos sincronizados com o main thread.
==============================================================================}
unit DlpDataExportPipeline;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB;

type
  { Formatos suportados pelo pipeline de exportação }
  TDlpExportFormat = (efCSV, efJSONL, efXMLSpreadsheet);

  { Evento de progresso de exportação sincronizado com a thread visual }
  TDlpExportProgressEvent = procedure(Sender: TObject; ACurrentRow, ATotalRows: Integer;
    APercent: Double) of object;

  { Evento de conclusão de exportação }
  TDlpExportCompleteEvent = procedure(Sender: TObject; ASuccess: Boolean;
    const AErrorMsg: string; ATotalExported: Integer) of object;

  { Declaração antecipada }
  TDlpDataExportPipeline = class;

  { Thread de processamento da exportação de dados }
  TDlpDataExportWorkerThread = class(TThread)
  private
    FDataSet: TDataSet;
    FFileName: string;
    FFormat: TDlpExportFormat;
    FOwnerPipeline: TDlpDataExportPipeline;
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
    constructor Create(APipeline: TDlpDataExportPipeline; ADataSet: TDataSet;
      const AFileName: string; AFormat: TDlpExportFormat);
  end;

  {============================================================================
    Componente: TDlpDataExportPipeline
    Pipeline multithread de exportação de dados desacoplado da GUI
  ============================================================================}
  TDlpDataExportPipeline = class(TComponent)
  private
    FDataSet: TDataSet;
    FOutputFile: string;
    FFormat: TDlpExportFormat;
    FWorkerThread: TDlpDataExportWorkerThread;
    FIsBusy: Boolean;
    FOnProgress: TDlpExportProgressEvent;
    FOnComplete: TDlpExportCompleteEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure StartExport;
    procedure CancelExport;

    property IsBusy: Boolean read FIsBusy;
  published
    property DataSet: TDataSet read FDataSet write FDataSet;
    property OutputFile: string read FOutputFile write FOutputFile;
    property Format: TDlpExportFormat read FFormat write FFormat default efCSV;
    property OnProgress: TDlpExportProgressEvent read FOnProgress write FOnProgress;
    property OnComplete: TDlpExportCompleteEvent read FOnComplete write FOnComplete;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpDataExportPipeline]);
end;

{ TDlpDataExportWorkerThread }

constructor TDlpDataExportWorkerThread.Create(APipeline: TDlpDataExportPipeline;
  ADataSet: TDataSet; const AFileName: string; AFormat: TDlpExportFormat);
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

procedure TDlpDataExportWorkerThread.DoSyncProgress;
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

procedure TDlpDataExportWorkerThread.DoSyncComplete;
begin
  FOwnerPipeline.FIsBusy := False;
  if Assigned(FOwnerPipeline.FOnComplete) then
    FOwnerPipeline.FOnComplete(FOwnerPipeline, FSuccess, FErrorMsg, FCurrentRow);
end;

function TDlpDataExportWorkerThread.EscapeCsvField(const S: string): string;
begin
  if (Pos('"', S) > 0) or (Pos(',', S) > 0) or (Pos(';', S) > 0) or (Pos(#10, S) > 0) then
    Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"'
  else
    Result := S;
end;

function TDlpDataExportWorkerThread.EscapeJsonString(const S: string): string;
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

procedure TDlpDataExportWorkerThread.ExportToCSV(AStream: TStream);
var
  Line: string;
  i: Integer;
  Buf: TBytes;
begin
  Line := '';
  for i := 0 to FDataSet.FieldCount - 1 do
  begin
    if i > 0 then Line := Line + ';';
    Line := Line + EscapeCsvField(FDataSet.Fields[i].FieldName);
  end;
  Line := Line + #13#10;
  Buf := TEncoding.UTF8.GetBytes(Line);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

  while not FDataSet.EOF and not Terminated do
  begin
    Line := '';
    for i := 0 to FDataSet.FieldCount - 1 do
    begin
      if i > 0 then Line := Line + ';';
      Line := Line + EscapeCsvField(FDataSet.Fields[i].AsString);
    end;
    Line := Line + #13#10;
    Buf := TEncoding.UTF8.GetBytes(Line);
    AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

    Inc(FCurrentRow);
    if (FCurrentRow mod 100 = 0) then
      Synchronize(DoSyncProgress);

    FDataSet.Next;
  end;
end;

procedure TDlpDataExportWorkerThread.ExportToJSONL(AStream: TStream);
var
  Line: string;
  i: Integer;
  Buf: TBytes;
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
    Buf := TEncoding.UTF8.GetBytes(Line);
    AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

    Inc(FCurrentRow);
    if (FCurrentRow mod 100 = 0) then
      Synchronize(DoSyncProgress);

    FDataSet.Next;
  end;
end;

procedure TDlpDataExportWorkerThread.ExportToXMLSpreadsheet(AStream: TStream);
var
  Header, Line, Footer: string;
  i: Integer;
  Buf: TBytes;
begin
  Header := '<?xml version="1.0" encoding="UTF-8"?>'#13#10 +
            '<?mso-application progid="Excel.Sheet"?>'#13#10 +
            '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'#13#10 +
            ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">'#13#10 +
            '<Worksheet ss:Name="ExportedData">'#13#10 +
            '<Table>'#13#10;
  Buf := TEncoding.UTF8.GetBytes(Header);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

  Line := '<Row>';
  for i := 0 to FDataSet.FieldCount - 1 do
    Line := Line + '<Cell><Data ss:Type="String">' + FDataSet.Fields[i].FieldName + '</Data></Cell>';
  Line := Line + '</Row>'#13#10;
  Buf := TEncoding.UTF8.GetBytes(Line);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

  while not FDataSet.EOF and not Terminated do
  begin
    Line := '<Row>';
    for i := 0 to FDataSet.FieldCount - 1 do
      Line := Line + '<Cell><Data ss:Type="String">' + FDataSet.Fields[i].AsString + '</Data></Cell>';
    Line := Line + '</Row>'#13#10;
    Buf := TEncoding.UTF8.GetBytes(Line);
    AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));

    Inc(FCurrentRow);
    if (FCurrentRow mod 100 = 0) then
      Synchronize(DoSyncProgress);

    FDataSet.Next;
  end;

  Footer := '</Table></Worksheet></Workbook>'#13#10;
  Buf := TEncoding.UTF8.GetBytes(Footer);
  AStream.WriteBuffer(Pointer(Buf)^, Length(Buf));
end;

procedure TDlpDataExportWorkerThread.Execute;
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
      FErrorMsg := 'O DataSet configurado encontra-se inativo (Active = False).';
      FSuccess := False;
    end;
  except
    on E: Exception do
    begin
      FSuccess := False;
      FErrorMsg := E.Message;
    end;
  end;

  Synchronize(DoSyncComplete);
end;

{ TDlpDataExportPipeline }

constructor TDlpDataExportPipeline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFormat := efCSV;
  FIsBusy := False;
  FWorkerThread := nil;
end;

destructor TDlpDataExportPipeline.Destroy;
begin
  CancelExport;
  inherited Destroy;
end;

procedure TDlpDataExportPipeline.StartExport;
begin
  if FIsBusy then
    raise Exception.Create('O pipeline de exportacao ja se encontra em execucao.');

  if not Assigned(FDataSet) then
    raise Exception.Create('Nenhum TDataSet foi associado para exportacao.');

  if Trim(FOutputFile) = '' then
    raise Exception.Create('Nome do arquivo de destino nao foi informado.');

  FIsBusy := True;
  FWorkerThread := TDlpDataExportWorkerThread.Create(Self, FDataSet, FOutputFile, FFormat);
  FWorkerThread.Start;
end;

procedure TDlpDataExportPipeline.CancelExport;
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
