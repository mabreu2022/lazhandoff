{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 23: Componentes de Hardware, I/O e Comunicação Serial
  Componente: TLazSerialDeviceConnector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Driver não-visual de comunicação serial assíncrona (RS-232 / USB Virtual)
             multiplataforma (Windows e Linux), com leitura em worker thread,
             decodificador de protocolo de balanças de checkout (Toledo, Filizola)
             e despacho para a UI thread via Application.QueueAsyncCall.
==============================================================================}
unit LazSerialDeviceConnector;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms
  {$IFDEF WINDOWS}
  , Windows
  {$ELSE}
  , BaseUnix, Termio
  {$ENDIF}
  ;

type
  { Paridade de transmissão serial }
  TSerialParity = (spNone, spOdd, spEven);

  { Evento de recepção de dados brutos }
  TOnSerialDataEvent = procedure(Sender: TObject; const AData: string) of object;

  { Evento de leitura decodificada de balança de pesagem }
  TOnScaleWeightEvent = procedure(Sender: TObject; WeightKG: Double;
    const RawData: string) of object;

  { Ponteiro para estrutura de despacho assíncrono }
  PSerialPacket = ^TSerialPacket;
  TSerialPacket = record
    Sender: TObject;
    Payload: string;
  end;

  class forward;
  TLazSerialDeviceConnector = class;

  { Thread de leitura assíncrona do descritor de porta serial }
  TLazSerialListenerThread = class(TThread)
  private
    FConnector: TLazSerialDeviceConnector;
    {$IFDEF WINDOWS}
    FHandle: THandle;
    {$ELSE}
    FHandle: cint;
    {$ENDIF}
  protected
    procedure Execute; override;
  public
    {$IFDEF WINDOWS}
    constructor Create(AConnector: TLazSerialDeviceConnector; AHandle: THandle);
    {$ELSE}
    constructor Create(AConnector: TLazSerialDeviceConnector; AHandle: cint);
    {$ENDIF}
  end;

  {============================================================================
    Classe: TLazSerialDeviceConnector
    Conector de portas seriais de automação comercial e industrial
  ============================================================================}
  TLazSerialDeviceConnector = class(TComponent)
  private
    FPort: string;
    FBaudRate: Integer;
    FDataBits: Integer;
    FStopBits: Integer;
    FParity: TSerialParity;
    FActive: Boolean;
    FReaderThread: TLazSerialListenerThread;
    {$IFDEF WINDOWS}
    FPortHandle: THandle;
    {$ELSE}
    FPortHandle: cint;
    {$ENDIF}

    FOnDataReceived: TOnSerialDataEvent;
    FOnWeightReceived: TOnScaleWeightEvent;

    procedure SetActive(const AValue: Boolean);
    procedure DispatchDataToUI(Data: PtrInt);
    procedure ProcessIncomingProtocol(const ARawString: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Abertura e encerramento da porta }
    procedure Open;
    procedure Close;

    { Transmissão de comandos para a balança / periférico }
    procedure WriteString(const ACommand: string);

    { Solicita pesagem padrão (comando ENQ #5) para balanças Toledo/Filizola }
    procedure RequestWeight;

    { Decodifica formatos como STX + 5 digitos de peso + ETX }
    class function ParseToledoWeight(const ARaw: string): Double;
  published
    property Port: string read FPort write FPort;
    property BaudRate: Integer read FBaudRate write FBaudRate default 9600;
    property DataBits: Integer read FDataBits write FDataBits default 8;
    property StopBits: Integer read FStopBits write FStopBits default 1;
    property Parity: TSerialParity read FParity write FParity default spNone;
    property Active: Boolean read FActive write SetActive default False;

    property OnDataReceived: TOnSerialDataEvent read FOnDataReceived write FOnDataReceived;
    property OnWeightReceived: TOnScaleWeightEvent read FOnWeightReceived write FOnWeightReceived;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazSerialDeviceConnector]);
end;

{ TLazSerialListenerThread }

{$IFDEF WINDOWS}
constructor TLazSerialListenerThread.Create(AConnector: TLazSerialDeviceConnector;
  AHandle: THandle);
