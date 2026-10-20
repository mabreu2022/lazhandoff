{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 20: Caso de Estudo Real 2 — Gerador do Cadastro de Produtos e Itens
  Componente: TLazProductStockIndicator
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Indicador visual e reativo de níveis de estoque de produtos
             (Estoque Crítico, Mínimo, Normal, Excesso) com cálculo automático
             de margem de lucro e markup em tempo real.
==============================================================================}
unit LazProductStockIndicator;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  DB;

type
  { Classificação visual da situação de estoque }
  TStockStatusLevel = (slCritical, slWarning, slNormal, slExcess);

  {============================================================================
    Classe: TLazProductStockIndicator
    Controle gráfico DB-Aware para visualização analítica de estoque
  ============================================================================}
  TLazProductStockIndicator = class(TGraphicControl)
  private
    FDataLink: TDataLink;
    FCurrentStockField: string;
    FMinStockField: string;
    FMaxStockField: string;

    FCriticalColor: TColor;
    FWarningColor: TColor;
    FNormalColor: TColor;
    FExcessColor: TColor;

    function GetDataSource: TDataSource;
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetCurrentStockField(const AValue: string);
    procedure SetMinStockField(const AValue: string);
    procedure SetMaxStockField(const AValue: string);
    procedure DataChange(Sender: TObject);
    function GetStockLevel(Current, Min, Max: Double): TStockStatusLevel;
  protected
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Funções utilitárias estáticas de cálculo comercial }
    class function CalculateMargin(CostPrice, SellPrice: Double): Double;
    class function CalculateMarkup(CostPrice, SellPrice: Double): Double;
    class function FormatPercent(const AValue: Double): string;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property CurrentStockField: string read FCurrentStockField write SetCurrentStockField;
    property MinStockField: string read FMinStockField write SetMinStockField;
    property MaxStockField: string read FMaxStockField write SetMaxStockField;

    property CriticalColor: TColor read FCriticalColor write FCriticalColor default $002A2AE0;
    property WarningColor: TColor read FWarningColor write FWarningColor default $0000A5FF;
    property NormalColor: TColor read FNormalColor write FNormalColor default $0032B032;
    property ExcessColor: TColor read FExcessColor write FExcessColor default $00D07020;

    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazProductStockIndicator]);
end;

{ Métodos de Cálculo Financeiro }

class function TLazProductStockIndicator.CalculateMargin(CostPrice, SellPrice: Double): Double;
begin
  if SellPrice <= 0 then
    Exit(0.0);
  Result := ((SellPrice - CostPrice) / SellPrice) * 100.0;
end;

class function TLazProductStockIndicator.CalculateMarkup(CostPrice, SellPrice: Double): Double;
begin
  if CostPrice <= 0 then
    Exit(0.0);
  Result := ((SellPrice - CostPrice) / CostPrice) * 100.0;
end;

class function TLazProductStockIndicator.FormatPercent(const AValue: Double): string;
begin
  Result := FormatFloat('0.00', AValue) + '%';
end;

{ TLazProductStockIndicator }

constructor TLazProductStockIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 240;
  Height := 48;
  FCriticalColor := $002A2AE0; // Vermelho intenso
  FWarningColor := $0000A5FF;  // Laranja / Âmbar
  FNormalColor := $0032B032;   // Verde vibrante
  FExcessColor := $00D07020;   // Azul cobalto

  FDataLink := TDataLink.Create;
  FDataLink.OnDataChange := @DataChange;
end;

destructor TLazProductStockIndicator.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TLazProductStockIndicator.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TLazProductStockIndicator.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TLazProductStockIndicator.SetCurrentStockField(const AValue: string);
begin
  if FCurrentStockField <> AValue then
  begin
    FCurrentStockField := AValue;
    Invalidate;
  end;
end;

