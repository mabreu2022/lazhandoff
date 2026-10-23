const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');

// Carrega os 50 componentes a partir do script gerador
const componentsScriptPath = path.join(rootDir, '..', '..', '..', '..', 'Users', 'Denize Abreu', '.gemini', 'antigravity-ide', 'brain', 'cbaf1476-ae33-42c5-90cb-784dc50e8691', 'scratch', 'generate_master_tables.js');
let componentsSrc = '';
if (fs.existsSync(componentsScriptPath)) {
  componentsSrc = fs.readFileSync(componentsScriptPath, 'utf8');
} else {
  // Fallback se não encontrar o caminho absoluto
  const altPath = 'C:\\Users\\Denize Abreu\\.gemini\\antigravity-ide\\brain\\cbaf1476-ae33-42c5-90cb-784dc50e8691\\scratch\\generate_master_tables.js';
  componentsSrc = fs.readFileSync(altPath, 'utf8');
}

const match = componentsSrc.match(/const COMPONENTS = (\[[\s\S]*?\]);/);
if (!match) {
  console.error("Não foi possível carregar a lista de componentes!");
  process.exit(1);
}

const COMPONENTS = eval(match[1]);
console.log(`Carregados ${COMPONENTS.length} componentes com sucesso!`);

// 1. Gera o documento Markdown
let md = `---
title: "Catálogo Técnico e Resumo dos 50 Componentes Object Pascal"
subtitle: "Guia Visual e Arquitetural de Referência Rápida para Lazarus IDE & LCL e Delphi 12 Athens+ (VCL/FMX)"
author: "Engenharia de Software Especializada & Arquitetura RAD"
date: "2026"
lang: "pt-BR"
---

# APRESENTAÇÃO DO CATÁLOGO TÉCNICO

Este documento consolida a **ficha técnica, finalidade arquitetural e catálogo analítico dos 50 componentes profissionais** desenvolvidos na obra *Engenharia Avançada de Componentes Object Pascal*.

O objetivo deste guia de referência rápida é fornecer a arquitetos de software, consultores e desenvolvedores uma visão panorâmica e imediata sobre o que cada componente faz, quais problemas de engenharia ele resolve, em quais cenários reais aplicá-lo e onde localizar tanto sua unidade fonte quanto seu **projeto de exemplo isolado e compilável**.

> **💡 Projetos Independentes para Aprendizado Prático:**
> Cada um dos 50 componentes possui um projeto próprio e totalmente independente localizado nas pastas:
> * **Lazarus LCL:** \`lazarus/examples/XX_NomeComponente/\` (ou \`Livro1_Lazarus_LCL/code/examples/\`)
> * **Delphi VCL/FMX:** \`delphi/examples/XX_NomeComponente/\` (ou \`Livro2_Delphi_VCL_FMX/code/examples/\`)
> Cada pasta contém o arquivo de projeto (\`.lpi\` / \`.dproj\`), formulário funcional (\`FormMain.pas\`) e documentação local (\`README.md\`).

---

# TABELA MESTRA DOS 50 COMPONENTES: FINALIDADE E USO PRÁTICO

A tabela a seguir apresenta os 50 módulos técnicos da obra em ordem numérica, mapeando as classes para Lazarus (FPC/LCL) e Delphi 12 (VCL/FMX), suas respectivas unidades de código-fonte e o detalhamento técnico de suas finalidades e aplicações reais:

| # | Módulo / Domínio | Lazarus (FPC/LCL) | Delphi (VCL/FMX) | Para que serve (Finalidade Principal e Aplicação Prática no Mundo Real) |
| :-: | :--- | :--- | :--- | :--- |
`;

for (const c of COMPONENTS) {
  md += `| **${c.mod}** | **${c.palette}** | \`${c.lazClass}\`<br>↳ \`${c.lazUnit}\` | \`${c.dlpClass}\`<br>↳ \`${c.dlpUnit}\` | **${c.purpose}**<br><br>*(Cenário Real:* ${c.sample}*)* |\n`;
}

