{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 13: Arquitetura de Dados no Pascal e a Ponte TDataLink
  Componente: TLazCustomDBConnector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Framework base reativo para componentes DB-Aware, encapsulando
             a ponte TFieldDataLink para sincronização bidirecional em tempo real
             entre TDataSet, TDataSource, TField e a interface gráfica (LCL).
==============================================================================}
unit LazCustomDBConnector;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  DB;

type
  { Declaração antecipada }
  TLazCustomDBConnector = class;

  {============================================================================
    Classe: TLazFieldDataLinkBridge
    Especializa TFieldDataLink para interceptar todos os eventos do dataset
  ============================================================================}
  TLazFieldDataLinkBridge = class(TFieldDataLink)
  private
    FConnector: TLazCustomDBConnector;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure EditingChanged; override;
    procedure RecordChanged(Field: TField); override;
    procedure UpdateData; override;
  public
    constructor Create(AConnector: TLazCustomDBConnector);
  end;

  { Eventos de notificação reativa de dados }
  TOnDBDataChangeEvent = procedure(Sender: TObject; AField: TField) of object;
  TOnDBStateChangeEvent = procedure(Sender: TObject; AState: TDataSetState) of object;
  TOnDBUpdateDataEvent = procedure(Sender: TObject; AField: TField) of object;

  {============================================================================
    Classe: TLazCustomDBConnector
    Componente não-visual / base para orquestração de campos de dados
  ============================================================================}
  TLazCustomDBConnector = class(TComponent)
  private
    FDataLink: TLazFieldDataLinkBridge;
    FOnDataChange: TOnDBDataChangeEvent;
    FOnStateChange: TOnDBStateChangeEvent;
    FOnUpdateData: TOnDBUpdateDataEvent;

    function GetDataSource: TDataSource;
    procedure SetDataSource(const AValue: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const AValue: string);
    function GetField: TField;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    { Métodos internos acionados pelo DataLink }
    procedure DoActiveChanged; virtual;
    procedure DoDataSetChanged; virtual;
    procedure DoEditingChanged; virtual;
    procedure DoRecordChanged(AField: TField); virtual;
    procedure DoUpdateData; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Operações no DataSet via DataLink }
    function CanModify: Boolean;
    function Edit: Boolean;
    procedure Modified;
    procedure Reset;

    property Field: TField read GetField;
    property DataLink: TLazFieldDataLinkBridge read FDataLink;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;

    property OnDataChange: TOnDBDataChangeEvent read FOnDataChange write FOnDataChange;
    property OnStateChange: TOnDBStateChangeEvent read FOnStateChange write FOnStateChange;
    property OnUpdateData: TOnDBUpdateDataEvent read FOnUpdateData write FOnUpdateData;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazCustomDBConnector]);
end;

{ TLazFieldDataLinkBridge }

constructor TLazFieldDataLinkBridge.Create(AConnector: TLazCustomDBConnector);
begin
  inherited Create;
  FConnector := AConnector;
  Control := AConnector;
end;

procedure TLazFieldDataLinkBridge.ActiveChanged;
begin
  inherited ActiveChanged;
  if Assigned(FConnector) then
    FConnector.DoActiveChanged;
end;

procedure TLazFieldDataLinkBridge.DataSetChanged;
begin
  inherited DataSetChanged;
  if Assigned(FConnector) then
    FConnector.DoDataSetChanged;
end;

procedure TLazFieldDataLinkBridge.EditingChanged;
begin
  inherited EditingChanged;
  if Assigned(FConnector) then
    FConnector.DoEditingChanged;
end;

procedure TLazFieldDataLinkBridge.RecordChanged(Field: TField);
begin
  inherited RecordChanged(Field);
  if Assigned(FConnector) then
    FConnector.DoRecordChanged(Field);
end;

procedure TLazFieldDataLinkBridge.UpdateData;
begin
  inherited UpdateData;
  if Assigned(FConnector) then
    FConnector.DoUpdateData;
end;

{ TLazCustomDBConnector }

constructor TLazCustomDBConnector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataLink := TLazFieldDataLinkBridge.Create(Self);
end;

destructor TLazCustomDBConnector.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TLazCustomDBConnector.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TLazCustomDBConnector.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if Assigned(AValue) then
      AValue.FreeNotification(Self);
  end;
end;

function TLazCustomDBConnector.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TLazCustomDBConnector.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

function TLazCustomDBConnector.GetField: TField;
begin
  Result := FDataLink.Field;
end;

procedure TLazCustomDBConnector.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TLazCustomDBConnector.CanModify: Boolean;
begin
  Result := FDataLink.CanModify;
end;

function TLazCustomDBConnector.Edit: Boolean;
begin
  Result := FDataLink.Edit;
end;

procedure TLazCustomDBConnector.Modified;
begin
  FDataLink.Modified;
end;

procedure TLazCustomDBConnector.Reset;
begin
  FDataLink.Reset;
end;

procedure TLazCustomDBConnector.DoActiveChanged;
begin
  if Assigned(FOnStateChange) and Assigned(FDataLink.DataSet) then
    FOnStateChange(Self, FDataLink.DataSet.State);
end;

procedure TLazCustomDBConnector.DoDataSetChanged;
begin
  if Assigned(FOnDataChange) then
    FOnDataChange(Self, FDataLink.Field);
end;

procedure TLazCustomDBConnector.DoEditingChanged;
begin
  if Assigned(FOnStateChange) and Assigned(FDataLink.DataSet) then
    FOnStateChange(Self, FDataLink.DataSet.State);
end;

procedure TLazCustomDBConnector.DoRecordChanged(AField: TField);
begin
  if Assigned(FOnDataChange) then
    FOnDataChange(Self, AField);
end;

procedure TLazCustomDBConnector.DoUpdateData;
begin
  if Assigned(FOnUpdateData) then
    FOnUpdateData(Self, FDataLink.Field);
end;

end.
