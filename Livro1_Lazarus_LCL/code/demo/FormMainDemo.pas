unit FormMainDemo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, StdCtrls, Buttons,
  // Unidades dos componentes do livro
  LazAnalogGauge,
  LazIndustrialTankGauge,
  LazVectorDonutChart,
  LazMatrixHeatmap,
  LazProductStockIndicator,
  LazAccordionContainer,
  LazCustomTabBar,
  LazHighDpiThemedPanel,
  LazCRUDOperationsBar,
  LazCryptoVaultStorage,
  LazJwtSecurityManager,
  LazBinaryBlobContainer,
  LazFiscalXmlValidator,
  LazTypeInfoInspector,
  LazCodeBenchmarkHarness,
  LazSystemMetricsProbe;

type
  { TFrmMainDemo }
  TFrmMainDemo = class(TForm)
    PnlTopHeader: TPanel;
    LblTitle: TLabel;
    LblSubtitle: TLabel;
    PageControlMain: TPageControl;
    TabIndustrial: TTabSheet;
    TabUI: TTabSheet;
    TabSecurity: TTabSheet;
    TabDiagnostics: TTabSheet;
    PnlIndustrialControls: TPanel;
    PnlUIControls: TPanel;
    PnlSecurityControls: TPanel;
    PnlDiagControls: TPanel;
    PnlBottomLog: TPanel;
    PnlLogHeader: TPanel;
    LblLogTitle: TLabel;
    BtnClearLog: TButton;
    MemoLog: TMemo;
    TimerGaugeAnim: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnClearLogClick(Sender: TObject);
    procedure TimerGaugeAnimTimer(Sender: TObject);

  private
    { Componentes Visuais Criados Dinamicamente }
    FGauge: TLazAnalogGauge;
    FTank: TLazIndustrialTankGauge;
    FDonut: TLazVectorDonutChart;
    FHeatmap: TLazMatrixHeatmap;
    FStock: TLazProductStockIndicator;

    FAccordion: TLazAccordionContainer;
    FTabBar: TLazCustomTabBar;
    FThemedPanel: TLazHighDpiThemedPanel;
    FCrudBar: TLazCRUDOperationsBar;

    { Componentes de Serviço e Segurança }
    FVault: TLazCryptoVaultStorage;
    FJwt: TLazJwtSecurityManager;
    FBlobContainer: TLazBinaryBlobContainer;
    FFiscalValidator: TLazFiscalXmlValidator;
    FInspector: TLazTypeInfoInspector;
    FBenchmark: TLazCodeBenchmarkHarness;
    FMetricsProbe: TLazSystemMetricsProbe;

    { Variáveis de Animação }
    FGaugeVal: Double;
    FGaugeUp: Boolean;
    FTankVal: Double;
    FTankUp: Boolean;

    { Controles UI Auxiliares para Testes }
    BtnPopulateHeatmap: TButton;
    BtnTestVaultStore: TButton;
    BtnTestVaultRetrieve: TButton;
    BtnGenerateJwt: TButton;
    BtnValidateJwt: TButton;
    BtnCompressBlob: TButton;
    BtnValidateNFeKey: TButton;
    BtnRunRttiInspect: TButton;
    BtnRunMicroBenchmark: TButton;
    BtnCollectSysMetrics: TButton;

    FGeneratedToken: string;

    procedure LogMessage(const Msg: string);
    procedure SetupTabIndustrial;
    procedure SetupTabUI;
    procedure SetupTabSecurity;
    procedure SetupTabDiagnostics;

    { Handlers de Eventos }
    procedure OnHeatmapClick(Sender: TObject);
    procedure OnVaultStoreClick(Sender: TObject);
    procedure OnVaultRetrieveClick(Sender: TObject);
    procedure OnJwtGenerateClick(Sender: TObject);
    procedure OnJwtValidateClick(Sender: TObject);
    procedure OnBlobCompressClick(Sender: TObject);
    procedure OnValidateNFeClick(Sender: TObject);
    procedure OnRttiInspectClick(Sender: TObject);
    procedure OnBenchmarkClick(Sender: TObject);
    procedure OnMetricsClick(Sender: TObject);
    procedure DummyWork;
  public

  end;

