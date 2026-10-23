{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 05: Empacotamento Profissional (Packages .lpk)
  Unidade: LazPackageRegister
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Unidade exclusiva de Design-Time que centraliza o registro oficial
             de todos os componentes e editores dos 50 módulos da obra
             na Tool Palette do Lazarus IDE.
==============================================================================}
unit LazPackageRegister;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  LResources,
  LazAccordionContainer,
  LazAiPromptDispatcher,
  LazAiStructuredExtractor,
  LazAnalogGauge,
  LazAsyncEventHook,
  LazAsyncTaskRunner,
  LazAutoFormBuilder,
  LazAutoUpdateManager,
  LazBinaryBlobContainer,
  LazCardView,
  LazCardViewEditor,
  LazCleanArchFormWizard,
  LazCodeBenchmarkHarness,
  LazCRUDOperationsBar,
  LazCryptoVaultStorage,
  LazCustomDBConnector,
  LazCustomTabBar,
  LazDatabaseConnectionPool,
  LazDataConnectionMonitor,
  LazDataExportPipeline,
  LazDBBasicControls,
  LazDBLookupTagBox,
  LazEmbeddedWebhookServer,
  LazEncryptedZipArchive,
  LazFastPdfReport,
  LazFieldSchemaInspector,
  LazFiscalXmlValidator,
  LazHighDpiThemedPanel,
  LazIndustrialTankGauge,
  LazIntegrityWatchdog,
  LazJsonConfig,
  LazJsonConfigPropEditor,
  LazJwtSecurityManager,
  LazMatrixHeatmap,
  LazMqttClientBridge,
  LazProductStockIndicator,
  LazPushNotificationHub,
  LazRealtimeChartEngine,
  LazReleasePipeline,
  LazRestClientBridge,
  LazSafeLinkedPanel,
  LazSecurityRoleManager,
  LazSerialDeviceConnector,
  LazSystemDaemonController,
  LazSystemMetricsProbe,
  LazTypeInfoInspector,
  LazVectorDonutChart,
  LazVectorEmbeddingStore,
  LazWebSocketLiveClient;

{ Procedimento oficial invocado pela IDE Lazarus ao carregar o pacote }
procedure Register;

implementation

procedure Register;
begin
  { Registra todos os componentes, editores e wizards dos módulos do livro }
  LazAccordionContainer.Register;
  LazAiPromptDispatcher.Register;
  LazAiStructuredExtractor.Register;
  LazAnalogGauge.Register;
  LazAsyncEventHook.Register;
  LazAsyncTaskRunner.Register;
  LazAutoFormBuilder.Register;
  LazAutoUpdateManager.Register;
  LazBinaryBlobContainer.Register;
  LazCardView.Register;
  LazCardViewEditor.Register;
  LazCleanArchFormWizard.Register;
  LazCodeBenchmarkHarness.Register;
  LazCRUDOperationsBar.Register;
  LazCryptoVaultStorage.Register;
  LazCustomDBConnector.Register;
  LazCustomTabBar.Register;
  LazDatabaseConnectionPool.Register;
  LazDataConnectionMonitor.Register;
  LazDataExportPipeline.Register;
  LazDBBasicControls.Register;
  LazDBLookupTagBox.Register;
  LazEmbeddedWebhookServer.Register;
  LazEncryptedZipArchive.Register;
  LazFastPdfReport.Register;
  LazFieldSchemaInspector.Register;
  LazFiscalXmlValidator.Register;
  LazHighDpiThemedPanel.Register;
  LazIndustrialTankGauge.Register;
  LazIntegrityWatchdog.Register;
  LazJsonConfig.Register;
  LazJsonConfigPropEditor.Register;
  LazJwtSecurityManager.Register;
  LazMatrixHeatmap.Register;
  LazMqttClientBridge.Register;
  LazProductStockIndicator.Register;
  LazPushNotificationHub.Register;
  LazRealtimeChartEngine.Register;
  LazReleasePipeline.Register;
  LazRestClientBridge.Register;
  LazSafeLinkedPanel.Register;
  LazSecurityRoleManager.Register;
  LazSerialDeviceConnector.Register;
  LazSystemDaemonController.Register;
  LazSystemMetricsProbe.Register;
  LazTypeInfoInspector.Register;
  LazVectorDonutChart.Register;
  LazVectorEmbeddingStore.Register;
  LazWebSocketLiveClient.Register;
end;

initialization
  { Inicialização opcional de recursos de ícones (.lrs) compilados via lazres }
  {$IFDEF HAS_LRS_ICONS}
  {$I laz_components_icons.lrs}
  {$ENDIF}

end.
