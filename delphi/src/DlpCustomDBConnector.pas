{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 13: Arquitetura de Dados no Pascal e a Ponte TDataLink
  Componente: TDlpCustomDBConnector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Framework base corporativo para componentes DB-Aware no Delphi 12,
             encapsulando a ponte TFieldDataLink para sincronização bidirecional
             reativa entre FireDAC / TDataSet, TDataSource, TField e a UI.
==============================================================================}
unit DlpCustomDBConnector;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Vcl.Controls,
  Vcl.DBCtrls;

type
  TDlpCustomDBConnector = class;

  {============================================================================
    Classe: TDlpFieldDataLinkBridge
    Especializa TFieldDataLink para captura dos eventos de cursor e edição
  ============================================================================}
  TDlpFieldDataLinkBridge = class(TFieldDataLink)
  private
    FConnector: TDlpCustomDBConnector;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure EditingChanged; override;
    procedure RecordChanged(Field: TField); override;
    procedure UpdateData; override;
  public
    constructor Create(AConnector: TDlpCustomDBConnector);
  end;

  { Eventos reativos tipados }
  TDlpDBDataChangeEvent = procedure(Sender: TObject; AField: TField) of object;
  TDlpDBStateChangeEvent = procedure(Sender: TObject; AState: TDataSetState) of object;
  TDlpDBUpdateDataEvent = procedure(Sender: TObject; AField: TField) of object;

  {============================================================================
    Classe: TDlpCustomDBConnector
    Componente não-visual orquestrador de vínculos com bancos de dados
  ============================================================================}
  TDlpCustomDBConnector = class(TComponent)
  private
    FDataLink: TDlpFieldDataLinkBridge;
    FOnDataChange: TDlpDBDataChangeEvent;
    FOnStateChange: TDlpDBStateChangeEvent;
    FOnUpdateData: TDlpDBUpdateDataEvent;

    function GetDataSource: TDataSource;
    procedure SetDataSource(const AValue: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const AValue: string);
    function GetField: TField;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    { Métodos internos propagadores }
    procedure DoActiveChanged; virtual;
    procedure DoDataSetChanged; virtual;
    procedure DoEditingChanged; virtual;
    procedure DoRecordChanged(AField: TField); virtual;
    procedure DoUpdateData; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function CanModify: Boolean;
    function Edit: Boolean;
    procedure Modified;
    procedure Reset;

    property Field: TField read GetField;
    property DataLink: TDlpFieldDataLinkBridge read FDataLink;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;

    property OnDataChange: TDlpDBDataChangeEvent read FOnDataChange write FOnDataChange;
    property OnStateChange: TDlpDBStateChangeEvent read FOnStateChange write FOnStateChange;
    property OnUpdateData: TDlpDBUpdateDataEvent read FOnUpdateData write FOnUpdateData;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpCustomDBConnector]);
end;

{ TDlpFieldDataLinkBridge }

constructor TDlpFieldDataLinkBridge.Create(AConnector: TDlpCustomDBConnector);
begin
  inherited Create;
  FConnector := AConnector;
  Control := AConnector;
end;

procedure TDlpFieldDataLinkBridge.ActiveChanged;
begin
  inherited ActiveChanged;
  if Assigned(FConnector) then
    FConnector.DoActiveChanged;
end;

procedure TDlpFieldDataLinkBridge.DataSetChanged;
begin
  inherited DataSetChanged;
  if Assigned(FConnector) then
    FConnector.DoDataSetChanged;
end;

procedure TDlpFieldDataLinkBridge.EditingChanged;
begin
  inherited EditingChanged;
  if Assigned(FConnector) then
    FConnector.DoEditingChanged;
end;

procedure TDlpFieldDataLinkBridge.RecordChanged(Field: TField);
begin
  inherited RecordChanged(Field);
  if Assigned(FConnector) then
    FConnector.DoRecordChanged(Field);
end;

procedure TDlpFieldDataLinkBridge.UpdateData;
begin
  inherited UpdateData;
  if Assigned(FConnector) then
    FConnector.DoUpdateData;
end;

{ TDlpCustomDBConnector }

constructor TDlpCustomDBConnector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataLink := TDlpFieldDataLinkBridge.Create(Self);
end;

destructor TDlpCustomDBConnector.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TDlpCustomDBConnector.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDlpCustomDBConnector.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if Assigned(AValue) then
      AValue.FreeNotification(Self);
  end;
end;

function TDlpCustomDBConnector.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TDlpCustomDBConnector.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

function TDlpCustomDBConnector.GetField: TField;
begin
  Result := FDataLink.Field;
end;

procedure TDlpCustomDBConnector.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TDlpCustomDBConnector.CanModify: Boolean;
begin
  Result := FDataLink.CanModify;
end;

function TDlpCustomDBConnector.Edit: Boolean;
begin
  Result := FDataLink.Edit;
end;

procedure TDlpCustomDBConnector.Modified;
begin
  FDataLink.Modified;
end;

procedure TDlpCustomDBConnector.Reset;
begin
  FDataLink.Reset;
end;

procedure TDlpCustomDBConnector.DoActiveChanged;
begin
  if Assigned(FOnStateChange) and Assigned(FDataLink.DataSet) then
    FOnStateChange(Self, FDataLink.DataSet.State);
end;

procedure TDlpCustomDBConnector.DoDataSetChanged;
begin
  if Assigned(FOnDataChange) then
    FOnDataChange(Self, FDataLink.Field);
end;

procedure TDlpCustomDBConnector.DoEditingChanged;
begin
  if Assigned(FOnStateChange) and Assigned(FDataLink.DataSet) then
    FOnStateChange(Self, FDataLink.DataSet.State);
end;

procedure TDlpCustomDBConnector.DoRecordChanged(AField: TField);
begin
  if Assigned(FOnDataChange) then
    FOnDataChange(Self, AField);
end;

procedure TDlpCustomDBConnector.DoUpdateData;
begin
  if Assigned(FOnUpdateData) then
    FOnUpdateData(Self, FDataLink.Field);
end;

end.