procedure TLazProductStockIndicator.SetMinStockField(const AValue: string);
begin
  if FMinStockField <> AValue then
  begin
    FMinStockField := AValue;
    Invalidate;
  end;
end;

procedure TLazProductStockIndicator.SetMaxStockField(const AValue: string);
begin
  if FMaxStockField <> AValue then
  begin
    FMaxStockField := AValue;
    Invalidate;
  end;
end;

procedure TLazProductStockIndicator.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TLazProductStockIndicator.DataChange(Sender: TObject);
begin
  Invalidate;
end;

function TLazProductStockIndicator.GetStockLevel(Current, Min, Max: Double): TStockStatusLevel;
begin
  if Current <= Min then
    Result := slCritical
  else if (Max > 0) and (Current > Max) then
    Result := slExcess
  else if (Min > 0) and (Current <= Min * 1.25) then
    Result := slWarning
  else
    Result := slNormal;
end;

procedure TLazProductStockIndicator.Paint;
var
  CurVal, MinVal, MaxVal, Ratio: Double;
  CurField, MinFld, MaxFld: TField;
  Status: TStockStatusLevel;
  BarColor: TColor;
  StatusText: string;
  BarWidth, FillW: Integer;
begin
  Canvas.Font.Assign(Self.Font);
  CurVal := 0;
  MinVal := 0;
  MaxVal := 100;

  // Extração de valores do DataSet ativo
  if (FDataLink <> nil) and (FDataLink.DataSet <> nil) and FDataLink.DataSet.Active then
  begin
    if FCurrentStockField <> '' then
    begin
      CurField := FDataLink.DataSet.FindField(FCurrentStockField);
      if CurField <> nil then
        CurVal := CurField.AsFloat;
    end;

    if FMinStockField <> '' then
    begin
      MinFld := FDataLink.DataSet.FindField(FMinStockField);
      if MinFld <> nil then
        MinVal := MinFld.AsFloat;
    end;

    if FMaxStockField <> '' then
    begin
      MaxFld := FDataLink.DataSet.FindField(FMaxStockField);
      if (MaxFld <> nil) and (MaxFld.AsFloat > 0) then
        MaxVal := MaxFld.AsFloat;
    end;
  end;

  Status := GetStockLevel(CurVal, MinVal, MaxVal);
  case Status of
    slCritical:
    begin
      BarColor := FCriticalColor;
      StatusText := Format('CRÍTICO (%.1f)', [CurVal]);
    end;
    slWarning:
    begin
      BarColor := FWarningColor;
      StatusText := Format('REPOSIÇÃO (%.1f)', [CurVal]);
    end;
    slNormal:
    begin
      BarColor := FNormalColor;
      StatusText := Format('NORMAL (%.1f)', [CurVal]);
    end;
    slExcess:
    begin
      BarColor := FExcessColor;
      StatusText := Format('EXCESSO (%.1f)', [CurVal]);
    end;
  end;

  // Desenha o rótulo de status
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Bold := True;
  Canvas.Font.Color := BarColor;
  Canvas.TextOut(4, 2, 'Estoque: ' + StatusText);

  // Fundo do medidor (trilho da barra)
  BarWidth := Width - 8;
  Canvas.Brush.Color := $00E0E0E0;
  Canvas.Pen.Color := $00CCCCCC;
  Canvas.RoundRect(4, 24, Width - 4, Height - 4, 6, 6);

  // Preenchimento proporcional
  if MaxVal > 0 then
    Ratio := CurVal / MaxVal
  else
    Ratio := 0;

  if Ratio > 1.0 then
    Ratio := 1.0
  else if Ratio < 0 then
    Ratio := 0;

  FillW := Round(BarWidth * Ratio);
  if FillW > 4 then
  begin
    Canvas.Brush.Color := BarColor;
    Canvas.Pen.Color := BarColor;
    Canvas.RoundRect(4, 24, 4 + FillW, Height - 4, 6, 6);
  end;
end;

end.
