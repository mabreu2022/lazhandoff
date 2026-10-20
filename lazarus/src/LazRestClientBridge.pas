{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 22: Componentes de Comunicação de Rede e Consumo de APIs
  Componente: TLazRestClientBridge
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+ / fphttpclient & fpjson
  Descrição: Cliente HTTP RESTful não-visual de alta fidelidade para integração
             com microsserviços e APIs web modernas. Suporta Bearer Tokens,
             cabeçalhos customizados, payloads JSON e chamadas assíncronas.
==============================================================================}
unit LazRestClientBridge;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  fphttpclient,
  fpjson,
  jsonparser;

type
  { Assinatura do callback de resposta assíncrona na UI thread }
  TOnRestResponseEvent = procedure(Sender: TObject; StatusCode: Integer;
    const ResponseBody, ErrorMsg: string) of object;

  { Estrutura para passagem de dados para o loop assíncrono }
  PRestResponseData = ^TRestResponseData;
  TRestResponseData = record
    Sender: TObject;
    StatusCode: Integer;
    ResponseBody: string;
    ErrorMsg: string;
    Callback: TOnRestResponseEvent;
  end;

  class forward;
  TLazRestClientBridge = class;

  { Thread interna para execução assíncrona de requisições de rede }
  TLazRestWorkerThread = class(TThread)
  private
    FBridge: TLazRestClientBridge;
    FMethod: string;
    FURL: string;
    FBody: string;
    FToken: string;
    FTimeout: Integer;
    FHeaders: TStringList;
    FCallback: TOnRestResponseEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(ABridge: TLazRestClientBridge; const AMethod, AURL, ABody,
      AToken: string; ATimeout: Integer; AHeaders: TStrings; ACallback: TOnRestResponseEvent);
    destructor Destroy; override;
  end;

  {============================================================================
    Classe: TLazRestClientBridge
    Ponte de integração de rede RESTful para aplicações LCL
  ============================================================================}
  TLazRestClientBridge = class(TComponent)
  private
    FBaseURL: string;
    FBearerToken: string;
    FTimeoutSeconds: Integer;
    FCustomHeaders: TStrings;

    procedure SetCustomHeaders(const AValue: TStrings);
    procedure AsyncDispatchResponse(Data: PtrInt);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos síncronos de chamada HTTP }
    function Get(const Endpoint: string): string;
    function Post(const Endpoint, JsonBody: string): string;
    function Put(const Endpoint, JsonBody: string): string;
    function Delete(const Endpoint: string): Integer;

    { Método universal de execução assíncrona }
    procedure ExecuteAsync(const Method, Endpoint, JsonBody: string;
      ACallback: TOnRestResponseEvent);
  published
    property BaseURL: string read FBaseURL write FBaseURL;
    property BearerToken: string read FBearerToken write FBearerToken;
    property TimeoutSeconds: Integer read FTimeoutSeconds write FTimeoutSeconds default 30;
    property CustomHeaders: TStrings read FCustomHeaders write SetCustomHeaders;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazRestClientBridge]);
end;

{ TLazRestWorkerThread }

constructor TLazRestWorkerThread.Create(ABridge: TLazRestClientBridge;
  const AMethod, AURL, ABody, AToken: string; ATimeout: Integer;
  AHeaders: TStrings; ACallback: TOnRestResponseEvent);
begin
  inherited Create(True);
  FBridge := ABridge;
  FMethod := AMethod;
  FURL := AURL;
  FBody := ABody;
  FToken := AToken;
  FTimeout := ATimeout;
  FCallback := ACallback;
  FHeaders := TStringList.Create;
  if AHeaders <> nil then
    FHeaders.Assign(AHeaders);
  FreeOnTerminate := True;
end;

destructor TLazRestWorkerThread.Destroy;
begin
  FreeAndNil(FHeaders);
  inherited Destroy;
end;

procedure TLazRestWorkerThread.Execute;
var
  Client: TFPHTTPClient;
  RespStream: TStringStream;
  ReqStream: TStringStream;
  RespData: PRestResponseData;
  i: Integer;
begin
  New(RespData);
  RespData^.Sender := FBridge;
  RespData^.StatusCode := 0;
  RespData^.ResponseBody := '';
  RespData^.ErrorMsg := '';
  RespData^.Callback := FCallback;

  Client := TFPHTTPClient.Create(nil);
  RespStream := TStringStream.Create('');
  ReqStream := nil;
  try
    try
      Client.IOTimeout := FTimeout * 1000;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');

      if FToken <> '' then
        Client.AddHeader('Authorization', 'Bearer ' + FToken);

      for i := 0 to FHeaders.Count - 1 do
        Client.AddHeader(FHeaders.Names[i], FHeaders.ValueFromIndex[i]);

      if (FMethod = 'POST') or (FMethod = 'PUT') then
      begin
        ReqStream := TStringStream.Create(FBody);
        Client.RequestBody := ReqStream;
      end;

      Client.HTTPMethod(FMethod, FURL, RespStream, [200, 201, 204, 400, 401, 403, 404, 500]);
      RespData^.StatusCode := Client.ResponseStatusCode;
      RespData^.ResponseBody := RespStream.DataString;
    except
      on E: Exception do
      begin
        RespData^.StatusCode := 500;
        RespData^.ErrorMsg := E.Message;
      end;
    end;
  finally
    Client.Free;
    RespStream.Free;
    if ReqStream <> nil then
      ReqStream.Free;
  end;

  Application.QueueAsyncCall(@FBridge.AsyncDispatchResponse, PtrInt(RespData));