var
  FrmMainDemo: TFrmMainDemo;

implementation

{$R *.lfm}

{ TFrmMainDemo }

procedure TFrmMainDemo.FormCreate(Sender: TObject);
begin
  LogMessage('Iniciando Demonstrador de Componentes de Engenharia Lazarus...');
  FGaugeVal := 0.0;
  FGaugeUp := True;
  FTankVal := 2000.0;
  FTankUp := True;

  // Instanciar Componentes de Lógica
  FVault := TLazCryptoVaultStorage.Create(Self);
  FJwt := TLazJwtSecurityManager.Create(Self);
  FJwt.SecretKey := 'MinhaChaveMestraUltraSegura2026!@#';
  FBlobContainer := TLazBinaryBlobContainer.Create(Self);
  FFiscalValidator := TLazFiscalXmlValidator.Create(Self);
  FInspector := TLazTypeInfoInspector.Create(Self);
  FBenchmark := TLazCodeBenchmarkHarness.Create(Self);
  FMetricsProbe := TLazSystemMetricsProbe.Create(Self);

  // Montar Telas
  SetupTabIndustrial;
  SetupTabUI;
  SetupTabSecurity;
  SetupTabDiagnostics;

  LogMessage('Todos os componentes carregados e inicializados com sucesso.');
end;

procedure TFrmMainDemo.FormDestroy(Sender: TObject);
begin
  // Liberação gerenciada pelo Owner (Self)
end;

procedure TFrmMainDemo.LogMessage(const Msg: string);
begin
  MemoLog.Lines.Add(FormatDateTime('[hh:nn:ss.zzz] ', Now) + Msg);
  MemoLog.SelStart := Length(MemoLog.Text);
end;

procedure TFrmMainDemo.BtnClearLogClick(Sender: TObject);
begin
  MemoLog.Clear;
  LogMessage('Console de log limpo.');
end;

procedure TFrmMainDemo.TimerGaugeAnimTimer(Sender: TObject);
begin
  // Animar Mostrador Analógico
  if FGaugeUp then
  begin
    FGaugeVal := FGaugeVal + 1.5;
    if FGaugeVal >= 160.0 then FGaugeUp := False;
  end
  else
  begin
    FGaugeVal := FGaugeVal - 1.5;
    if FGaugeVal <= 20.0 then FGaugeUp := True;
  end;

  if Assigned(FGauge) then
    FGauge.Value := FGaugeVal;

  // Animar Tanque Industrial
  if FTankUp then
  begin
    FTankVal := FTankVal + 50.0;
    if FTankVal >= 9200.0 then FTankUp := False;
  end
  else
  begin
    FTankVal := FTankVal - 50.0;
    if FTankVal <= 1500.0 then FTankUp := True;
  end;

  if Assigned(FTank) then
    FTank.CurrentLevel := FTankVal;
end;

procedure TFrmMainDemo.SetupTabIndustrial;
var
  Slice: TLazDonutSliceItem;
