{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 47: Gerenciador de Pool de Conexões SQL (TDlpDatabaseConnectionPool)
  Componente: TDlpDatabaseConnectionPool
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / FireDAC / DataSnap / Multiplataforma)
  Descrição: Gerenciador thread-safe de pool de conexões (FireDAC TFDConnection).
             Implementa alocação antecipada (MinConnections), teto escalável
             (MaxConnections), empréstimo (Acquire) e devolução (Release) com timeout,
             e expurgo automático de conexões ociosas ou zumbis.
==============================================================================}
unit DlpDatabaseConnectionPool;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  { Item encapsulado do pool de conexões }
  TDlpPooledConnection = class
  public
    ConnectionInstance: TObject;
    InUse: Boolean;
    CreatedAt: TDateTime;
    LastUsedAt: TDateTime;
    UsageCount: Integer;
  end;

  { Assinatura de fabricação de conexão pelo usuário }
  TDlpCreateConnectionEvent = procedure(Sender: TObject; out NewConnection: TObject) of object;

  { Assinatura de encerramento da conexão }
  TDlpDestroyConnectionEvent = procedure(Sender: TObject; var ConnectionToFree: TObject) of object;

  {============================================================================
    Componente: TDlpDatabaseConnectionPool
    Pool de conexões thread-safe de alto rendimento
  ============================================================================}
  TDlpDatabaseConnectionPool = class(TComponent)
  private
    FMinConnections: Integer;
    FMaxConnections: Integer;
    FIdleTimeoutSeconds: Integer;
    FConnectionTimeoutMs: Integer;
    FPoolItems: TList;
    FLock: TCriticalSection;
    FOnCreateConnection: TDlpCreateConnectionEvent;
    FOnDestroyConnection: TDlpDestroyConnectionEvent;

    function CreateNewPooledItem: TDlpPooledConnection;
    procedure DestroyPooledItem(Item: TDlpPooledConnection);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InitializePool;
    procedure ClearPool;

    function AcquireConnection(out AConnection: TObject; ATimeoutMs: Integer = -1): Boolean;
    procedure ReleaseConnection(AConnection: TObject);

    procedure PurgeIdleConnections;
    function ActiveConnectionsCount: Integer;
    function InUseConnectionsCount: Integer;
  published
    property MinConnections: Integer read FMinConnections write FMinConnections default 2;
    property MaxConnections: Integer read FMaxConnections write FMaxConnections default 10;
    property IdleTimeoutSeconds: Integer read FIdleTimeoutSeconds write FIdleTimeoutSeconds default 300;
    property ConnectionTimeoutMs: Integer read FConnectionTimeoutMs write FConnectionTimeoutMs default 5000;
    property OnCreateConnection: TDlpCreateConnectionEvent read FOnCreateConnection write FOnCreateConnection;
    property OnDestroyConnection: TDlpDestroyConnectionEvent read FOnDestroyConnection write FOnDestroyConnection;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpDatabaseConnectionPool]);
end;

{ TDlpDatabaseConnectionPool }

constructor TDlpDatabaseConnectionPool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMinConnections := 2;
  FMaxConnections := 10;
  FIdleTimeoutSeconds := 300;
  FConnectionTimeoutMs := 5000;
  FPoolItems := TList.Create;
  FLock := TCriticalSection.Create;
end;

destructor TDlpDatabaseConnectionPool.Destroy;
begin
  ClearPool;
  FLock.Free;
  FPoolItems.Free;
  inherited Destroy;
end;

function TDlpDatabaseConnectionPool.CreateNewPooledItem: TDlpPooledConnection;
var
  NewConn: TObject;
begin
  NewConn := nil;
  if Assigned(FOnCreateConnection) then
    FOnCreateConnection(Self, NewConn)
  else
    NewConn := TObject.Create;

  Result := TDlpPooledConnection.Create;
  Result.ConnectionInstance := NewConn;
  Result.InUse := False;
  Result.CreatedAt := Now;
  Result.LastUsedAt := Now;
  Result.UsageCount := 0;
end;

procedure TDlpDatabaseConnectionPool.DestroyPooledItem(Item: TDlpPooledConnection);
var
  Inst: TObject;
