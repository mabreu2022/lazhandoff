{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 22: Componentes de Comunicação de Rede e Consumo de APIs
  Componente: TDlpRestClientBridge
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL & FMX
  Descrição: Cliente HTTP RESTful de alta performance baseado em System.Net.HttpClient,
             suporte a JWT/Bearer Token, headers customizados, serialização JSON
             e despachos assíncronos não-bloqueantes para a UI thread via PPL.
==============================================================================}
unit DlpRestClientBridge;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Threading;

type
  /// <summary>
  /// Procedimento anônimo de retorno assíncrono de resposta HTTP na UI thread.
  /// </summary>
  TOnDlpRestResponseEvent = reference to procedure(StatusCode: Integer;
    const ResponseBody, ErrorMsg: string);

  /// <summary>
  /// Cliente RESTful não-visual multiplataforma para o Delphi 12 Athens+.
  /// </summary>
  TDlpRestClientBridge = class(TComponent)
  private
    FBaseURL: string;
    FBearerToken: string;
    FTimeoutSeconds: Integer;
    FCustomHeaders: TStrings;

    procedure SetCustomHeaders(const AValue: TStrings);
    function CreateConfiguredClient: THTTPClient;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Executa uma requisição HTTP GET síncrona.
    /// </summary>
    function Get(const Endpoint: string): string;

    /// <summary>
    /// Executa uma requisição HTTP POST síncrona com payload JSON.
    /// </summary>
    function Post(const Endpoint, JsonBody: string): string;

    /// <summary>
    /// Executa uma requisição HTTP PUT síncrona com payload JSON.
    /// </summary>
    function Put(const Endpoint, JsonBody: string): string;

    /// <summary>
    /// Executa uma requisição HTTP DELETE síncrona.
    /// </summary>
    function Delete(const Endpoint: string): Integer;

    /// <summary>
    /// Executa qualquer verbo HTTP em background com callback na UI thread.
    /// </summary>
    procedure ExecuteAsync(const Method, Endpoint, JsonBody: string;
      Callback: TOnDlpRestResponseEvent);
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
  RegisterComponents('Delphi Component Engineering', [TDlpRestClientBridge]);
end;

{ TDlpRestClientBridge }

constructor TDlpRestClientBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBaseURL := '';
  FBearerToken := '';
  FTimeoutSeconds := 30;
  FCustomHeaders := TStringList.Create;
end;

destructor TDlpRestClientBridge.Destroy;
begin
  FreeAndNil(FCustomHeaders);
  inherited Destroy;
end;

procedure TDlpRestClientBridge.SetCustomHeaders(const AValue: TStrings);
begin
  FCustomHeaders.Assign(AValue);
end;

function TDlpRestClientBridge.CreateConfiguredClient: THTTPClient;
var
  i: Integer;
begin
  Result := THTTPClient.Create;
  Result.ConnectionTimeout := FTimeoutSeconds * 1000;
  Result.ResponseTimeout := FTimeoutSeconds * 1000;
  Result.Accept := 'application/json';

  if FBearerToken <> '' then
    Result.CustomHeaders['Authorization'] := 'Bearer ' + FBearerToken;

  for i := 0 to FCustomHeaders.Count - 1 do
    Result.CustomHeaders[FCustomHeaders.Names[i]] := FCustomHeaders.ValueFromIndex[i];
end;

function TDlpRestClientBridge.Get(const Endpoint: string): string;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
begin
  Client := CreateConfiguredClient;
  try
    Resp := Client.Get(FBaseURL + Endpoint);
    Result := Resp.ContentAsString(TEncoding.UTF8);
  finally
    Client.Free;
  end;
end;

function TDlpRestClientBridge.Post(const Endpoint, JsonBody: string): string;
var
  Client: THTTPClient;
  Stream: TStringStream;
  Resp: IHTTPResponse;