begin
  // 1. TLazAnalogGauge
  FGauge := TLazAnalogGauge.Create(Self);
  FGauge.Parent := PnlIndustrialControls;
  FGauge.SetBounds(20, 20, 240, 240);
  FGauge.GaugeTitle := 'VELOCIDADE';
  FGauge.UnitLabel := 'KM/H';
  FGauge.MinValue := 0;
  FGauge.MaxValue := 200;
  FGauge.WarningThreshold := 120;
  FGauge.CriticalThreshold := 160;

  // 2. TLazIndustrialTankGauge
  FTank := TLazIndustrialTankGauge.Create(Self);
  FTank.Parent := PnlIndustrialControls;
  FTank.SetBounds(280, 20, 160, 240);
  FTank.Capacity := 10000;
  FTank.CurrentLevel := 4500;
  FTank.LowAlarmLevel := 1000;
  FTank.HighAlarmLevel := 9000;
  FTank.UnitOfMeasure := 'LITROS';

  // 3. TLazVectorDonutChart
  FDonut := TLazVectorDonutChart.Create(Self);
  FDonut.Parent := PnlIndustrialControls;
  FDonut.SetBounds(460, 20, 280, 240);
  
  Slice := FDonut.Slices.Add;
  Slice.Caption := 'Vendas';
  Slice.Value := 45.0;
  Slice.Color := clTeal;

  Slice := FDonut.Slices.Add;
  Slice.Caption := 'Suporte';
  Slice.Value := 25.0;
  Slice.Color := clNavy;

  Slice := FDonut.Slices.Add;
  Slice.Caption := 'P&D';
  Slice.Value := 20.0;
  Slice.Color := clMaroon;

  Slice := FDonut.Slices.Add;
  Slice.Caption := 'Mkt';
  Slice.Value := 10.0;
  Slice.Color := clOlive;

  // 4. TLazProductStockIndicator
  FStock := TLazProductStockIndicator.Create(Self);
  FStock.Parent := PnlIndustrialControls;
  FStock.SetBounds(760, 20, 280, 110);

  // 5. TLazMatrixHeatmap
  FHeatmap := TLazMatrixHeatmap.Create(Self);
  FHeatmap.Parent := PnlIndustrialControls;
  FHeatmap.SetBounds(20, 280, 720, 150);
  FHeatmap.SetMatrixSize(4, 12);
  FHeatmap.PopulateRandom(10.0, 95.0);

  BtnPopulateHeatmap := TButton.Create(Self);
  BtnPopulateHeatmap.Parent := PnlIndustrialControls;
  BtnPopulateHeatmap.SetBounds(760, 280, 180, 36);
  BtnPopulateHeatmap.Caption := 'Gerar Heatmap Aleatório';
  BtnPopulateHeatmap.OnClick := @OnHeatmapClick;
end;

procedure TFrmMainDemo.OnHeatmapClick(Sender: TObject);
begin
  if Assigned(FHeatmap) then
  begin
    FHeatmap.PopulateRandom(5.0, 100.0);
    LogMessage('TLazMatrixHeatmap: Matriz regenerada com 48 pontos térmicos.');
  end;
end;

procedure TFrmMainDemo.SetupTabUI;
var
  LblInAccordion: TLabel;
  EditInAccordion: TEdit;
begin
  // 1. TLazCustomTabBar
  FTabBar := TLazCustomTabBar.Create(Self);
  FTabBar.Parent := PnlUIControls;
  FTabBar.Align := alTop;
  FTabBar.Height := 40;
  FTabBar.Tabs.AddTab('Dashboard Geral', -1, False);
  FTabBar.Tabs.AddTab('Pedidos Pendentes [4]', -1, True);
  FTabBar.Tabs.AddTab('Auditoria & Logs', -1, True);

  // 2. TLazAccordionContainer
  FAccordion := TLazAccordionContainer.Create(Self);
  FAccordion.Parent := PnlUIControls;
  FAccordion.SetBounds(20, 60, 500, 180);
  FAccordion.HeaderCaption := '▼ Painel Sanfonado Expansível (TLazAccordionContainer)';
  FAccordion.ExpandedHeight := 180;
  FAccordion.Collapsed := False;

  LblInAccordion := TLabel.Create(FAccordion);
  LblInAccordion.Parent := FAccordion;
  LblInAccordion.SetBounds(20, 50, 400, 20);
  LblInAccordion.Caption := 'Controles filhos hospedados internamente via csAcceptsControls:';

  EditInAccordion := TEdit.Create(FAccordion);
  EditInAccordion.Parent := FAccordion;
  EditInAccordion.SetBounds(20, 80, 320, 26);
  EditInAccordion.Text := 'Parâmetro de Configuração Avançada';

  // 3. TLazHighDpiThemedPanel
  FThemedPanel := TLazHighDpiThemedPanel.Create(Self);
  FThemedPanel.Parent := PnlUIControls;
  FThemedPanel.SetBounds(540, 60, 500, 180);

  // 4. TLazCRUDOperationsBar
  FCrudBar := TLazCRUDOperationsBar.Create(Self);
  FCrudBar.Parent := PnlUIControls;
  FCrudBar.SetBounds(20, 260, 1020, 50);
