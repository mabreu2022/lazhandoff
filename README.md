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

### 📑 Catálogo Técnico & Resumo Executivo dos 50 Componentes (Guia Rápido)
* **Finalidade:** Ficha técnica isolada contendo a tabela comparativa completa dos 50 componentes (Lazarus e Delphi), mapeamento das unidades fonte, finalidades arquiteturais, cenários reais de aplicação e guia rápido dos 50 projetos de exemplo.
* **Volume Gerado:** [`Resumo_50_Componentes_Lazarus_Delphi.pdf`](Resumo_50_Componentes_Lazarus_Delphi.pdf) (Diagramação editorial profissional em A4 Paisagem, otimizado para leitura fluida em tela e impressão de referência técnica).

---

## 🧭 Tabela Mestra dos 50 Módulos: Guia de Finalidade e Arquitetura

Abaixo está a relação analítica dos 50 módulos da obra, informando o propósito e para que serve cada componente desenvolvido:

| # | Módulo Temático | Componente (Classe) | Unidade Lazarus (FPC/LCL) | Unidade Delphi (VCL/FMX) | Para que serve (Finalidade Principal e Cenário de Aplicação) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **01** | Diagnóstico / RTTI | `TLazTypeInfoInspector` / `TDlpTypeHierarchyInspector` | [`LazTypeInfoInspector.pas`](Livro1_Lazarus_LCL/code/units/LazTypeInfoInspector.pas) | [`DlpTypeHierarchyInspector.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpTypeHierarchyInspector.pas) | **Inspeciona dinamicamente em tempo de execução a árvore de herança de qualquer classe (até TObject) e extrai metadados RTTI completos (propriedades published, métodos, tipos e atributos), gerando relatórios textuais ou em Markdown para auditoria e documentação.** | 
| **02** | Contêineres Seguros | `TLazSafeLinkedPanel` / `TDlpSafeLinkedContainer` | [`LazSafeLinkedPanel.pas`](Livro1_Lazarus_LCL/code/units/LazSafeLinkedPanel.pas) | [`DlpSafeLinkedContainer.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpSafeLinkedContainer.pas) | **Contêiner visual com gerenciamento de referências fracas para múltiplos componentes do formulário. Utiliza FreeNotification e Notification(opRemove) para anular ponteiros automaticamente quando um controle associado é destruído, eliminando 100% dos erros de Access Violation.** | 
| **03** | Persistência / Streaming | `TLazBinaryBlobContainer` / `TDlpEncryptedDataStore` | [`LazBinaryBlobContainer.pas`](Livro1_Lazarus_LCL/code/units/LazBinaryBlobContainer.pas) | [`DlpEncryptedDataStore.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpEncryptedDataStore.pas) | **Armazena, comprime (ZLib/Deflate) e serializa arquivos binários, imagens ou documentos diretamente dentro do arquivo de layout (.lfm / .dfm) via DefineProperties, permitindo empacotar recursos embutidos sem depender de arquivos soltos em disco.** | 
| **04** | Sistema / Mensageria | `LazAsyncEventHook` / `TDlpWindowsMessageInterceptor` | [`LazAsyncEventHook.pas`](Livro1_Lazarus_LCL/code/units/LazAsyncEventHook.pas) | [`DlpWindowsMessageInterceptor.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpWindowsMessageInterceptor.pas) | **Intercepta mensagens de janela do SO em baixo nível (subclassing de WndProc) como movimentação, foco, redimensionamento e teclas globais, despachando eventos assíncronos desacoplados sem bloquear o loop de mensagens da interface.** | 
| **05** | Arquitetura de Pacotes | `LazPackageRegister` / `DlpPackageRegister` | [`LazPackageRegister.pas`](Livro1_Lazarus_LCL/code/units/LazPackageRegister.pas) | [`DlpPackageRegister.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpPackageRegister.pas) | **Centraliza o registro modular de componentes e editores na Tool Palette e Object Inspector, separando rigorosamente o pacote de tempo de execução (Runtime .lpk / .dpk) do pacote de projeto (Design-time .lpk / .dpk) com ícones profissionais.** | 
| **06** | Design-Time / IDEIntf | `TLazJsonConfigPropEditor` / `TDlpGradientPropEditor` | [`LazJsonConfigPropEditor.pas`](Livro1_Lazarus_LCL/code/units/LazJsonConfigPropEditor.pas) | [`DlpGradientPropEditor.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpGradientPropEditor.pas) | **Estende o Object Inspector da IDE com janelas de diálogo modais interativas ([...]) e listas suspensas dinâmicas (dropdown paValueList) para edição amigável de tipos complexos, como payloads JSON e gradientes de cores.** | 
| **07** | Design-Time / Verbos | `TLazCardViewEditor` / `TDlpDashboardCardEditor` | [`LazCardViewEditor.pas`](Livro1_Lazarus_LCL/code/units/LazCardViewEditor.pas) | [`DlpDashboardCardEditor.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpDashboardCardEditor.pas) | **Editor de componentes que injeta verbos de menu de contexto no clique direito do Form Designer da IDE ('Adicionar Item', 'Trocar Layout', 'Verificar Status') e gerencia a ação executada ao dar duplo-clique sobre o controle.** | 
| **08** | Wizards / ToolsAPI | `TLazCleanArchFormWizard` / `TDlpCleanArchProjectWizard` | [`LazCleanArchFormWizard.pas`](Livro1_Lazarus_LCL/code/units/LazCleanArchFormWizard.pas) | [`DlpCleanArchProjectWizard.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpCleanArchProjectWizard.pas) | **Assistente de projeto (Wizard) integrado à IDE que gera algoritmicamente toda a estrutura de pastas e unidades segundo a Clean Architecture (Domain, UseCases, Repositories e UI Controllers) com código limpo e desacoplado.** | 
| **09** | Instrumentação Leve | `TLazAnalogGauge` / `TDlpAnalogGauge` | [`LazAnalogGauge.pas`](Livro1_Lazarus_LCL/code/units/LazAnalogGauge.pas) | [`DlpAnalogGauge.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpAnalogGauge.pas) | **Mostrador analógico circular leve (TGraphicControl sem janela de SO) de alta performance a 60 FPS com Double Buffering, agulha vetorial por trigonometria (270°), pivô metálico, zonas coloridas configuráveis e disparo de alarmes ao atingir limites.** | 
| **10** | Contêineres Janelados | `TLazAccordionContainer` / `TDlpAccordionContainer` | [`LazAccordionContainer.pas`](Livro1_Lazarus_LCL/code/units/LazAccordionContainer.pas) | [`DlpAccordionContainer.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpAccordionContainer.pas) | **Painel sanfonado colapsável janelado (TWinControl) com suporte à hospedagem de filhos no designer (csAcceptsControls), animação fluida por timer sem sobrecarga em design-time, acessibilidade total via teclado (Enter/Espaço/Tab) e chevron dinâmico.** | 
| **11** | Navegação / Abas | `TLazCustomTabBar` / `TDlpCustomTabBar` | [`LazCustomTabBar.pas`](Livro1_Lazarus_LCL/code/units/LazCustomTabBar.pas) | [`DlpCustomTabBar.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpCustomTabBar.pas) | **Barra de guias e abas modernas estilizadas baseadas em coleções tipadas (TCollection/TCollectionItem), com suporte a badges numéricos de notificação, botões de fechamento individual, scroll horizontal de abas e estados hover/ativo.** | 
| **12** | UI Moderna / High-DPI | `TLazHighDpiThemedPanel` / `TDlpHighDpiThemedPanel` | [`LazHighDpiThemedPanel.pas`](Livro1_Lazarus_LCL/code/units/LazHighDpiThemedPanel.pas) | [`DlpHighDpiThemedPanel.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpHighDpiThemedPanel.pas) | **Painel moderno com cantos arredondados, bordas elegantes e sombreamento suave que recalcula automaticamente proporções, margens e espessuras em monitores 4K de alta densidade (Per-Monitor v2 DPI 96 até 288+).** | 
| **13** | Dados / TDataLink | `TLazCustomDBConnector` / `TDlpCustomDBConnector` | [`LazCustomDBConnector.pas`](Livro1_Lazarus_LCL/code/units/LazCustomDBConnector.pas) | [`DlpCustomDBConnector.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpCustomDBConnector.pas) | **Componente intermediário DB-Aware que encapsula um TDataLink customizado, sincronizando automaticamente o estado de componentes gráficos com a abertura, fechamento e alteração de dados de qualquer TDataSource/TDataSet.** | 
| **14** | Controles de Dados | `TLazDBBasicControls` / `TDlpDBBasicControls` | [`LazDBBasicControls.pas`](Livro1_Lazarus_LCL/code/units/LazDBBasicControls.pas) | [`DlpDBBasicControls.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpDBBasicControls.pas) | **Família de controles básicos DB-Aware (Label, Edit e CheckBox) com binding bidirecional com DataSet, validação automática de tipos, controle estrito de edição/leitura e tratamento de campos nulos.** | 
| **15** | Controles Avançados | `TLazDBLookupTagBox` / `TDlpDBLookupTagBox` | [`LazDBLookupTagBox.pas`](Livro1_Lazarus_LCL/code/units/LazDBLookupTagBox.pas) | [`DlpDBLookupTagBox.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpDBLookupTagBox.pas) | **Caixa de entrada inteligente para seleção múltipla com chips visuais (tags) pesquisáveis a partir de uma tabela de lookup, permitindo adicionar/remover itens e gravando os IDs selecionados como lista ou JSON.** | 
| **16** | Telemetria / Banco | `TLazDataConnectionMonitor` / `TDlpDataConnectionMonitor` | [`LazDataConnectionMonitor.pas`](Livro1_Lazarus_LCL/code/units/LazDataConnectionMonitor.pas) | [`DlpDataConnectionMonitor.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpDataConnectionMonitor.pas) | **Intercepta e audita em tempo real a execução de queries SQL, registrando o tempo de resposta em milissegundos, quantidade de linhas afetadas e disparando alertas para consultas lentas (slow queries).** | 
| **17** | Design-Time / DragDrop | `TLazFieldSchemaInspector` / `TDlpFieldSchemaInspector` | [`LazFieldSchemaInspector.pas`](Livro1_Lazarus_LCL/code/units/LazFieldSchemaInspector.pas) | [`DlpFieldSchemaInspector.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpFieldSchemaInspector.pas) | **Lê o dicionário de dados de um DataSet e habilita o arrastar e soltar (drag-and-drop) de colunas diretamente para a tela, gerando automaticamente os labels e componentes de entrada configurados.** | 
| **18** | Geração de Telas | `TLazAutoFormBuilder` / `TDlpAutoFormBuilder` | [`LazAutoFormBuilder.pas`](Livro1_Lazarus_LCL/code/units/LazAutoFormBuilder.pas) | [`DlpAutoFormBuilder.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpAutoFormBuilder.pas) | **Motor generativo que constrói algoritmicamente formulários inteiros em tempo de execução ou de design com base em metadados RTTI ou metadados de banco de dados, posicionando campos e botões com alinhamento perfeito.** | 
| **19** | Barras de Ação | `TLazCRUDOperationsBar` / `TDlpCRUDOperationsBar` | [`LazCRUDOperationsBar.pas`](Livro1_Lazarus_LCL/code/units/LazCRUDOperationsBar.pas) | [`DlpCRUDOperationsBar.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpCRUDOperationsBar.pas) | **Barra de ferramentas completa para manutenção de registros (Novo, Editar, Excluir, Gravar, Cancelar, Atualizar, Buscar) que controla automaticamente o estado ativo dos botões com base no modo do DataSet.** | 
| **20** | Indicadores Comerciais | `TLazProductStockIndicator` / `TDlpProductStockIndicator` | [`LazProductStockIndicator.pas`](Livro1_Lazarus_LCL/code/units/LazProductStockIndicator.pas) | [`DlpProductStockIndicator.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpProductStockIndicator.pas) | **Badge/card gráfico que renderiza o nível atual de estoque, ponto crítico de reposição, barra de capacidade percentual e indicadores de margem de lucro com paletas dinâmicas verde/amarelo/vermelho.** | 
| **21** | Concorrência / Threads | `TLazAsyncTaskRunner` / `TDlpAsyncTaskRunner` | [`LazAsyncTaskRunner.pas`](Livro1_Lazarus_LCL/code/units/LazAsyncTaskRunner.pas) | [`DlpAsyncTaskRunner.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpAsyncTaskRunner.pas) | **Executor assíncrono que processa tarefas demoradas em worker threads de segundo plano com proteção de memória, cancelamento limpo e sincronização segura de resultados com a thread principal sem travar a UI.** | 
| **22** | Comunicação / REST | `TLazRestClientBridge` / `TDlpRestClientBridge` | [`LazRestClientBridge.pas`](Livro1_Lazarus_LCL/code/units/LazRestClientBridge.pas) | [`DlpRestClientBridge.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpRestClientBridge.pas) | **Cliente HTTP de alta velocidade para consumo de APIs RESTful (GET, POST, PUT, DELETE, PATCH), com suporte a cabeçalhos customizados, autenticação Bearer/Basic, timeouts resilientes e conversão de JSON.** | 
| **23** | Hardware / Automação | `TLazSerialDeviceConnector` / `TDlpSerialDeviceConnector` | [`LazSerialDeviceConnector.pas`](Livro1_Lazarus_LCL/code/units/LazSerialDeviceConnector.pas) | [`DlpSerialDeviceConnector.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpSerialDeviceConnector.pas) | **Conector de comunicação bidirecional com portas seriais (RS-232, RS-485 e USB Virtual COM), com buffer circular de alta precisão, detecção de perda de sinal e decodificação automática de pacotes de dados.** | 
| **24** | Qualidade / Testes | `LazComponentTests` / `DlpComponentTests` | [`LazComponentTests.pas`](Livro1_Lazarus_LCL/code/units/LazComponentTests.pas) | [`DlpComponentTests.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpComponentTests.pas) | **Estrutura de testes unitários automatizados para validação do ciclo de vida dos componentes, prevenção de memory leaks e análise de estresse sob Heaptrc (FPC) e FastMM5 (Delphi).** | 
| **25** | Distribuição / OPM | `LazPackageRegister` / `DlpPackageRegister` | [`LazPackageRegister.pas`](Livro1_Lazarus_LCL/code/units/LazPackageRegister.pas) | [`DlpPackageRegister.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpPackageRegister.pas) | **Mecanismo oficial de empacotamento, registro de metadados e versionamento semântico para distribuição no Online Package Manager (Lazarus) e GetIt Package Manager (Delphi).** | 
| **26** | Gráficos de Alta Densidade | `TLazRealtimeChartEngine` / `TDlpRealtimeChartEngine` | [`LazRealtimeChartEngine.pas`](Livro1_Lazarus_LCL/code/units/LazRealtimeChartEngine.pas) | [`DlpRealtimeChartEngine.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpRealtimeChartEngine.pas) | **Motor de renderização gráfica vetorial para séries temporais contínuas, mantendo buffer circular de alta velocidade para plotar até 100.000 pontos em tempo real com auto-escala e 60 FPS estáveis.** | 
| **27** | Instrumentação Industrial | `TLazIndustrialTankGauge` / `TDlpIndustrialTankGauge` | [`LazIndustrialTankGauge.pas`](Livro1_Lazarus_LCL/code/units/LazIndustrialTankGauge.pas) | [`DlpIndustrialTankGauge.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpIndustrialTankGauge.pas) | **Mostrador visual em forma de tanque ou silo com representação realista de fluidos, gradientes térmicos, efeito de ondas na superfície, marcadores numéricos de volume e limites sonoros/visuais de segurança.** | 
| **28** | Gráficos Vetoriais | `TLazVectorDonutChart` / `TDlpVectorDonutChart` | [`LazVectorDonutChart.pas`](Livro1_Lazarus_LCL/code/units/LazVectorDonutChart.pas) | [`DlpVectorDonutChart.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpVectorDonutChart.pas) | **Gráfico de setores estilo Donut/Pizza com cálculo trigonométrico polar de fatias, detecção de clique na fatia individual (hit-testing preciso), realce da fatia selecionada e legendas percentuais automáticas.** | 
| **29** | Visualização de Dados | `TLazMatrixHeatmap` / `TDlpMatrixHeatmap` | [`LazMatrixHeatmap.pas`](Livro1_Lazarus_LCL/code/units/LazMatrixHeatmap.pas) | [`DlpMatrixHeatmap.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpMatrixHeatmap.pas) | **Mapa de calor bidimensional matricial com interpolação contínua de paletas térmicas (azul frio até vermelho quente), suporte a grades de qualquer dimensão e exibição de tooltips com valores exatos por célula.** | 
| **30** | Geração de Documentos | `TLazFastPdfReport` / `TDlpFastPdfReport` | [`LazFastPdfReport.pas`](Livro1_Lazarus_LCL/code/units/LazFastPdfReport.pas) | [`DlpFastPdfReport.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpFastPdfReport.pas) | **Gerador nativo e ultrarrápido de arquivos PDF em código Pascal puro sem depender de DLLs ou drivers externos, desenhando cabeçalhos, tabelas com quebra de página automática, fontes e linhas.** | 
| **31** | Pipelines de Dados | `TLazDataExportPipeline` / `TDlpDataExportPipeline` | [`LazDataExportPipeline.pas`](Livro1_Lazarus_LCL/code/units/LazDataExportPipeline.pas) | [`DlpDataExportPipeline.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpDataExportPipeline.pas) | **Pipeline assíncrono de exportação em streaming para múltiplos formatos (CSV, JSON Lines e XML Spreadsheet), consumindo DataSets gigantescos sem inflar a memória RAM e emitindo progresso percentual.** | 
| **32** | Automação Fiscal (DF-e) | `TLazFiscalXmlValidator` / `TDlpFiscalXmlValidator` | [`LazFiscalXmlValidator.pas`](Livro1_Lazarus_LCL/code/units/LazFiscalXmlValidator.pas) | [`DlpFiscalXmlValidator.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpFiscalXmlValidator.pas) | **Validador e auditor de arquivos XML fiscais brasileiros (NF-e, NFC-e, CT-e, MDF-e), validando o dígito verificador da chave de acesso de 44 dígitos (algoritmo Módulo 11) e a assinatura digital SHA-1.** | 
| **33** | Compressão & Segurança | `TLazEncryptedZipArchive` / `TDlpEncryptedZipArchive` | [`LazEncryptedZipArchive.pas`](Livro1_Lazarus_LCL/code/units/LazEncryptedZipArchive.pas) | [`DlpEncryptedZipArchive.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpEncryptedZipArchive.pas) | **Compactação, descompactação e leitura de arquivos ZIP com criptografia de senha conforme o padrão PKWARE, cálculo automático de CRC-32 e suporte a streaming de arquivos direto na memória.** | 
| **34** | Segurança / JWT | `TLazJwtSecurityManager` / `TDlpJwtSecurityManager` | [`LazJwtSecurityManager.pas`](Livro1_Lazarus_LCL/code/units/LazJwtSecurityManager.pas) | [`DlpJwtSecurityManager.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpJwtSecurityManager.pas) | **Emissor, assinador e validador de tokens de autenticação JWT (RFC 7519) com algoritmo HMAC-SHA256, verificação automática de expiração (exp), emissor (iss), claims personalizados e lista de revogação.** | 
| **35** | Cofre de Segredos | `TLazCryptoVaultStorage` / `TDlpCryptoVaultStorage` | [`LazCryptoVaultStorage.pas`](Livro1_Lazarus_LCL/code/units/LazCryptoVaultStorage.pas) | [`DlpCryptoVaultStorage.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpCryptoVaultStorage.pas) | **Cofre em memória para armazenamento ultra-seguro de credenciais, chaves privadas e senhas de banco com criptografia dinâmica, ofuscação XOR e limpeza automática de buffers contra inspeção por dumps de RAM.** | 
| **36** | Segurança / RBAC | `TLazSecurityRoleManager` / `TDlpSecurityRoleManager` | [`LazSecurityRoleManager.pas`](Livro1_Lazarus_LCL/code/units/LazSecurityRoleManager.pas) | [`DlpSecurityRoleManager.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpSecurityRoleManager.pas) | **Motor declarativo de permissões baseado em papéis (RBAC). Varre automaticamente os controles do formulário (botões, menus, abas) e ajusta propriedades Visible/Enabled conforme os privilégios do usuário ativo.** | 
| **37** | Auditoria / Anti-Tamper | `TLazIntegrityWatchdog` / `TDlpIntegrityWatchdog` | [`LazIntegrityWatchdog.pas`](Livro1_Lazarus_LCL/code/units/LazIntegrityWatchdog.pas) | [`DlpIntegrityWatchdog.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpIntegrityWatchdog.pas) | **Auditor de integridade que calcula o checksum criptográfico SHA-256 do próprio executável em tempo de boot e compara com assinaturas esperadas, alertando ou abortando o sistema se detectar adulteração no binário.** | 
| **38** | Mensageria IoT (MQTT) | `TLazMqttClientBridge` / `TDlpMqttClientBridge` | [`LazMqttClientBridge.pas`](Livro1_Lazarus_LCL/code/units/LazMqttClientBridge.pas) | [`DlpMqttClientBridge.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpMqttClientBridge.pas) | **Cliente MQTT 3.1.1 leve e assíncrono para publicação e subscrição de tópicos com suporte a QoS 0, 1 e 2, reconexão transparente e processamento de telemetria de sensores industriais e dispositivos embarcados.** | 
| **39** | Serviços / Webhooks | `TLazEmbeddedWebhookServer` / `TDlpEmbeddedWebhookServer` | [`LazEmbeddedWebhookServer.pas`](Livro1_Lazarus_LCL/code/units/LazEmbeddedWebhookServer.pas) | [`DlpEmbeddedWebhookServer.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpEmbeddedWebhookServer.pas) | **Micro-servidor HTTP embutido de altíssima velocidade que escuta em uma porta TCP dedicada e recebe notificações de webhooks (JSON/POST), despachando os eventos imediatamente para o aplicativo desktop.** | 
| **40** | Comunicação em Tempo Real | `TLazWebSocketLiveClient` / `TDlpWebSocketLiveClient` | [`LazWebSocketLiveClient.pas`](Livro1_Lazarus_LCL/code/units/LazWebSocketLiveClient.pas) | [`DlpWebSocketLiveClient.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpWebSocketLiveClient.pas) | **Cliente WebSocket de canal contínuo full-duplex (RFC 6455) com suporte a mensagens de texto e binárias, batimento de coração periódico (Ping/Pong) e reconexão automática com backoff exponencial.** | 
| **41** | Notificações / Cloud | `TLazPushNotificationHub` / `TDlpPushNotificationHub` | [`LazPushNotificationHub.pas`](Livro1_Lazarus_LCL/code/units/LazPushNotificationHub.pas) | [`DlpPushNotificationHub.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpPushNotificationHub.pas) | **Despachante de notificações push centralizado que conecta diretamente com serviços na nuvem (Google Firebase Cloud Messaging v1 e Apple APNs), enviando alertas para smartphones e navegadores.** | 
| **42** | Inteligência Artificial | `TLazAiPromptDispatcher` / `TDlpAiPromptDispatcher` | [`LazAiPromptDispatcher.pas`](Livro1_Lazarus_LCL/code/units/LazAiPromptDispatcher.pas) | [`DlpAiPromptDispatcher.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpAiPromptDispatcher.pas) | **Ponte de integração com modelos de linguagem (LLMs locais como Ollama/Llama e APIs como OpenAI/Gemini), suportando envio de prompts estruturados e recepção de tokens gerados em streaming direto para a tela.** | 
| **43** | Processamento de IA | `TLazAiStructuredExtractor` / `TDlpAiStructuredExtractor` | [`LazAiStructuredExtractor.pas`](Livro1_Lazarus_LCL/code/units/LazAiStructuredExtractor.pas) | [`DlpAiStructuredExtractor.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpAiStructuredExtractor.pas) | **Parser semântico que higieniza saídas geradas por Inteligência Artificial, extraindo blocos JSON limpos, validando schemas e hidratando automaticamente classes e registros Pascal tipados.** | 
| **44** | Busca Vetorial / RAG | `TLazVectorEmbeddingStore` / `TDlpVectorEmbeddingStore` | [`LazVectorEmbeddingStore.pas`](Livro1_Lazarus_LCL/code/units/LazVectorEmbeddingStore.pas) | [`DlpVectorEmbeddingStore.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpVectorEmbeddingStore.pas) | **Armazenamento em memória de vetores multidimensionais (embeddings) com cálculo ultrarrápido de Similaridade por Cosseno e busca semântica Top-K para arquiteturas de RAG (Retrieval-Augmented Generation).** | 
| **45** | Daemons & Serviços | `TLazSystemDaemonController` / `TDlpSystemDaemonController` | [`LazSystemDaemonController.pas`](Livro1_Lazarus_LCL/code/units/LazSystemDaemonController.pas) | [`DlpSystemDaemonController.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpSystemDaemonController.pas) | **Controlador multiplataforma de serviços em segundo plano (Windows Services e Linux Daemons via Systemd), com suporte a instalação, início, parada, pausa e registro de ocorrências em log do SO.** | 
| **46** | Sonda de Telemetria | `TLazSystemMetricsProbe` / `TDlpSystemMetricsProbe` | [`LazSystemMetricsProbe.pas`](Livro1_Lazarus_LCL/code/units/LazSystemMetricsProbe.pas) | [`DlpSystemMetricsProbe.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpSystemMetricsProbe.pas) | **Sonda que monitora em tempo real métricas de hardware e processo: percentual de uso de CPU, memória RAM alocada pelo executável, contagem de threads ativas e descritores de arquivo/handles do SO.** | 
| **47** | Pool de Conexões | `TLazDatabaseConnectionPool` / `TDlpDatabaseConnectionPool` | [`LazDatabaseConnectionPool.pas`](Livro1_Lazarus_LCL/code/units/LazDatabaseConnectionPool.pas) | [`DlpDatabaseConnectionPool.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpDatabaseConnectionPool.pas) | **Gerenciador de pool de conexões com banco de dados SQL (thread-safe), mantendo conexões pré-aquecidas, reciclagem automática por inatividade e prevenção de bloqueios em acessos concorrentes multi-usuário.** | 
| **48** | Atualizações OTA | `TLazAutoUpdateManager` / `TDlpAutoUpdateManager` | [`LazAutoUpdateManager.pas`](Livro1_Lazarus_LCL/code/units/LazAutoUpdateManager.pas) | [`DlpAutoUpdateManager.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpAutoUpdateManager.pas) | **Motor de atualização automática (OTA - Over-The-Air) que consulta repositórios remotos, realiza download do novo executável, verifica o hash SHA-256 e executa a troca segura com reinício automático da aplicação.** | 
| **49** | Micro-benchmarks | `TLazCodeBenchmarkHarness` / `TDlpCodeBenchmarkHarness` | [`LazCodeBenchmarkHarness.pas`](Livro1_Lazarus_LCL/code/units/LazCodeBenchmarkHarness.pas) | [`DlpCodeBenchmarkHarness.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpCodeBenchmarkHarness.pas) | **Harness de micro-medições com precisão de nanossegundos via instruções de CPU (RDTSC / QueryPerformanceCounter), calculando média, desvio padrão e taxa de operações por segundo de trechos de código.** | 
| **50** | CI/CD & DevOps | `LazReleasePipeline` / `DlpReleasePipeline` | [`LazReleasePipeline.pas`](Livro1_Lazarus_LCL/code/units/LazReleasePipeline.pas) | [`DlpReleasePipeline.pas`](Livro2_Delphi_VCL_FMX/code/units/DlpReleasePipeline.pas) | **Pipeline automatizado de compilação headless em lote (lazbuild e msbuild), geração de pacotes binários, numeração de versão semântica e publicação automática de releases no GitHub Actions.** | 

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