md += `

---

# VISÃO GERAL DOS COMPONENTES AGRUPADOS POR DOMÍNIO ARQUITETURAL

Para facilitar a consulta e implementação arquitetural em seus projetos, os 50 componentes encontram-se estruturados em 7 grandes domínios de engenharia:

## 1. 🛡️ Diagnósticos, RTTI & Extensibilidade de Design-Time (Módulos 01 a 08)
* **TLazTypeInfoInspector / TDlpTypeHierarchyInspector (01):** Auditoria profunda de metadados de classe, listagem de métodos e propriedades published para geração de documentação ou serializadores automáticos.
* **TLazSafeLinkedPanel / TDlpSafeLinkedContainer (02):** Prevenção de Access Violation através do gerenciamento rigoroso de ponteiros fracos via \`FreeNotification\` e \`opRemove\`.
* **TLazBinaryBlobContainer / TDlpEncryptedDataStore (03):** Serialização e compressão ZLib de arquivos e recursos binários no streaming nativo LFM/DFM via \`DefineProperties\`.
* **LazAsyncEventHook / TDlpWindowsMessageInterceptor (04):** Subclassing de baixo nível de janelas de SO (\`WndProc\`) para captura assíncrona de foco, inatividade e hotkeys.
* **LazPackageRegister / DlpPackageRegister (05):** Separação limpa de pacotes Runtime (.lpk/.dpk) e Design-time (.lpk/.dpk) com ícones profissionais para distribuição.
* **TLazJsonConfigPropEditor / TDlpGradientPropEditor (06):** Extensão do Object Inspector da IDE com diálogos modais interativos e listas suspensas customizadas.
* **TLazCardViewEditor / TDlpDashboardCardEditor (07):** Injeção de verbos de menu de contexto (clique direito no Form Designer) e tratamento de duplo-clique.
* **TLazCleanArchFormWizard / TDlpCleanArchProjectWizard (08):** Assistente automatizado de geração de projetos segundo os princípios da Clean Architecture.

## 2. 📊 Dashboards, Instrumentação & UI Moderna (Módulos 09 a 12, 20, 26 a 29)
* **TLazAnalogGauge / TDlpAnalogGauge (09):** Mostrador analógico circular vetorial leve a 60 FPS com Double Buffering, agulha trigonométrica e zonas de alarme.
* **TLazAccordionContainer / TDlpAccordionContainer (10):** Painel sanfonado colapsável janelado com suporte nativo a hospedar filhos no designer e navegação por teclado.
* **TLazCustomTabBar / TDlpCustomTabBar (11):** Barra de abas tipadas com coleções dinâmicas, badges numéricos de alerta e botão individual de fechamento.
* **TLazHighDpiThemedPanel / TDlpHighDpiThemedPanel (12):** Painel responsivo adaptável a resoluções 4K High-DPI (96 a 288+ DPI) com bordas e cantos arredondados.
* **TLazProductStockIndicator / TDlpProductStockIndicator (20):** Card comercial com renderização gráfica de estoque, ponto de ressuprimento e cálculo de margem/markup.
* **TLazRealtimeChartEngine / TDlpRealtimeChartEngine (26):** Motor gráfico para séries temporais contínuas de até 100.000 pontos em tempo real com auto-escala.
* **TLazIndustrialTankGauge / TDlpIndustrialTankGauge (27):** Medidor vertical de nível de fluidos e silos com gradiente térmico e marcadores volumétricos.
* **TLazVectorDonutChart / TDlpVectorDonutChart (28):** Gráfico vetorial de rosca/pizza com animação de varredura, fatias coloridas e cálculo percentual.
* **TLazMatrixHeatmap / TDlpMatrixHeatmap (29):** Mapa de calor bidimensional para análise de dados multidimensionais com interpolação de paletas fria/quente.

## 3. 💾 Arquitetura DB-Aware & Manipulação de Dados (Módulos 13 a 19, 47)
* **TLazCustomDBConnector / TDlpCustomDBConnector (13):** Encapsulamento da ponte reativa \`TDataLink\` para sincronização de controles com \`TDataSource\`.
* **TLazDBBasicControls / TDlpDBBasicControls (14):** Conjunto básico de controles DB-Aware (Label, Edit, CheckBox) com binding bidirecional com DataSet.
* **TLazDBLookupTagBox / TDlpDBLookupTagBox (15):** Seleção múltipla visual através de chips/tags pesquisáveis a partir de tabelas de consulta.
* **TLazDataConnectionMonitor / TDlpDataConnectionMonitor (16):** Telemetria em tempo real de execução de queries SQL com alerta para slow queries.
* **TLazFieldSchemaInspector / TDlpFieldSchemaInspector (17):** Dicionário de dados interativo com drag-and-drop de campos para a tela do formulário.
* **TLazAutoFormBuilder / TDlpAutoFormBuilder (18):** Motor de geração algorítmica de telas e cadastros completos a partir de metadados RTTI.
* **TLazCRUDOperationsBar / TDlpCRUDOperationsBar (19):** Barra de ferramentas para manutenção de registros (Novo, Editar, Gravar, Excluir, Navegar) sincronizada com o estado do DataSet.
* **TLazDatabaseConnectionPool / TDlpDatabaseConnectionPool (47):** Pool gerenciado de conexões de banco de dados com reciclagem ativa e proteção multithread.

## 4. ⚡ Concorrência, Hardware & Comunicação Industrial (Módulos 21 a 23, 38 a 41, 45, 46)
* **TLazAsyncTaskRunner / TDlpAsyncTaskRunner (21):** Processamento em worker threads de segundo plano com cancelamento limpo e sincronização segura com a UI.
* **TLazRestClientBridge / TDlpRestClientBridge (22):** Cliente HTTP assíncrono para consumo de endpoints RESTful com serialização JSON e autenticação.
* **TLazSerialDeviceConnector / TDlpSerialDeviceConnector (23):** Comunicação bidirecional com portas seriais (RS-232/RS-485/USB Virtual COM) com buffer circular.
* **TLazMqttClientBridge / TDlpMqttClientBridge (38):** Ponte de mensageria IoT via protocolo MQTT (Publish/Subscribe) para automação e sensores.
* **TLazEmbeddedWebhookServer / TDlpEmbeddedWebhookServer (39):** Servidor HTTP embutido para recepção de webhooks de pagamento (Pix, Stripe) e integrações externas.
* **TLazWebSocketLiveClient / TDlpWebSocketLiveClient (40):** Cliente WebSocket duplex de baixa latência para dashboards operacionais em tempo real.
* **TLazPushNotificationHub / TDlpPushNotificationHub (41):** Central de despacho de notificações push (FCM, Apple APNs) com tratamento de fila de envio.
* **TLazSystemDaemonController / TDlpSystemDaemonController (45):** Gerenciador de serviços de sistema em segundo plano (Windows Services e Linux Systemd daemons).
* **TLazSystemMetricsProbe / TDlpSystemMetricsProbe (46):** Sonda de telemetria de hardware (consumo de CPU, memória RAM, taxa de I/O de disco e rede).

## 5. 🔒 Criptografia, Segurança & Documentos Fiscais (Módulos 32 a 37)
* **TLazFiscalXmlValidator / TDlpFiscalXmlValidator (32):** Validador oficial de documentos fiscais eletrônicos (NF-e, NFC-e) com validação de schemas XSD e cálculo de dígito verificador.
* **TLazEncryptedZipArchive / TDlpEncryptedZipArchive (33):** Compactador e descompactador ZIP com cifra criptográfica AES-256 e proteção por senha em memória.
* **TLazJwtSecurityManager / TDlpJwtSecurityManager (34):** Gerador e validador de tokens JWT (JSON Web Tokens) com assinatura HMAC-SHA256 e controle estrito de expiração.
* **TLazCryptoVaultStorage / TDlpCryptoVaultStorage (35):** Cofre seguro em memória protegida com criptografia simétrica para chaves de API, senhas e certificados.
* **TLazSecurityRoleManager / TDlpSecurityRoleManager (36):** Sistema de controle de acesso baseado em papéis (RBAC - Role-Based Access Control) para menus e ações.
* **TLazIntegrityWatchdog / TDlpIntegrityWatchdog (37):** Sentinela anti-tampering que monitora hashes SHA-256 de binários e bibliotecas para prevenir injeções de código.

## 6. 🧠 Inteligência Artificial, Vetores & Automação (Módulos 42 a 44, 48)
* **TLazAiPromptDispatcher / TDlpAiPromptDispatcher (42):** Despachante resiliente de requisições para LLMs (OpenAI, Anthropic Claude, Google Gemini) com streaming e retry exponencial.
* **TLazAiStructuredExtractor / TDlpAiStructuredExtractor (43):** Extrator de dados que força respostas de IA no formato estrito de JSON Schemas mapeados para registros Pascal.
* **TLazVectorEmbeddingStore / TDlpVectorEmbeddingStore (44):** Banco de dados vetorial em memória para busca semântica por similaridade de cosseno de embeddings.
* **TLazAutoUpdateManager / TDlpAutoUpdateManager (48):** Gerenciador de auto-atualização de software com download assíncrono, verificação de integridade e reinício transparente.

## 7. 🚀 Qualidade, Testes, Benchmarks & CI/CD (Módulos 24, 25, 30, 31, 49, 50)
* **LazComponentTests / DlpComponentTests (24):** Suíte de testes automatizados para validação do ciclo de vida dos componentes e prevenção de memory leaks.
* **LazPackageRegister / DlpPackageRegister (25):** Estrutura de empacotamento oficial para submissão no Online Package Manager (OPM) e GetIt.
* **TLazFastPdfReport / TDlpFastPdfReport (30):** Gerador nativo e ultrarrápido de relatórios em PDF sem dependência de DLLs externas, com cabeçalhos e paginação.
* **TLazDataExportPipeline / TDlpDataExportPipeline (31):** Pipeline de exportação de dados em lote para múltiplos formatos (CSV, JSON, XML e XLSX).
* **TLazCodeBenchmarkHarness / TDlpCodeBenchmarkHarness (49):** Harness de micro-benchmarks em nanossegundos com medição estatística (média, desvio padrão, min/max).
* **LazReleasePipeline / DlpReleasePipeline (50):** Automação do pipeline de compilação em lote (headless lazbuild/msbuild) e publicação automática no GitHub Actions.

---

# GUIA RÁPIDO DE INSTALAÇÃO E EXECUÇÃO DOS 50 PROJETOS DE EXEMPLO

Todos os exemplos da obra estão disponíveis no repositório com código-fonte integral:

### 1. Como Abrir e Executar um Exemplo no Lazarus IDE:
1. Inicie o Lazarus 3.x+.
2. Acesse o menu **Project** $\rightarrow$ **Open Project...**
3. Navegue até a pasta do componente desejado dentro de:
   \`lazarus/examples/XX_NomeComponente/Demo_XX_NomeComponente.lpi\`
4. Pressione **F9** para compilar e executar o projeto imediatamente.
5. *Opcional via linha de comando:*
   \`\`\`bash
   lazbuild lazarus/examples/09_AnalogGauge/Demo_09_LazAnalogGauge.lpi
   \`\`\`

### 2. Como Abrir e Executar um Exemplo no Delphi 12:
1. Inicie o Embarcadero Delphi 12 Athens+.
2. Acesse o menu **File** $\rightarrow$ **Open Project...**
3. Navegue até a pasta do componente desejado dentro de:
   \`delphi/examples/XX_NomeComponente/Demo_XX_NomeComponente.dproj\`
4. Pressione **F9** para compilar e executar.
5. *Opcional via linha de comando (MSBuild):*
   \`\`\`bash
   msbuild delphi/examples/21_AsyncTaskRunner/Demo_21_DlpAsyncTaskRunner.dproj
   \`\`\`

---

*Catálogo Técnico e Guia de Referência dos 50 Componentes Object Pascal &bull; Edição 2026*
`;

