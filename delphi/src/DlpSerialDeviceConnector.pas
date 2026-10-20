{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 23: Componentes de Hardware, I/O e Comunicação Serial
  Componente: TDlpSerialDeviceConnector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL & Windows API
  Descrição: Driver de comunicação serial de baixa latência (RS-232 / USB Virtual COM)
             para periféricos de automação comercial e industrial (balanças de checkout,
             leitores ópticos), com leitura assíncrona em worker thread e despacho
             seguro para a UI thread via TThread.Queue.
==============================================================================}
unit DlpSerialDeviceConnector;

interface

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows;

type
  /// <summary>
  /// Paridade para configuração do frame de comunicação serial.
  /// </summary>
  TDlpSerialParity = (spNone, spOdd, spEven);

  /// <summary>
  /// Evento disparado ao receber qualquer sequência de bytes brutos na porta.
  /// </summary>
  TOnDlpSerialDataEvent = procedure(Sender: TObject; const AData: string) of object;

  /// <summary>
  /// Evento disparado ao detectar e decodificar com sucesso um peso de balança.
  /// </summary>
  TOnDlpScaleWeightEvent = procedure(Sender: TObject; WeightKG: Double;
    const RawData: string) of object;

  TDlpSerialDeviceConnector = class;

  /// <summary>
  /// Worker thread dedicada à escuta contínua e sem bloqueio da porta serial.
  /// </summary>
  TDlpSerialReaderThread = class(TThread)
  private
    FConnector: TDlpSerialDeviceConnector;
    FHandle: THandle;
  protected
    procedure Execute; override;
  public
    constructor Create(AConnector: TDlpSerialDeviceConnector; AHandle: THandle);
  end;

  /// <summary>
  /// Componente não-visual de integração com periféricos seriais e hardware.
  /// </summary>
  TDlpSerialDeviceConnector = class(TComponent)
  private
    FPort: string;
    FBaudRate: Integer;
    FDataBits: Integer;
    FStopBits: Integer;
    FParity: TDlpSerialParity;
    FActive: Boolean;
    FPortHandle: THandle;
    FReaderThread: TDlpSerialReaderThread;

    FOnDataReceived: TOnDlpSerialDataEvent;
    FOnWeightReceived: TOnDlpScaleWeightEvent;

    procedure SetActive(const AValue: Boolean);
    procedure ProcessIncomingData(const ARaw: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Abre a porta serial e inicializa a thread de escuta.
    /// </summary>
    procedure Open;

    /// <summary>
    /// Encerra a thread de escuta e fecha o descritor de porta serial.
    /// </summary>
    procedure Close;

    /// <summary>
    /// Transmite uma cadeia de caracteres diretamente para o periférico.
    /// </summary>
    procedure WriteString(const AData: string);

    /// <summary>
    /// Envia o comando ENQ (#5) requisitando a leitura de peso imediata.
    /// </summary>
    procedure RequestWeight;

    /// <summary>
    /// Algoritmo de decodificação para protocolo Toledo / Filizola.
    /// </summary>
    class function ParseToledoWeight(const ARaw: string): Double;
  published
    property Port: string read FPort write FPort;
    property BaudRate: Integer read FBaudRate write FBaudRate default 9600;
    property DataBits: Integer read FDataBits write FDataBits default 8;
    property StopBits: Integer read FStopBits write FStopBits default 1;
    property Parity: TDlpSerialParity read FParity write FParity default spNone;
    property Active: Boolean read FActive write SetActive default False;

    property OnDataReceived: TOnDlpSerialDataEvent read FOnDataReceived write FOnDataReceived;
    property OnWeightReceived: TOnDlpScaleWeightEvent read FOnWeightReceived write FOnWeightReceived;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Component Engineering', [TDlpSerialDeviceConnector]);
end;

{ TDlpSerialReaderThread }

constructor TDlpSerialReaderThread.Create(AConnector: TDlpSerialDeviceConnector;
  AHandle: THandle);
begin
  inherited Create(True);
  FConnector := AConnector;
  FHandle := AHandle;
  FreeOnTerminate := False;
end;

procedure TDlpSerialReaderThread.Execute;
var
  Buffer: array[0..255] of AnsiChar;
  BytesRead: DWORD;
  RawChunk: string;
begin
  while not Terminated do
  begin
    FillChar(Buffer, SizeOf(Buffer), 0);
    if ReadFile(FHandle, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) and (BytesRead > 0) then
    begin
      SetString(RawChunk, PAnsiChar(@Buffer[0]), BytesRead);
      TThread.Queue(nil,
        procedure
        begin
          if FConnector <> nil then
            FConnector.ProcessIncomingData(RawChunk);
        end);
    end
    else
      Sleep(20);
  end;
end;

{ TDlpSerialDeviceConnector }

constructor TDlpSerialDeviceConnector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPort := 'COM1';
  FBaudRate := 9600;
  FDataBits := 8;
  FStopBits := 1;
  FParity := spNone;
  FActive := False;
  FPortHandle := INVALID_HANDLE_VALUE;
  FReaderThread := nil;
end;

destructor TDlpSerialDeviceConnector.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TDlpSerialDeviceConnector.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    if not (csDesigning in ComponentState) and not (csLoading in ComponentState) then
    begin
      if AValue then
        Open
      else
        Close;
    end
    else
      FActive := AValue;
  end;
end;

procedure TDlpSerialDeviceConnector.Open;
var
  PortPath: string;
  DCB: TDCB;
  Timeouts: TCOMMTIMEOUTS;
begin
  if FActive then
    Exit;

  // Prefixo universal \\.\ para suporte a portas COM de 1 a 256
  PortPath := '\\.\' + FPort;
  FPortHandle := CreateFile(PChar(PortPath), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  if FPortHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('TDlpSerialDeviceConnector: Não foi possível abrir a porta %s.', [FPort]);

  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FPortHandle, DCB) then
  begin
    CloseHandle(FPortHandle);
    FPortHandle := INVALID_HANDLE_VALUE;
    raise Exception.Create('TDlpSerialDeviceConnector: Falha ao obter parâmetros DCB da porta.');
  end;

  DCB.BaudRate := FBaudRate;
  DCB.ByteSize := FDataBits;
  case FParity of
    spNone: DCB.Parity := NOPARITY;
    spOdd:  DCB.Parity := ODDPARITY;
    spEven: DCB.Parity := EVENPARITY;
  end;
  DCB.StopBits := ONESTOPBIT;

  SetCommState(FPortHandle, DCB);

  // Configuração de timeouts não-bloqueantes
  Timeouts.ReadIntervalTimeout := MAXDWORD;
  Timeouts.ReadTotalTimeoutMultiplier := 0;
  Timeouts.ReadTotalTimeoutConstant := 100;
  Timeouts.WriteTotalTimeoutMultiplier := 0;
  Timeouts.WriteTotalTimeoutConstant := 500;
  SetCommTimeouts(FPortHandle, Timeouts);

  FActive := True;
  FReaderThread := TDlpSerialReaderThread.Create(Self, FPortHandle);
  FReaderThread.Start;
end;

procedure TDlpSerialDeviceConnector.Close;
begin
  if not FActive then
    Exit;

  if FReaderThread <> nil then
  begin
    FReaderThread.Terminate;
    FReaderThread.WaitFor;
    FreeAndNil(FReaderThread);
  end;

  if FPortHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FPortHandle);
    FPortHandle := INVALID_HANDLE_VALUE;
  end;

  FActive := False;