end;

{ TLazRestClientBridge }

constructor TLazRestClientBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBaseURL := '';
  FBearerToken := '';
  FTimeoutSeconds := 30;
  FCustomHeaders := TStringList.Create;
end;

destructor TLazRestClientBridge.Destroy;
begin
  FreeAndNil(FCustomHeaders);
  inherited Destroy;
end;

procedure TLazRestClientBridge.SetCustomHeaders(const AValue: TStrings);
begin
  FCustomHeaders.Assign(AValue);
end;

procedure TLazRestClientBridge.AsyncDispatchResponse(Data: PtrInt);
var
  DataPtr: PRestResponseData;
begin
  DataPtr := PRestResponseData(Data);
  try
    if (DataPtr <> nil) and Assigned(DataPtr^.Callback) then
      DataPtr^.Callback(DataPtr^.Sender, DataPtr^.StatusCode, DataPtr^.ResponseBody, DataPtr^.ErrorMsg);
  finally
    Dispose(DataPtr);
  end;
end;

function TLazRestClientBridge.Get(const Endpoint: string): string;
var
  Client: TFPHTTPClient;
  FullURL: string;
  i: Integer;
begin
  FullURL := FBaseURL + Endpoint;
  Client := TFPHTTPClient.Create(nil);
  try
    Client.IOTimeout := FTimeoutSeconds * 1000;
    Client.AddHeader('Accept', 'application/json');
    if FBearerToken <> '' then
      Client.AddHeader('Authorization', 'Bearer ' + FBearerToken);

    for i := 0 to FCustomHeaders.Count - 1 do
      Client.AddHeader(FCustomHeaders.Names[i], FCustomHeaders.ValueFromIndex[i]);

    Result := Client.Get(FullURL);
  finally
    Client.Free;
  end;
end;

function TLazRestClientBridge.Post(const Endpoint, JsonBody: string): string;
var
  Client: TFPHTTPClient;
  FullURL: string;
  i: Integer;
begin
  FullURL := FBaseURL + Endpoint;
  Client := TFPHTTPClient.Create(nil);
  try
    Client.IOTimeout := FTimeoutSeconds * 1000;
    Client.AddHeader('Content-Type', 'application/json');
    Client.AddHeader('Accept', 'application/json');
    if FBearerToken <> '' then
      Client.AddHeader('Authorization', 'Bearer ' + FBearerToken);

    for i := 0 to FCustomHeaders.Count - 1 do
      Client.AddHeader(FCustomHeaders.Names[i], FCustomHeaders.ValueFromIndex[i]);

    Result := Client.FormPost(FullURL, JsonBody);
  finally
    Client.Free;
  end;
end;

function TLazRestClientBridge.Put(const Endpoint, JsonBody: string): string;
var
  Client: TFPHTTPClient;
  FullURL: string;
  ReqStream, RespStream: TStringStream;
  i: Integer;
begin
  FullURL := FBaseURL + Endpoint;
  Client := TFPHTTPClient.Create(nil);
  ReqStream := TStringStream.Create(JsonBody);
  RespStream := TStringStream.Create('');
  try
    Client.IOTimeout := FTimeoutSeconds * 1000;
    Client.AddHeader('Content-Type', 'application/json');
    Client.AddHeader('Accept', 'application/json');
    if FBearerToken <> '' then
      Client.AddHeader('Authorization', 'Bearer ' + FBearerToken);

    for i := 0 to FCustomHeaders.Count - 1 do
      Client.AddHeader(FCustomHeaders.Names[i], FCustomHeaders.ValueFromIndex[i]);

    Client.RequestBody := ReqStream;
    Client.HTTPMethod('PUT', FullURL, RespStream, [200, 201, 204]);
    Result := RespStream.DataString;
  finally
    ReqStream.Free;
    RespStream.Free;
    Client.Free;
  end;
end;

function TLazRestClientBridge.Delete(const Endpoint: string): Integer;
var
  Client: TFPHTTPClient;
  FullURL: string;
  RespStream: TStringStream;
  i: Integer;
begin
  FullURL := FBaseURL + Endpoint;
  Client := TFPHTTPClient.Create(nil);
  RespStream := TStringStream.Create('');
  try
    Client.IOTimeout := FTimeoutSeconds * 1000;
    if FBearerToken <> '' then
      Client.AddHeader('Authorization', 'Bearer ' + FBearerToken);

    for i := 0 to FCustomHeaders.Count - 1 do
      Client.AddHeader(FCustomHeaders.Names[i], FCustomHeaders.ValueFromIndex[i]);

    Client.HTTPMethod('DELETE', FullURL, RespStream, [200, 204]);
    Result := Client.ResponseStatusCode;
  finally
    RespStream.Free;
    Client.Free;
  end;
end;

procedure TLazRestClientBridge.ExecuteAsync(const Method, Endpoint, JsonBody: string;
  ACallback: TOnRestResponseEvent);
var
  FullURL: string;
  Worker: TLazRestWorkerThread;
begin
  FullURL := FBaseURL + Endpoint;
  Worker := TLazRestWorkerThread.Create(Self, Method, FullURL, JsonBody,
    FBearerToken, FTimeoutSeconds, FCustomHeaders, ACallback);
  Worker.Start;
end;

end.