const mdPath = path.join(rootDir, 'Resumo_50_Componentes_Lazarus_Delphi.md');
fs.writeFileSync(mdPath, md, 'utf8');
console.log(`Markdown gerado em: ${mdPath}`);

// 2. Compila Markdown para HTML via Pandoc
const htmlPath = path.join(rootDir, 'Resumo_50_Componentes_Lazarus_Delphi.html');
const cssRel = 'scripts/summary_theme.css';
console.log("Executando Pandoc...");
execSync(`pandoc "${mdPath}" -s -N -c "${cssRel}" -o "${htmlPath}"`, { cwd: rootDir, stdio: 'inherit' });

// 3. Injeta a capa editorial personalizada Landscape
let htmlContent = fs.readFileSync(htmlPath, 'utf8');

const coverHtml = `
<div class="editorial-cover-landscape">
  <div>
    <div class="cover-badge-top">GUIA TÉCNICO RÁPIDO &bull; CATÁLOGO DE REFERÊNCIA EXECUTIVA</div>
    <h1 class="cover-title-main">Catálogo Técnico &amp; Resumo dos 50 Componentes</h1>
    <div class="cover-subtitle-main">Guia de Arquitetura, Finalidade e Aplicação Prática dos Componentes Profissionais desenvolvidos para Free Pascal / Lazarus IDE (LCL) e Embarcadero Delphi 12 Athens+ (VCL &amp; FMX).</div>
    <div class="cover-divider-bar"></div>
    <div class="cover-chips-container">
      <span class="chip-item">50 Módulos de Engenharia</span>
      <span class="chip-item">Free Pascal 3.2+</span>
      <span class="chip-item">Lazarus 3.x+ (LCL)</span>
      <span class="chip-item">Delphi 12 Athens+ (VCL &amp; FMX)</span>
      <span class="chip-item">50 Demos Independentes</span>
      <span class="chip-item">Tabela Comparativa Completa</span>
      <span class="chip-item">Licença Open Source MIT</span>
    </div>
  </div>
  <div class="cover-footer-row">
    <div>
      <div class="author-title">Engenharia de Software Especializada &amp; Arquitetura RAD</div>
      <div class="institution-title">Coleção de Engenharia Avançada de Componentes Object Pascal</div>
    </div>
    <div class="meta-title">
      <div><strong>Edição Oficial de Produção</strong></div>
      <div>Publicação: 2026 &bull; Formato A4 Paisagem</div>
    </div>
  </div>
</div>
`;