begin
  Client := CreateConfiguredClient;
  Stream := TStringStream.Create(JsonBody, TEncoding.UTF8);
  try
    Client.ContentType := 'application/json';
    Resp := Client.Post(FBaseURL + Endpoint, Stream);
    Result := Resp.ContentAsString(TEncoding.UTF8);
  finally
    Stream.Free;
    Client.Free;
  end;
end;

function TDlpRestClientBridge.Put(const Endpoint, JsonBody: string): string;
var
  Client: THTTPClient;
  Stream: TStringStream;
  Resp: IHTTPResponse;
begin
  Client := CreateConfiguredClient;
  Stream := TStringStream.Create(JsonBody, TEncoding.UTF8);
  try
    Client.ContentType := 'application/json';
    Resp := Client.Put(FBaseURL + Endpoint, Stream);
    Result := Resp.ContentAsString(TEncoding.UTF8);
  finally
    Stream.Free;
    Client.Free;
  end;
end;

function TDlpRestClientBridge.Delete(const Endpoint: string): Integer;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
begin
  Client := CreateConfiguredClient;
  try
    Resp := Client.Delete(FBaseURL + Endpoint);
    Result := Resp.StatusCode;
  finally
    Client.Free;
  end;
end;

procedure TDlpRestClientBridge.ExecuteAsync(const Method, Endpoint, JsonBody: string;
  Callback: TOnDlpRestResponseEvent);
var
  LocalURL, LocalMethod, LocalBody, LocalToken: string;
  LocalTimeout: Integer;
  LocalHeaders: TStringList;
begin
  LocalURL := FBaseURL + Endpoint;
  LocalMethod := UpperCase(Method);
  LocalBody := JsonBody;
  LocalToken := FBearerToken;
  LocalTimeout := FTimeoutSeconds;

  LocalHeaders := TStringList.Create;
  LocalHeaders.Assign(FCustomHeaders);

  TTask.Run(
    procedure
    var
      Client: THTTPClient;
      Resp: IHTTPResponse;
      Stream: TStringStream;
      StatusCode: Integer;
      ResponseBody: string;
      ErrorMsg: string;
      i: Integer;
    begin
      StatusCode := 0;
      ResponseBody := '';
      ErrorMsg := '';
      Stream := nil;
      Client := THTTPClient.Create;
      try
        try
          Client.ConnectionTimeout := LocalTimeout * 1000;
          Client.ResponseTimeout := LocalTimeout * 1000;
          Client.Accept := 'application/json';

          if LocalToken <> '' then
            Client.CustomHeaders['Authorization'] := 'Bearer ' + LocalToken;

          for i := 0 to LocalHeaders.Count - 1 do
            Client.CustomHeaders[LocalHeaders.Names[i]] := LocalHeaders.ValueFromIndex[i];

          if (LocalMethod = 'POST') or (LocalMethod = 'PUT') then
          begin
            Client.ContentType := 'application/json';
            Stream := TStringStream.Create(LocalBody, TEncoding.UTF8);
          end;

          if LocalMethod = 'GET' then
            Resp := Client.Get(LocalURL)
          else if LocalMethod = 'POST' then
            Resp := Client.Post(LocalURL, Stream)
          else if LocalMethod = 'PUT' then
            Resp := Client.Put(LocalURL, Stream)
          else if LocalMethod = 'DELETE' then
            Resp := Client.Delete(LocalURL)
          else
            raise Exception.Create('Método HTTP não suportado: ' + LocalMethod);

          StatusCode := Resp.StatusCode;
          ResponseBody := Resp.ContentAsString(TEncoding.UTF8);
        except
          on E: Exception do
          begin
            StatusCode := 500;
            ErrorMsg := E.Message;
          end;
        end;
      finally
        if Stream <> nil then
          Stream.Free;
        Client.Free;
        LocalHeaders.Free;
      end;

      TThread.Queue(nil,
        procedure
        begin
          if Assigned(Callback) then
            Callback(StatusCode, ResponseBody, ErrorMsg);
        end);
    end);
end;

end.