end;

procedure TDlpSerialDeviceConnector.WriteString(const AData: string);
var
  BytesWritten: DWORD;
  AnsiStr: AnsiString;
begin
  if not FActive or (FPortHandle = INVALID_HANDLE_VALUE) then
    Exit;

  AnsiStr := AnsiString(AData);
  WriteFile(FPortHandle, PAnsiChar(AnsiStr)^, Length(AnsiStr), BytesWritten, nil);
end;

procedure TDlpSerialDeviceConnector.RequestWeight;
begin
  WriteString(#5); // Transmite o caractere ENQ para balanças de checkout
end;

class function TDlpSerialDeviceConnector.ParseToledoWeight(const ARaw: string): Double;
var
  CleanDigits: string;
  i, ValInt: Integer;
begin
  Result := 0.0;
  CleanDigits := '';
  for i := 1 to Length(ARaw) do
  begin
    if CharInSet(ARaw[i], ['0'..'9']) then
      CleanDigits := CleanDigits + ARaw[i];
  end;

  if Length(CleanDigits) >= 5 then
  begin
    CleanDigits := Copy(CleanDigits, Length(CleanDigits) - 4, 5);
    ValInt := StrToIntDef(CleanDigits, 0);
    Result := ValInt / 1000.0;
  end;
end;

procedure TDlpSerialDeviceConnector.ProcessIncomingData(const ARaw: string);
var
  Weight: Double;
begin
  if Assigned(FOnDataReceived) then
    FOnDataReceived(Self, ARaw);

  Weight := ParseToledoWeight(ARaw);
  if (Weight > 0.0) and Assigned(FOnWeightReceived) then
    FOnWeightReceived(Self, Weight, ARaw);
end;

end.