htmlContent = htmlContent.replace(/<body\b[^>]*>/, `<body>\n${coverHtml}`);

// Otimiza colgroup para dar 50% de espaço para a coluna de descrição
htmlContent = htmlContent.replace(/<colgroup>[\s\S]*?<\/colgroup>/g, `
<colgroup>
<col style="width: 4% !important;" />
<col style="width: 14% !important;" />
<col style="width: 16% !important;" />
<col style="width: 16% !important;" />
<col style="width: 50% !important;" />
</colgroup>`);

fs.writeFileSync(htmlPath, htmlContent, 'utf8');
console.log(`HTML estilizado salvo em: ${htmlPath}`);

// 4. Renderiza PDF via Edge Headless
const edgePath = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const pdfPath = path.join(rootDir, 'Resumo_50_Componentes_Lazarus_Delphi.pdf');

console.log("Renderizando PDF via Edge Headless...");
execSync(`"${edgePath}" --headless --disable-gpu --run-all-compositor-stages-before-draw --no-pdf-header-footer --print-to-pdf="${pdfPath}" "${htmlPath}"`, { stdio: 'inherit' });

if (fs.existsSync(pdfPath)) {
  const sizeMB = (fs.statSync(pdfPath).size / (1024 * 1024)).toFixed(2);
  console.log(`\n==========================================================`);
  console.log(`[SUCESSO] PDF do Resumo gerado com sucesso!`);
  console.log(`Arquivo: ${pdfPath} (${sizeMB} MB)`);
  console.log(`==========================================================\n`);
} else {
  console.error("Falha ao gerar PDF.");
  process.exit(1);
}