begin
  inherited Create(True);
  FConnector := AConnector;
  FHandle := AHandle;
  FreeOnTerminate := False;
end;

procedure TLazSerialListenerThread.Execute;
var
  Buffer: array[0..255] of AnsiChar;
  BytesRead: DWORD;
  Packet: PSerialPacket;
  RawChunk: string;
begin
  while not Terminated do
  begin
    FillChar(Buffer, SizeOf(Buffer), 0);
    if ReadFile(FHandle, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) and (BytesRead > 0) then
    begin
      SetString(RawChunk, PAnsiChar(@Buffer[0]), BytesRead);
      New(Packet);
      Packet^.Sender := FConnector;
      Packet^.Payload := RawChunk;
      Application.QueueAsyncCall(@FConnector.DispatchDataToUI, PtrInt(Packet));
    end
    else
      Sleep(20);
  end;
end;
{$ELSE}
constructor TLazSerialListenerThread.Create(AConnector: TLazSerialDeviceConnector;
  AHandle: cint);
begin
  inherited Create(True);
  FConnector := AConnector;
  FHandle := AHandle;
  FreeOnTerminate := False;
end;

procedure TLazSerialListenerThread.Execute;
var
  Buffer: array[0..255] of AnsiChar;
  BytesRead: tsizet;
  Packet: PSerialPacket;
  RawChunk: string;
begin
  while not Terminated do
  begin
    FillChar(Buffer, SizeOf(Buffer), 0);
    BytesRead := FpRead(FHandle, @Buffer[0], SizeOf(Buffer) - 1);
    if BytesRead > 0 then
    begin
      SetString(RawChunk, PAnsiChar(@Buffer[0]), BytesRead);
      New(Packet);
      Packet^.Sender := FConnector;
      Packet^.Payload := RawChunk;
      Application.QueueAsyncCall(@FConnector.DispatchDataToUI, PtrInt(Packet));
    end
    else
      Sleep(20);
  end;
end;
{$ENDIF}

{ TLazSerialDeviceConnector }

constructor TLazSerialDeviceConnector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IFDEF WINDOWS}
  FPort := 'COM1';
  FPortHandle := INVALID_HANDLE_VALUE;
  {$ELSE}
  FPort := '/dev/ttyUSB0';
  FPortHandle := -1;
  {$ENDIF}
  FBaudRate := 9600;
  FDataBits := 8;
  FStopBits := 1;
  FParity := spNone;
  FActive := False;
  FReaderThread := nil;
end;

destructor TLazSerialDeviceConnector.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TLazSerialDeviceConnector.SetActive(const AValue: Boolean);
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

procedure TLazSerialDeviceConnector.Open;
{$IFDEF WINDOWS}
var
  PortPath: string;
  DCB: TDCB;
  Timeouts: TCOMMTIMEOUTS;
begin
  if FActive then
    Exit;

  // Formato com prefixo para suportar portas COM acima de 9
  PortPath := '\\.\' + FPort;
  FPortHandle := CreateFile(PChar(PortPath), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  if FPortHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('TLazSerialDeviceConnector: Falha ao abrir porta %s.', [FPort]);

  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FPortHandle, DCB) then
  begin
    CloseHandle(FPortHandle);
    FPortHandle := INVALID_HANDLE_VALUE;
    raise Exception.Create('TLazSerialDeviceConnector: Não foi possível obter CommState.');
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

  // Timeouts não-bloqueantes
  Timeouts.ReadIntervalTimeout := MAXDWORD;
  Timeouts.ReadTotalTimeoutMultiplier := 0;
  Timeouts.ReadTotalTimeoutConstant := 100;
  Timeouts.WriteTotalTimeoutMultiplier := 0;
  Timeouts.WriteTotalTimeoutConstant := 500;
  SetCommTimeouts(FPortHandle, Timeouts);

  FActive := True;
  FReaderThread := TLazSerialListenerThread.Create(Self, FPortHandle);
  FReaderThread.Start;
end;
{$ELSE}
var
  TIO: Termios;
  BaudFlag: Cardinal;
