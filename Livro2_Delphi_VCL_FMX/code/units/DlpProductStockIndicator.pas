{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 20: Caso de Estudo Real 2 — Gerador do Cadastro de Produtos e Itens
  Componente: TDlpProductStockIndicator
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL
  Descrição: Indicador visual e reativo de níveis de estoque na VCL com alertas
             dinâmicos (Crítico, Reposição, Normal, Excesso) e utilitários
             matemáticos de cálculo de margem de lucro e markup.
==============================================================================}
unit DlpProductStockIndicator;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Graphics,
  Data.DB,
  Vcl.DBCtrls;

type
  /// <summary>
  /// Classificação visual do status de estoque do produto.
  /// </summary>
  TDlpStockStatusLevel = (slCritical, slWarning, slNormal, slExcess);

  /// <summary>
  /// Controle gráfico DB-Aware leve para visualização de estoque.
  /// </summary>
  TDlpProductStockIndicator = class(TGraphicControl)
  private
    FDataLink: TFieldDataLink;
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
    function GetStockLevel(Current, Min, Max: Double): TDlpStockStatusLevel;
  protected
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Calcula a margem de lucro percentual com base no preço de venda.
    /// Margem = ((PreçoVenda - PreçoCusto) / PreçoVenda) * 100
    /// </summary>
    class function CalculateMargin(CostPrice, SellPrice: Double): Double;

    /// <summary>
    /// Calcula o markup percentual com base no preço de custo.
    /// Markup = ((PreçoVenda - PreçoCusto) / PreçoCusto) * 100
    /// </summary>
    class function CalculateMarkup(CostPrice, SellPrice: Double): Double;

    /// <summary>
    /// Formata um valor numérico em percentual com duas casas decimais.
    /// </summary>
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
  RegisterComponents('Delphi Component Engineering', [TDlpProductStockIndicator]);
end;

{ Métodos de Cálculo Financeiro }

class function TDlpProductStockIndicator.CalculateMargin(CostPrice, SellPrice: Double): Double;
begin
  if SellPrice <= 0 then
    Exit(0.0);
  Result := ((SellPrice - CostPrice) / SellPrice) * 100.0;
end;

class function TDlpProductStockIndicator.CalculateMarkup(CostPrice, SellPrice: Double): Double;
begin
  if CostPrice <= 0 then
    Exit(0.0);
  Result := ((SellPrice - CostPrice) / CostPrice) * 100.0;
end;

class function TDlpProductStockIndicator.FormatPercent(const AValue: Double): string;
begin
  Result := FormatFloat('0.00', AValue) + '%';
end;

{ TDlpProductStockIndicator }

constructor TDlpProductStockIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 240;
  Height := 48;
  FCriticalColor := $002A2AE0; // Vermelho intenso
  FWarningColor := $0000A5FF;  // Laranja / Âmbar
  FNormalColor := $0032B032;   // Verde vibrante
  FExcessColor := $00D07020;   // Azul cobalto

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
end;

destructor TDlpProductStockIndicator.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TDlpProductStockIndicator.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDlpProductStockIndicator.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TDlpProductStockIndicator.SetCurrentStockField(const AValue: string);
begin
  if FCurrentStockField <> AValue then
  begin
    FCurrentStockField := AValue;
    Invalidate;
  end;
end;

procedure TDlpProductStockIndicator.SetMinStockField(const AValue: string);
begin
  if FMinStockField <> AValue then
  begin
    FMinStockField := AValue;
    Invalidate;
  end;
end;

procedure TDlpProductStockIndicator.SetMaxStockField(const AValue: string);
begin
  if FMaxStockField <> AValue then
  begin
    FMaxStockField := AValue;
    Invalidate;
  end;
end;

procedure TDlpProductStockIndicator.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TDlpProductStockIndicator.DataChange(Sender: TObject);
begin
  Invalidate;
end;

function TDlpProductStockIndicator.GetStockLevel(Current, Min, Max: Double): TDlpStockStatusLevel;
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

procedure TDlpProductStockIndicator.Paint;
var
  CurVal, MinVal, MaxVal, Ratio: Double;
  CurField, MinFld, MaxFld: TField;
  Status: TDlpStockStatusLevel;
  BarColor: TColor;
  StatusText: string;
  BarWidth, FillW: Integer;
begin
  Canvas.Font.Assign(Self.Font);
  CurVal := 0;
  MinVal := 0;
  MaxVal := 100;

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

  // Rótulo textual de status
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := BarColor;
  Canvas.TextOut(4, 2, 'Estoque: ' + StatusText);

  // Barra de fundo
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