## 🖥️ Aplicativos de Demonstração Interativa (Demos em Execução)

Para experimentar imediatamente os componentes em tempo de execução sem precisar instalá-los previamente, a obra disponibiliza aplicativos completos de demonstração com interface moderna, abas temáticas e console de auditoria em tempo real:

### 1. Demonstração Lazarus (FPC / LCL):
* **Localização do Projeto:** [`Livro1_Lazarus_LCL/code/demo/LazComponentsDemo.lpi`](Livro1_Lazarus_LCL/code/demo/LazComponentsDemo.lpi) (e espelhado em [`lazarus/demo/`](lazarus/demo/)).
* **Como executar:** Abra o projeto no Lazarus IDE e pressione **F9**, ou compile via terminal:
  ```bash
  lazbuild Livro1_Lazarus_LCL/code/demo/LazComponentsDemo.lpi
  ```
* **O que a demo exibe:**
  * **Instrumentação & Dashboards:** Mostrador analógico `TLazAnalogGauge` animado a 60 FPS com Double Buffering, medidor de reservatórios `TLazIndustrialTankGauge`, gráfico vetorial `TLazVectorDonutChart`, mapa de calor térmico `TLazMatrixHeatmap` e indicador `TLazProductStockIndicator`.
  * **UI Moderna & Contêineres:** Painel sanfonado colapsável `TLazAccordionContainer`, barra de abas tipadas com badges `TLazCustomTabBar`, painel High-DPI `TLazHighDpiThemedPanel` e barra de ações `TLazCRUDOperationsBar`.
  * **Segurança & Criptografia:** Cofre em memória `TLazCryptoVaultStorage`, emissor e validador de tokens `TLazJwtSecurityManager`, compactador `TLazBinaryBlobContainer` e validador de chave NF-e `TLazFiscalXmlValidator`.
  * **Diagnósticos & RTTI:** Auditoria genealógica `TLazTypeInfoInspector`, micro-benchmarks em nanossegundos `TLazCodeBenchmarkHarness` e sonda de telemetria `TLazSystemMetricsProbe`.