end;

procedure TFrmMainDemo.SetupTabSecurity;
begin
  // Botões de Teste de Segurança
  BtnTestVaultStore := TButton.Create(Self);
  BtnTestVaultStore.Parent := PnlSecurityControls;
  BtnTestVaultStore.SetBounds(30, 30, 240, 40);
  BtnTestVaultStore.Caption := '1. Guardar Segredo no Cofre';
  BtnTestVaultStore.OnClick := @OnVaultStoreClick;

  BtnTestVaultRetrieve := TButton.Create(Self);
  BtnTestVaultRetrieve.Parent := PnlSecurityControls;
  BtnTestVaultRetrieve.SetBounds(290, 30, 240, 40);
  BtnTestVaultRetrieve.Caption := '2. Recuperar do Cofre de Memória';
  BtnTestVaultRetrieve.OnClick := @OnVaultRetrieveClick;

  BtnGenerateJwt := TButton.Create(Self);
  BtnGenerateJwt.Parent := PnlSecurityControls;
  BtnGenerateJwt.SetBounds(30, 90, 240, 40);
  BtnGenerateJwt.Caption := '3. Emitir Token JWT HMAC-SHA256';
  BtnGenerateJwt.OnClick := @OnJwtGenerateClick;

  BtnValidateJwt := TButton.Create(Self);
  BtnValidateJwt.Parent := PnlSecurityControls;
  BtnValidateJwt.SetBounds(290, 90, 240, 40);
  BtnValidateJwt.Caption := '4. Validar Assinatura do Token';
  BtnValidateJwt.OnClick := @OnJwtValidateClick;

  BtnCompressBlob := TButton.Create(Self);
  BtnCompressBlob.Parent := PnlSecurityControls;
  BtnCompressBlob.SetBounds(30, 150, 240, 40);
  BtnCompressBlob.Caption := '5. Compactar Buffer ZLib (BLOB)';
  BtnCompressBlob.OnClick := @OnBlobCompressClick;

  BtnValidateNFeKey := TButton.Create(Self);
  BtnValidateNFeKey.Parent := PnlSecurityControls;
  BtnValidateNFeKey.SetBounds(290, 150, 240, 40);
  BtnValidateNFeKey.Caption := '6. Validar Chave NF-e (Módulo 11)';
  BtnValidateNFeKey.OnClick := @OnValidateNFeClick;
end;

procedure TFrmMainDemo.OnVaultStoreClick(Sender: TObject);
begin
  FVault.StoreSecret('DB_PASSWORD', 'MasterKey@Sql#2026$Encrypted');
  LogMessage('TLazCryptoVaultStorage: Chave "DB_PASSWORD" armazenada com blindagem XOR em memória.');
end;

procedure TFrmMainDemo.OnVaultRetrieveClick(Sender: TObject);
var
  Secret: string;
begin
  Secret := FVault.RetrieveSecret('DB_PASSWORD');
  LogMessage('TLazCryptoVaultStorage: Valor recuperado com sucesso: ' + Secret);
end;

procedure TFrmMainDemo.OnJwtGenerateClick(Sender: TObject);
begin
  FGeneratedToken := FJwt.GenerateToken('usuario_admin_01', 'token_id_998', '{"role":"Admin","dept":"IT"}');
  LogMessage('TLazJwtSecurityManager: Token gerado: ' + Copy(FGeneratedToken, 1, 45) + '... (tamanho: ' + IntToStr(Length(FGeneratedToken)) + ' bytes)');
end;

procedure TFrmMainDemo.OnJwtValidateClick(Sender: TObject);
var
  Claims: TJwtClaims;
  Status: TJwtValidationStatus;