begin
  if Assigned(Item) then
  begin
    Inst := Item.ConnectionInstance;
    if Assigned(Inst) then
    begin
      if Assigned(FOnDestroyConnection) then
        FOnDestroyConnection(Self, Inst)
      else
        Inst.Free;
    end;
    Item.Free;
  end;
end;

procedure TDlpDatabaseConnectionPool.InitializePool;
var
  Item: TDlpPooledConnection;
begin
  FLock.Enter;
  try
    while FPoolItems.Count < FMinConnections do
    begin
      Item := CreateNewPooledItem;
      FPoolItems.Add(Item);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TDlpDatabaseConnectionPool.ClearPool;
var
  i: Integer;
begin
  FLock.Enter;
  try
    for i := 0 to FPoolItems.Count - 1 do
      DestroyPooledItem(TDlpPooledConnection(FPoolItems[i]));
    FPoolItems.Clear;
  finally
    FLock.Leave;
  end;
end;

function TDlpDatabaseConnectionPool.AcquireConnection(out AConnection: TObject;
  ATimeoutMs: Integer): Boolean;
var
  EffectiveTimeout: Integer;
  StartTime: UInt64;
  i: Integer;
  Item: TDlpPooledConnection;
begin
  AConnection := nil;
  if ATimeoutMs < 0 then
    EffectiveTimeout := FConnectionTimeoutMs
  else
    EffectiveTimeout := ATimeoutMs;

  StartTime := GetTickCount64;

  while (GetTickCount64 - StartTime) <= UInt64(EffectiveTimeout) do
  begin
    FLock.Enter;
    try
      for i := 0 to FPoolItems.Count - 1 do
      begin
        Item := TDlpPooledConnection(FPoolItems[i]);
        if not Item.InUse then
        begin
          Item.InUse := True;
          Item.LastUsedAt := Now;
          Inc(Item.UsageCount);
          AConnection := Item.ConnectionInstance;
          Exit(True);
        end;
      end;

      if FPoolItems.Count < FMaxConnections then
      begin
        Item := CreateNewPooledItem;
        Item.InUse := True;
        Inc(Item.UsageCount);
        FPoolItems.Add(Item);
        AConnection := Item.ConnectionInstance;
        Exit(True);
      end;
    finally
      FLock.Leave;
    end;

    Sleep(20);
  end;

  Result := False;
end;

procedure TDlpDatabaseConnectionPool.ReleaseConnection(AConnection: TObject);
var
  i: Integer;
  Item: TDlpPooledConnection;
begin
  if not Assigned(AConnection) then Exit;

  FLock.Enter;
  try
    for i := 0 to FPoolItems.Count - 1 do
    begin
      Item := TDlpPooledConnection(FPoolItems[i]);
      if Item.ConnectionInstance = AConnection then
      begin
        Item.InUse := False;
        Item.LastUsedAt := Now;
        Exit;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TDlpDatabaseConnectionPool.PurgeIdleConnections;
var
  i: Integer;
  Item: TDlpPooledConnection;
  IdleSec: Double;
begin
  FLock.Enter;
  try
    for i := FPoolItems.Count - 1 downto 0 do
    begin
      if FPoolItems.Count <= FMinConnections then Break;

      Item := TDlpPooledConnection(FPoolItems[i]);
      if not Item.InUse then
      begin
        IdleSec := (Now - Item.LastUsedAt) * 86400.0;
        if IdleSec > FIdleTimeoutSeconds then
        begin
          FPoolItems.Delete(i);
          DestroyPooledItem(Item);
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

function TDlpDatabaseConnectionPool.ActiveConnectionsCount: Integer;
begin
  FLock.Enter;
  try
    Result := FPoolItems.Count;
  finally
    FLock.Leave;
  end;
end;

function TDlpDatabaseConnectionPool.InUseConnectionsCount: Integer;
var
  i, Cnt: Integer;
begin
  Cnt := 0;
  FLock.Enter;
  try
    for i := 0 to FPoolItems.Count - 1 do
      if TDlpPooledConnection(FPoolItems[i]).InUse then
        Inc(Cnt);
    Result := Cnt;
  finally
    FLock.Leave;
  end;
end;

end.
