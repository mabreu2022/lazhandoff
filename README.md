# 🚀 Engenharia Avançada de Componentes Object Pascal: A Enciclopédia Definitiva (50 Módulos)

[![Free Pascal](https://img.shields.io/badge/FPC-3.2.2%2B-blue.svg)](https://www.freepascal.org/)
[![Lazarus IDE](https://img.shields.io/badge/Lazarus-3.x%2B-teal.svg)](https://www.lazarus-ide.org/)
[![Delphi 12 Athens](https://img.shields.io/badge/Delphi-12%20Athens%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![CI/CD Multiplataforma](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green.svg)](.github/workflows/)
[![Licença MIT](https://img.shields.io/badge/Licen%C3%A7a-MIT-yellow.svg)](LICENSE)
[![Módulos Completos](https://img.shields.io/badge/M%C3%B3dulos-50%20completos-purple.svg)](#-tabela-mestra-dos-50-m%C3%B3dulos)

Coleção técnica definitiva e orientada à produção para arquitetos de software e desenvolvedores sêniores que desejam dominar a engenharia, design-time, computação gráfica, criptografia, mensageria IoT e integração de inteligência artificial em **Free Pascal / Lazarus 3.x+** e **Embarcadero Delphi 12 Athens+ (VCL & FMX)**.

---

## 📚 Os Dois Livros da Obra

### 📘 Livro 1: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
* **Ambiente Alvo:** Free Pascal 3.2.2+ e Lazarus 3.x+ (Multiplataforma: Windows, Linux e macOS).
* **Foco Técnico:** LCL (*Lazarus Component Library*), LCLIntf, IDEIntf (*Prop/Component Editors, Wizards*), FPC RTL, arquitetura WS (*Widgetset Bridge: Win32, GTK2/GTK3, Qt5/Qt6, Cocoa*), memória blindada e concorrência multithread.
* **Volume Gerado:** [`Livro1_Lazarus_LCL_Completo.pdf`](Livro1_Lazarus_LCL_Completo.pdf) (Diagramação Editorial Limpa O'Reilly / Addison-Wesley, fundo branco, blocos de código com realce tipográfico).

### 📕 Livro 2: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
* **Ambiente Alvo:** Embarcadero Delphi 12 Athens+ (12.x+) para Windows (Win32/Win64), Linux e Mobile.
* **Foco Técnico:** VCL moderna (*Per-Monitor v2 High-DPI, VCL Styles*), FireMonkey vetorial (*Styled Controls, FMX GPU Canvas*), ToolsAPI profunda (*OTA Interfaces, IDE Notifiers*), RTTI estendida, FastMM5 e concorrência paralela.
* **Volume Gerado:** [`Livro2_Delphi_Completo.pdf`](Livro2_Delphi_Completo.pdf) (Diagramação Editorial Limpa O'Reilly / Addison-Wesley).

---

## 🧭 Tabela Mestra dos 50 Módulos

| # | Módulo Temático | Componente / Foco | Unidade Lazarus (FPC/LCL) | Unidade Delphi (VCL/FMX) |
| :-: | :--- | :--- | :--- | :--- |
| **01** | Arquitetura e Hierarquia de Classes | Fundamentação RTL/LCL/VCL | [`LazTypeInfoInspector.pas`](lazarus/src/LazTypeInfoInspector.pas) | [`DlpTypeHierarchyInspector.pas`](delphi/src/DlpTypeHierarchyInspector.pas) |
| **02** | Ciclo de Vida e Notificações | Construtores, Loaded e FreeNotification | [`LazSafeLinkedPanel.pas`](lazarus/src/LazSafeLinkedPanel.pas) | [`DlpSafeLinkedContainer.pas`](delphi/src/DlpSafeLinkedContainer.pas) |
| **03** | Streaming, RTTI e Persistência | Propriedades Published e LFM/DFM | [`LazBinaryBlobContainer.pas`](lazarus/src/LazBinaryBlobContainer.pas) | [`DlpEncryptedDataStore.pas`](delphi/src/DlpEncryptedDataStore.pas) |
| **04** | Mensagens e Eventos do SO | Loops de Mensagens e Hooks | [`LazAsyncEventHook.pas`](lazarus/src/LazAsyncEventHook.pas) | [`DlpWindowsMessageInterceptor.pas`](delphi/src/DlpWindowsMessageInterceptor.pas) |
| **05** | Empacotamento de Packages | Desacoplamento Runtime / Design-time | [`laz_eng_components_rt.lpk`](Livro1_Lazarus_LCL/code/packages/laz_eng_components_rt.lpk) | [`DlpComponents_RT.dpk`](delphi/src/DlpComponents_RT.dpk) |
| **06** | Editores de Propriedades Customizados | Object Inspector e Diálogos | [`LazJsonConfigPropEditor.pas`](lazarus/src/LazJsonConfigPropEditor.pas) | [`DlpGradientPropEditor.pas`](delphi/src/DlpGradientPropEditor.pas) |
| **07** | Editores de Componentes e Verbos | Menus de Contexto no Designer | [`LazCardViewEditor.pas`](lazarus/src/LazCardViewEditor.pas) | [`DlpDashboardCardEditor.pas`](delphi/src/DlpDashboardCardEditor.pas) |
| **08** | Wizards e Especialistas de IDE | IDEIntf e ToolsAPI | [`LazCleanArchFormWizard.pas`](lazarus/src/LazCleanArchFormWizard.pas) | [`DlpCleanArchProjectWizard.pas`](delphi/src/DlpCleanArchProjectWizard.pas) |
| **09** | Controles Leves e Desenho Direto | TGraphicControl e Canvas Vetorial | [`LazAnalogGauge.pas`](lazarus/src/LazAnalogGauge.pas) | [`DlpAnalogGauge.pas`](delphi/src/DlpAnalogGauge.pas) |
| **10** | Controles Janelados e Sub-controles | TWinControl e Handles Nativos | [`LazAccordionContainer.pas`](lazarus/src/LazAccordionContainer.pas) | [`DlpAccordionContainer.pas`](delphi/src/DlpAccordionContainer.pas) |
| **11** | Coleções Tipadas e Sub-objetos | TCollection e TCollectionItem | [`LazCustomTabBar.pas`](lazarus/src/LazCustomTabBar.pas) | [`DlpCustomTabBar.pas`](delphi/src/DlpCustomTabBar.pas) |
| **12** | High-DPI, Temas e Escalonamento | Per-Monitor v2 e SVG | [`LazHighDpiThemedPanel.pas`](lazarus/src/LazHighDpiThemedPanel.pas) | [`DlpHighDpiThemedPanel.pas`](delphi/src/DlpHighDpiThemedPanel.pas) |
| **13** | Arquitetura de Dados e TDataLink | Acoplamento desacoplado de dados | [`LazCustomDBConnector.pas`](lazarus/src/LazCustomDBConnector.pas) | [`DlpCustomDBConnector.pas`](delphi/src/DlpCustomDBConnector.pas) |
| **14** | Controles de Dados Básicos | Edição e navegação em DataSets | [`LazDBBasicControls.pas`](lazarus/src/LazDBBasicControls.pas) | [`DlpDBBasicControls.pas`](delphi/src/DlpDBBasicControls.pas) |
| **15** | Controles de Dados Avançados | Seleção múltipla por Tags | [`LazDBLookupTagBox.pas`](lazarus/src/LazDBLookupTagBox.pas) | [`DlpDBLookupTagBox.pas`](delphi/src/DlpDBLookupTagBox.pas) |
| **16** | Monitoramento de Conexões e Transações | Interceptação SQL e Telemetria | [`LazDataConnectionMonitor.pas`](lazarus/src/LazDataConnectionMonitor.pas) | [`DlpDataConnectionMonitor.pas`](delphi/src/DlpDataConnectionMonitor.pas) |
| **17** | Drag-and-Drop e Interações no Designer | Arraste de dados e controles | [`LazFieldSchemaInspector.pas`](lazarus/src/LazFieldSchemaInspector.pas) | [`DlpFieldSchemaInspector.pas`](delphi/src/DlpFieldSchemaInspector.pas) |
| **18** | Geração Dinâmica de Telas | Auto-Form Builder com metadados | [`LazAutoFormBuilder.pas`](lazarus/src/LazAutoFormBuilder.pas) | [`DlpAutoFormBuilder.pas`](delphi/src/DlpAutoFormBuilder.pas) |
| **19** | Estudo de Caso: Gestão de Clientes | CRUD desacoplado corporativo | [`LazCRUDOperationsBar.pas`](lazarus/src/LazCRUDOperationsBar.pas) | [`DlpCRUDOperationsBar.pas`](delphi/src/DlpCRUDOperationsBar.pas) |
| **20** | Estudo de Caso: Gestão de Produtos | Precificação, Margens e Estoque | [`LazProductStockIndicator.pas`](lazarus/src/LazProductStockIndicator.pas) | [`DlpProductStockIndicator.pas`](delphi/src/DlpProductStockIndicator.pas) |
| **21** | Execução Assíncrona e Worker Threads | Concorrência sem congelar a UI | [`LazAsyncTaskRunner.pas`](lazarus/src/LazAsyncTaskRunner.pas) | [`DlpAsyncTaskRunner.pas`](delphi/src/DlpAsyncTaskRunner.pas) |
| **22** | Comunicação de Rede e APIs REST | Consumo HTTP REST com autenticação | [`LazRestClientBridge.pas`](lazarus/src/LazRestClientBridge.pas) | [`DlpRestClientBridge.pas`](delphi/src/DlpRestClientBridge.pas) |
| **23** | Hardware e Comunicação Serial | Balanças e periféricos de automação | [`LazSerialDeviceConnector.pas`](lazarus/src/LazSerialDeviceConnector.pas) | [`DlpSerialDeviceConnector.pas`](delphi/src/DlpSerialDeviceConnector.pas) |
| **24** | Testes Unitários e Profiling | Heaptrc, FastMM5 e Prevenção de Leaks | [`LazComponentTests.pas`](lazarus/src/LazComponentTests.pas) | [`DlpComponentTests.pas`](delphi/src/DlpComponentTests.pas) |
| **25** | Distribuição, OPM, GetIt e CI/CD | Publicação oficial em repositórios | [`LazPackageRegister.pas`](lazarus/src/LazPackageRegister.pas) | [`DlpPackageRegister.pas`](delphi/src/DlpPackageRegister.pas) |
| **26** | Gráficos de Alta Densidade em Tempo Real | Buffer circular de 100.000 pontos | [`LazRealtimeChartEngine.pas`](lazarus/src/LazRealtimeChartEngine.pas) | [`DlpRealtimeChartEngine.pas`](delphi/src/DlpRealtimeChartEngine.pas) |
| **27** | Medidores de Tanques Industriais | Simulação de fluidos e alertas | [`LazIndustrialTankGauge.pas`](lazarus/src/LazIndustrialTankGauge.pas) | [`DlpIndustrialTankGauge.pas`](delphi/src/DlpIndustrialTankGauge.pas) |
| **28** | Gráficos de Radar e Donut Vetorial | Trigonometria e Hit-Testing polar | [`LazVectorDonutChart.pas`](lazarus/src/LazVectorDonutChart.pas) | [`DlpVectorDonutChart.pas`](delphi/src/DlpVectorDonutChart.pas) |
| **29** | Visualizador de Mapas de Calor | Heatmaps matriciais contínuos | [`LazMatrixHeatmap.pas`](lazarus/src/LazMatrixHeatmap.pas) | [`DlpMatrixHeatmap.pas`](delphi/src/DlpMatrixHeatmap.pas) |
| **30** | Motor Gerador de PDFs Nativos | Relatórios e faturas sem DLL externa | [`LazFastPdfReport.pas`](lazarus/src/LazFastPdfReport.pas) | [`DlpFastPdfReport.pas`](delphi/src/DlpFastPdfReport.pas) |
| **31** | Pipeline de Exportação em Segundo Plano | Streaming CSV, JSONL e Planilhas XML | [`LazDataExportPipeline.pas`](lazarus/src/LazDataExportPipeline.pas) | [`DlpDataExportPipeline.pas`](delphi/src/DlpDataExportPipeline.pas) |
| **32** | Validador Fiscal XML (DF-e) | Módulo 11 e Digest SHA-1 | [`LazFiscalXmlValidator.pas`](lazarus/src/LazFiscalXmlValidator.pas) | [`DlpFiscalXmlValidator.pas`](delphi/src/DlpFiscalXmlValidator.pas) |
| **33** | Contêineres ZIP Criptografados | PKWARE binário e CRC-32 | [`LazEncryptedZipArchive.pas`](lazarus/src/LazEncryptedZipArchive.pas) | [`DlpEncryptedZipArchive.pas`](delphi/src/DlpEncryptedZipArchive.pas) |
| **34** | Validador e Emissor de Tokens JWT | HMAC-SHA256 e lista de revogação | [`LazJwtSecurityManager.pas`](lazarus/src/LazJwtSecurityManager.pas) | [`DlpJwtSecurityManager.pas`](delphi/src/DlpJwtSecurityManager.pas) |
| **35** | Cofre Seguro de Credenciais | Blindagem anti-dump em memória RAM | [`LazCryptoVaultStorage.pas`](lazarus/src/LazCryptoVaultStorage.pas) | [`DlpCryptoVaultStorage.pas`](delphi/src/DlpCryptoVaultStorage.pas) |
| **36** | Motor de Permissões Baseadas em Papéis | RBAC declarativo recursivo na tela | [`LazSecurityRoleManager.pas`](lazarus/src/LazSecurityRoleManager.pas) | [`DlpSecurityRoleManager.pas`](delphi/src/DlpSecurityRoleManager.pas) |
| **37** | Auditor de Integridade de Executáveis | Checksum SHA-256 e Anti-Tampering | [`LazIntegrityWatchdog.pas`](lazarus/src/LazIntegrityWatchdog.pas) | [`DlpIntegrityWatchdog.pas`](delphi/src/DlpIntegrityWatchdog.pas) |
| **38** | Cliente de Mensageria IoT via MQTT | MQTT 3.1.1 binário com QoS 0, 1 e 2 | [`LazMqttClientBridge.pas`](lazarus/src/LazMqttClientBridge.pas) | [`DlpMqttClientBridge.pas`](delphi/src/DlpMqttClientBridge.pas) |
| **39** | Servidor de Webhooks Embutido | Microservidor HTTP de alta velocidade | [`LazEmbeddedWebhookServer.pas`](lazarus/src/LazEmbeddedWebhookServer.pas) | [`DlpEmbeddedWebhookServer.pas`](delphi/src/DlpEmbeddedWebhookServer.pas) |
| **40** | Cliente WebSocket com Reconexão | RFC 6455 com backoff exponencial | [`LazWebSocketLiveClient.pas`](lazarus/src/LazWebSocketLiveClient.pas) | [`DlpWebSocketLiveClient.pas`](delphi/src/DlpWebSocketLiveClient.pas) |
| **41** | Hub de Notificações Push | Firebase FCM v1, Apple APNs e WebPush | [`LazPushNotificationHub.pas`](lazarus/src/LazPushNotificationHub.pas) | [`DlpPushNotificationHub.pas`](delphi/src/DlpPushNotificationHub.pas) |
| **42** | Dispatcher de Prompts para LLMs Locais | Streaming token a token (Ollama) | [`LazAiPromptDispatcher.pas`](lazarus/src/LazAiPromptDispatcher.pas) | [`DlpAiPromptDispatcher.pas`](delphi/src/DlpAiPromptDispatcher.pas) |
| **43** | Parser de Respostas Estruturadas JSON | Sanitização e hidratação de IA | [`LazAiStructuredExtractor.pas`](lazarus/src/LazAiStructuredExtractor.pas) | [`DlpAiStructuredExtractor.pas`](delphi/src/DlpAiStructuredExtractor.pas) |
| **44** | Motor de Busca Vetorial e Embeddings | Similaridade por Cosseno e Top-K RAG | [`LazVectorEmbeddingStore.pas`](lazarus/src/LazVectorEmbeddingStore.pas) | [`DlpVectorEmbeddingStore.pas`](delphi/src/DlpVectorEmbeddingStore.pas) |
| **45** | Construtor de Daemons e Serviços | Windows Services e Linux Systemd | [`LazSystemDaemonController.pas`](lazarus/src/LazSystemDaemonController.pas) | [`DlpSystemDaemonController.pas`](delphi/src/DlpSystemDaemonController.pas) |
| **46** | Sonda de Monitoramento de Sistema | Telemetria de CPU, Handles e Heap | [`LazSystemMetricsProbe.pas`](lazarus/src/LazSystemMetricsProbe.pas) | [`DlpSystemMetricsProbe.pas`](delphi/src/DlpSystemMetricsProbe.pas) |
| **47** | Gerenciador de Pool de Conexões SQL | Pooling thread-safe de banco | [`LazDatabaseConnectionPool.pas`](lazarus/src/LazDatabaseConnectionPool.pas) | [`DlpDatabaseConnectionPool.pas`](delphi/src/DlpDatabaseConnectionPool.pas) |
| **48** | Motor de Atualização Automática | OTA com validação SHA-256 e restart | [`LazAutoUpdateManager.pas`](lazarus/src/LazAutoUpdateManager.pas) | [`DlpAutoUpdateManager.pas`](delphi/src/DlpAutoUpdateManager.pas) |
| **49** | Harness de Micro-Benchmarks | Ciclos de CPU (RDTSC / QPC) | [`LazCodeBenchmarkHarness.pas`](lazarus/src/LazCodeBenchmarkHarness.pas) | [`DlpCodeBenchmarkHarness.pas`](delphi/src/DlpCodeBenchmarkHarness.pas) |
| **50** | Pipeline de CI/CD e Releases no GitHub | Compilação lazbuild/msbuild e releases | [`LazReleasePipeline.pas`](lazarus/src/LazReleasePipeline.pas) | [`DlpReleasePipeline.pas`](delphi/src/DlpReleasePipeline.pas) |

---

## 🛠️ Requisitos de Sistema

* **Lazarus & Free Pascal:**
  * Free Pascal Compiler 3.2.2 ou superior.
  * Lazarus IDE 3.0, 3.2 ou 3.4+.
  * Plataformas: Windows (x86_64), Linux (x86_64, aarch64), macOS.
* **Embarcadero Delphi:**
  * Delphi 12 Athens (12.0, 12.1 ou 12.2+).
  * Plataformas: Windows 32-bit e 64-bit (VCL & FMX), Linux 64-bit, Android e iOS.
* **Ferramental de Compilação Editorial (Opcional):**
  * [Pandoc](https://pandoc.org/) 3.0+.
  * Microsoft Edge ou Google Chrome (para geração de PDF headless).

---

## 📦 Como Instalar os Componentes nos IDEs

### No Lazarus IDE:
1. Abra o Lazarus.
2. Acesse o menu **Package** $\rightarrow$ **Open Package File (.lpk)...**.
3. Selecione `Livro1_Lazarus_LCL/code/packages/laz_eng_components_rt.lpk` e clique em **Compile**.
4. Em seguida, abra `Livro1_Lazarus_LCL/code/packages/laz_eng_components_dt.lpk`, clique em **Compile** e depois em **Use** $\rightarrow$ **Install**.
5. Confirme a recompilação da IDE. Após reiniciar, a paleta `'Lazarus Engenharia Avancada'` estará disponível com todos os componentes registrados.

### No Embarcadero Delphi 12:
1. Abra o Delphi 12 Athens.
2. Acesse **File** $\rightarrow$ **Open Project...** e selecione `Livro2_Delphi_VCL_FMX/code/packages/DlpComponents_RT.dpk`.
3. No Project Manager, clique com o botão direito sobre o pacote e selecione **Build** (para Win32 e Win64).
4. Abra o pacote de design-time `Livro2_Delphi_VCL_FMX/code/packages/DlpComponents_DT.dpk`, clique com o botão direito e selecione **Install**.
5. A paleta `'Delphi Engenharia Avancada'` será inserida na Tool Palette com todos os componentes prontos para uso em formulários VCL e FMX.

---

## 📖 Compilação Automatizada dos Livros em PDF

Para recompilar os dois livros em formato PDF com o tema editorial limpo (padrão de editora internacional com fundo branco e destaque de sintaxe Pascal):

```powershell
# Execução no PowerShell
powershell -ExecutionPolicy Bypass -File "scripts/compile_books_to_pdf.ps1"
```

O script utiliza Pandoc + o tema `scripts/book_theme.css` + o motor headless do Chromium/Edge para compilar e renderizar os dois livros em menos de 15 segundos sem gerar URLs ou rodapés de navegador.

---

## 📄 Licença

Este projeto é distribuído sob a licença **MIT**. Consulte o arquivo [`LICENSE`](LICENSE) para mais detalhes.