### 2. Demonstração Delphi (VCL & FMX):
* **Localização do Projeto:** [`Livro2_Delphi_VCL_FMX/code/demo/DlpComponentsDemo.dproj`](Livro2_Delphi_VCL_FMX/code/demo/DlpComponentsDemo.dproj) (e espelhado em [`delphi/demo/`](delphi/demo/)).
* **Como executar:** Abra o projeto no Delphi 12 Athens e pressione **F9**, ou compile via MSBuild:
  ```bash
  msbuild Livro2_Delphi_VCL_FMX/code/demo/DlpComponentsDemo.dproj /p:Configuration=Release
  ```

---

## 📂 50 Projetos Independentes de Exemplo (Aprenda Componente por Componente)

Para facilitar o estudo isolado, depuração e experimentação individual de cada recurso sem sobrecarga de um projeto monolítico, a obra conta com **50 pastas de projetos independentes** para cada ambiente (Lazarus e Delphi):

* **Lazarus / LCL:** Disponíveis em [`Livro1_Lazarus_LCL/code/examples/`](Livro1_Lazarus_LCL/code/examples/) (e espelhado em [`lazarus/examples/`](lazarus/examples/)).
* **Delphi / VCL-FMX:** Disponíveis em [`Livro2_Delphi_VCL_FMX/code/examples/`](Livro2_Delphi_VCL_FMX/code/examples/) (e espelhado em [`delphi/examples/`](delphi/examples/)).

Cada subpasta (do `01` ao `50`) contém:
1. **Projeto compilável independente:** Arquivo `.lpi` + `.lpr` (Lazarus) ou `.dproj` + `.dpr` (Delphi).
2. **Formulário de teste dedicado:** `FormMain.pas` e `FormMain.lfm` / `FormMain.dfm` com interface funcional focada no componente em questão.
3. **Documentação local (`README.md`):** Explicação teórica do componente, tabela de propriedades principais, eventos e instruções diretas de execução.

### Exemplo de Uso Rápido:
Para testar isoladamente o mostrador analógico (`TLazAnalogGauge`):
```bash
# Abrir no Lazarus ou compilar via linha de comando:
lazbuild lazarus/examples/09_AnalogGauge/Demo_09_LazAnalogGauge.lpi
```
Para testar o executor assíncrono multithread (`TDlpAsyncTaskRunner` no Delphi):
```bash
msbuild delphi/examples/21_AsyncTaskRunner/Demo_21_DlpAsyncTaskRunner.dproj
```

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
