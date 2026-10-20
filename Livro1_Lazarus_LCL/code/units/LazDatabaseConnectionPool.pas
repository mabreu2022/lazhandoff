{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 47: Gerenciador de Pool de Conexões SQL (TLazDatabaseConnectionPool)
  Componente: TLazDatabaseConnectionPool
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Gerenciador de pool de conexões com banco de dados (SQLdb / Zeos /
             PostgreSQL / MySQL / SQLite) estritamente thread-safe. Controla
             empréstimo (Acquire) e devolução (Release) com timeout, dimensionamento
             mínimo/máximo e eliminação periódica de conexões zumbis inativas.
==============================================================================}
unit LazDatabaseConnectionPool;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  syncobjs;

type
  { Estado do item dentro do pool }
  TPooledConnection = class
  public
    ConnectionInstance: TObject;
    InUse: Boolean;
    CreatedAt: TDateTime;
    LastUsedAt: TDateTime;
    UsageCount: Integer;
  end;

  { Assinatura da fábrica de conexões }
  TCreateConnectionEvent = procedure(Sender: TObject; out NewConnection: TObject) of object;

  { Assinatura do destruidor de conexão física }
  TDestroyConnectionEvent = procedure(Sender: TObject; var ConnectionToFree: TObject) of object;

  {============================================================================
    Componente: TLazDatabaseConnectionPool
    Pool de conexões thread-safe para aplicações de alta concorrência
  ============================================================================}
  TLazDatabaseConnectionPool = class(TComponent)
  private
    FMinConnections: Integer;
    FMaxConnections: Integer;
    FIdleTimeoutSeconds: Integer;
    FConnectionTimeoutMs: Integer;
    FPoolItems: TFPList;
    FLock: TCriticalSection;
    FOnCreateConnection: TCreateConnectionEvent;
    FOnDestroyConnection: TDestroyConnectionEvent;

    function CreateNewPooledItem: TPooledConnection;
    procedure DestroyPooledItem(Item: TPooledConnection);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Inicialização do Pool }
    procedure InitializePool;
    procedure ClearPool;

    { Empréstimo e Devolução Thread-Safe }
    function AcquireConnection(out AConnection: TObject; ATimeoutMs: Integer = -1): Boolean;
    procedure ReleaseConnection(AConnection: TObject);

    { Manutenção e Eliminação de Conexões Zumbis }
    procedure PurgeIdleConnections;
    function ActiveConnectionsCount: Integer;
    function InUseConnectionsCount: Integer;
  published
    property MinConnections: Integer read FMinConnections write FMinConnections default 2;
    property MaxConnections: Integer read FMaxConnections write FMaxConnections default 10;
    property IdleTimeoutSeconds: Integer read FIdleTimeoutSeconds write FIdleTimeoutSeconds default 300;
    property ConnectionTimeoutMs: Integer read FConnectionTimeoutMs write FConnectionTimeoutMs default 5000;
    property OnCreateConnection: TCreateConnectionEvent read FOnCreateConnection write FOnCreateConnection;
    property OnDestroyConnection: TDestroyConnectionEvent read FOnDestroyConnection write FOnDestroyConnection;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazDatabaseConnectionPool]);
end;

{ TLazDatabaseConnectionPool }

constructor TLazDatabaseConnectionPool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMinConnections := 2;
  FMaxConnections := 10;
  FIdleTimeoutSeconds := 300;
  FConnectionTimeoutMs := 5000;
  FPoolItems := TFPList.Create;
  FLock := TCriticalSection.Create;
end;

destructor TLazDatabaseConnectionPool.Destroy;
begin
  ClearPool;
  FLock.Free;
  FPoolItems.Free;
  inherited Destroy;
end;

function TLazDatabaseConnectionPool.CreateNewPooledItem: TPooledConnection;
var
  NewConn: TObject;
begin
  NewConn := nil;
  if Assigned(FOnCreateConnection) then
    FOnCreateConnection(Self, NewConn)
  else
    NewConn := TObject.Create; { Mock / Fallback }

  Result := TPooledConnection.Create;
  Result.ConnectionInstance := NewConn;
  Result.InUse := False;
  Result.CreatedAt := Now;
  Result.LastUsedAt := Now;
  Result.UsageCount := 0;
end;

procedure TLazDatabaseConnectionPool.DestroyPooledItem(Item: TPooledConnection);
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

procedure TLazDatabaseConnectionPool.InitializePool;
var
  i: Integer;
  Item: TPooledConnection;
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

procedure TLazDatabaseConnectionPool.ClearPool;
var
  i: Integer;
begin
  FLock.Enter;
  try
    for i := 0 to FPoolItems.Count - 1 do
      DestroyPooledItem(TPooledConnection(FPoolItems[i]));
    FPoolItems.Clear;
  finally
    FLock.Leave;
  end;
end;

function TLazDatabaseConnectionPool.AcquireConnection(out AConnection: TObject;
  ATimeoutMs: Integer): Boolean;
var
  EffectiveTimeout: Integer;
  StartTime: QWord;
  i: Integer;
  Item: TPooledConnection;
begin
  AConnection := nil;
  if ATimeoutMs < 0 then
    EffectiveTimeout := FConnectionTimeoutMs
  else
    EffectiveTimeout := ATimeoutMs;

  StartTime := GetTickCount64;

  while (GetTickCount64 - StartTime) <= QWord(EffectiveTimeout) do
  begin
    FLock.Enter;
    try
      { 1. Procura por conexão ociosa existente }
      for i := 0 to FPoolItems.Count - 1 do
      begin
        Item := TPooledConnection(FPoolItems[i]);
        if not Item.InUse then
        begin
          Item.InUse := True;
          Item.LastUsedAt := Now;
          Inc(Item.UsageCount);
          AConnection := Item.ConnectionInstance;
          Exit(True);
        end;
      end;

      { 2. Se não encontrou e ainda há espaço no pool, cria uma nova conexão }
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

    Sleep(20); { Espera cooperativa antes de tentar novamente }
  end;

  Result := False; { Esgotado o tempo limite de espera (Connection Timeout) }
end;

procedure TLazDatabaseConnectionPool.ReleaseConnection(AConnection: TObject);
var
  i: Integer;
  Item: TPooledConnection;
begin
  if not Assigned(AConnection) then Exit;

  FLock.Enter;
  try
    for i := 0 to FPoolItems.Count - 1 do
    begin
      Item := TPooledConnection(FPoolItems[i]);
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

procedure TLazDatabaseConnectionPool.PurgeIdleConnections;
var
  i: Integer;
  Item: TPooledConnection;
  IdleSec: Double;
begin
  FLock.Enter;
  try
    for i := FPoolItems.Count - 1 downto 0 do
    begin
      if FPoolItems.Count <= FMinConnections then Break;

      Item := TPooledConnection(FPoolItems[i]);
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

function TLazDatabaseConnectionPool.ActiveConnectionsCount: Integer;
begin
  FLock.Enter;
  try
    Result := FPoolItems.Count;
  finally
    FLock.Leave;
  end;
end;

function TLazDatabaseConnectionPool.InUseConnectionsCount: Integer;
var
  i, Cnt: Integer;
begin
  Cnt := 0;
  FLock.Enter;
  try
    for i := 0 to FPoolItems.Count - 1 do
      if TPooledConnection(FPoolItems[i]).InUse then
        Inc(Cnt);
    Result := Cnt;
  finally
    FLock.Leave;
  end;
end;

end.