begin
  if FActive then
    Exit;

  FPortHandle := FpOpen(FPort, O_RDWR or O_NOCTTY or O_NONBLOCK);
  if FPortHandle < 0 then
    raise Exception.CreateFmt('TLazSerialDeviceConnector: Falha ao abrir porta %s.', [FPort]);

  TCGetAttr(FPortHandle, TIO);
  case FBaudRate of
    9600:   BaudFlag := B9600;
    19200:  BaudFlag := B19200;
    38400:  BaudFlag := B38400;
    115200: BaudFlag := B115200;
    else    BaudFlag := B9600;
  end;
  CFSetISpeed(TIO, BaudFlag);
  CFSetOSpeed(TIO, BaudFlag);

  TIO.c_cflag := TIO.c_cflag or (CLOCAL or CREAD);
  TIO.c_cflag := TIO.c_cflag and not CSIZE;
  TIO.c_cflag := TIO.c_cflag or CS8;
  TIO.c_cflag := TIO.c_cflag and not PARENB;
  TIO.c_cflag := TIO.c_cflag and not CSTOPB;
  TCSetAttr(FPortHandle, TCSANOW, TIO);

  FActive := True;
  FReaderThread := TLazSerialListenerThread.Create(Self, FPortHandle);
  FReaderThread.Start;
end;
{$ENDIF}

procedure TLazSerialDeviceConnector.Close;
begin
  if not FActive then
    Exit;

  if FReaderThread <> nil then
  begin
    FReaderThread.Terminate;
    FReaderThread.WaitFor;
    FreeAndNil(FReaderThread);
  end;

  {$IFDEF WINDOWS}
  if FPortHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FPortHandle);
    FPortHandle := INVALID_HANDLE_VALUE;
  end;
  {$ELSE}
  if FPortHandle >= 0 then
  begin
    FpClose(FPortHandle);
    FPortHandle := -1;
  end;
  {$ENDIF}

  FActive := False;
end;

procedure TLazSerialDeviceConnector.WriteString(const ACommand: string);
{$IFDEF WINDOWS}
var
  BytesWritten: DWORD;
begin
  if not FActive or (FPortHandle = INVALID_HANDLE_VALUE) then
    Exit;
  WriteFile(FPortHandle, PAnsiChar(ACommand)^, Length(ACommand), BytesWritten, nil);
end;
{$ELSE}
begin
  if not FActive or (FPortHandle < 0) then
    Exit;
  FpWrite(FPortHandle, PAnsiChar(ACommand), Length(ACommand));
end;
{$ENDIF}

procedure TLazSerialDeviceConnector.RequestWeight;
begin
  WriteString(#5); // Envia ENQ (Enquiry) para requisitar peso
end;

class function TLazSerialDeviceConnector.ParseToledoWeight(const ARaw: string): Double;
var
  CleanDigits: string;
  i: Integer;
  ValInt: Integer;
begin
  Result := 0.0;
  CleanDigits := '';
  for i := 1 to Length(ARaw) do
  begin
    if ARaw[i] in ['0'..'9'] then
      CleanDigits := CleanDigits + ARaw[i];
  end;

  // Formato padrão: 5 dígitos representando peso com 3 casas decimais (ex.: 01500 = 1.500 kg)
  if Length(CleanDigits) >= 5 then
  begin
    CleanDigits := Copy(CleanDigits, Length(CleanDigits) - 4, 5);
    ValInt := StrToIntDef(CleanDigits, 0);
    Result := ValInt / 1000.0;
  end;
end;

procedure TLazSerialDeviceConnector.ProcessIncomingProtocol(const ARawString: string);
var
  Weight: Double;
begin
  if Assigned(FOnDataReceived) then
    FOnDataReceived(Self, ARawString);

  // Decodifica protocolo de balança se contiver sequência numérica de pesagem
  Weight := ParseToledoWeight(ARawString);
  if (Weight > 0.0) and Assigned(FOnWeightReceived) then
    FOnWeightReceived(Self, Weight, ARawString);
end;

procedure TLazSerialDeviceConnector.DispatchDataToUI(Data: PtrInt);
var
  Packet: PSerialPacket;
begin
  Packet := PSerialPacket(Data);
  try
    if (Packet <> nil) then
      ProcessIncomingProtocol(Packet^.Payload);
  finally
    Dispose(Packet);
  end;
end;

end.