begin
  if FGeneratedToken = '' then
  begin
    LogMessage('Aviso: Emita um token primeiro clicando no botão 3.');
    Exit;
  end;

  Status := FJwt.ValidateToken(FGeneratedToken, Claims);
  if Status = jvsValid then
    LogMessage('TLazJwtSecurityManager: [SUCESSO] Assinatura válida! Subject: ' + Claims.Subject + ', Expira em: ' + DateTimeToStr(Claims.ExpiresAt))
  else
    LogMessage('TLazJwtSecurityManager: [FALHA] Validação retornou código: ' + IntToStr(Ord(Status)));
end;

procedure TFrmMainDemo.OnBlobCompressClick(Sender: TObject);
begin
  FBlobContainer.Description := 'Arquivo de Configuração Binário';
  FBlobContainer.CompressionMode := bcmZLibMax;
  LogMessage('TLazBinaryBlobContainer: Buffer preparado com compressão bcmZLibMax.');
end;

procedure TFrmMainDemo.OnValidateNFeClick(Sender: TObject);
var
  SampleKey: string;
  IsValid: Boolean;
begin
  SampleKey := '35260100000000000000550010000000011000000010';
  IsValid := FFiscalValidator.ValidateAccessKey(SampleKey);
  LogMessage('TLazFiscalXmlValidator: Chave 44 dígitos [' + SampleKey + '] -> Válida: ' + BoolToStr(IsValid, True));
end;

procedure TFrmMainDemo.SetupTabDiagnostics;
begin
  BtnRunRttiInspect := TButton.Create(Self);
  BtnRunRttiInspect.Parent := PnlDiagControls;
  BtnRunRttiInspect.SetBounds(30, 30, 260, 40);
  BtnRunRttiInspect.Caption := '1. Inspecionar RTTI deste Form';
  BtnRunRttiInspect.OnClick := @OnRttiInspectClick;

  BtnRunMicroBenchmark := TButton.Create(Self);
  BtnRunMicroBenchmark.Parent := PnlDiagControls;
  BtnRunMicroBenchmark.SetBounds(310, 30, 260, 40);
  BtnRunMicroBenchmark.Caption := '2. Executar Micro-Benchmark';
  BtnRunMicroBenchmark.OnClick := @OnBenchmarkClick;

  BtnCollectSysMetrics := TButton.Create(Self);
  BtnCollectSysMetrics.Parent := PnlDiagControls;
  BtnCollectSysMetrics.SetBounds(590, 30, 260, 40);
  BtnCollectSysMetrics.Caption := '3. Coletar Métricas do Processo';
  BtnCollectSysMetrics.OnClick := @OnMetricsClick;
end;

procedure TFrmMainDemo.OnRttiInspectClick(Sender: TObject);
var
  Report: TStrings;
begin
  Report := FInspector.GetAncestryReport(Self);
  try
    LogMessage('--- TLazTypeInfoInspector: Genealogia de Classes ---');
    LogMessage(Report.Text);
  finally
    Report.Free;
  end;
end;

procedure TFrmMainDemo.DummyWork;
var
  i: Integer;
  d: Double;
begin
  d := 1.0;
  for i := 1 to 1000 do
    d := d * 1.0001;
end;

procedure TFrmMainDemo.OnBenchmarkClick(Sender: TObject);
var
  Rep: TBenchmarkReport;
begin
  Rep := FBenchmark.RunBenchmark('CalculoExemplo', @DummyWork);
  LogMessage(Format('TLazCodeBenchmarkHarness: [%s] Iterações: %d, Tempo Total: %.3f ms, Ops/seg: %.0f',
    [Rep.BenchmarkName, Rep.Iterations, Rep.TotalElapsedMs, Rep.OperationsPerSecond]));
end;

procedure TFrmMainDemo.OnMetricsClick(Sender: TObject);
var
  Snap: TProcessMetricsSnapshot;
begin
  Snap := FMetricsProbe.SampleNow;
  LogMessage(Format('TLazSystemMetricsProbe: Heap Alocado: %d KB | Threads: %d | Handles SO: %d | CPU: %.1f%%',
    [Snap.HeapAllocatedBytes div 1024, Snap.ActiveThreadsCount, Snap.OsHandlesCount, Snap.CpuUsagePercent]));
end;

end.
