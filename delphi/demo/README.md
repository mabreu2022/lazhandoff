# 🚀 Aplicativo de Demonstração Interativa dos Componentes Delphi (VCL & FMX)

Este projeto de demonstração oficial (**`DlpComponentsDemo.dproj`**) apresenta a utilização prática em tempo de execução dos **50 componentes profissionais** desenvolvidos no livro para o **Embarcadero Delphi 12 Athens+**.

## 🧭 O que a Demonstração Apresenta:

1. **Aba 1: Instrumentação & Dashboards Industriais**
   - **`TDlpAnalogGauge`**: Mostrador analógico circular animado com agulha vetorial e Double Buffering a 60 FPS.
   - **`TDlpIndustrialTankGauge`**: Medidor de nível de tanques industriais e reservatórios com simulação de fluidos.
   - **`TDlpVectorDonutChart`**: Gráfico vetorial de rosca com cálculo polar de fatias e percentuais.
   - **`TDlpMatrixHeatmap`**: Mapa de calor térmico matricial dinâmico com regeneração aleatória de pontos.
   - **`TDlpProductStockIndicator`**: Badge visual de análise de estoque crítico, normal e excesso.

2. **Aba 2: Contêineres & Interface Moderna**
   - **`TDlpAccordionContainer`**: Painel sanfonado colapsável com controles filhos embutidos via `csAcceptsControls`.
   - **`TDlpCustomTabBar`**: Barra moderna de guias baseada em coleções tipadas e badges de notificações.
   - **`TDlpHighDpiThemedPanel`**: Painel moderno com cantos arredondados adaptável a High-DPI (4K Per-Monitor v2).
   - **`TDlpCRUDOperationsBar`**: Barra de navegação e manutenção de registros (Novo, Editar, Gravar, Excluir).

3. **Aba 3: Segurança, Criptografia & Tokens**
   - **`TDlpCryptoVaultStorage`**: Cofre em memória com blindagem contra inspeção e memory dumps.
   - **`TDlpJwtSecurityManager`**: Emissão e validação criptográfica de tokens JWT HMAC-SHA256.
   - **`TDlpEncryptedDataStore`**: Armazenamento criptografado no streaming do DFM.
   - **`TDlpFiscalXmlValidator`**: Validador de chaves de acesso de DF-e de 44 dígitos com algoritmo Módulo 11.

4. **Aba 4: Diagnóstico, RTTI & Benchmarks**
   - **`TDlpTypeHierarchyInspector`**: Inspeção profunda da árvore de herança RTTI e propriedades publicadas.
   - **`TDlpCodeBenchmarkHarness`**: Medição estatística de tempo de execução com precisão de nanossegundos.
   - **`TDlpSystemMetricsProbe`**: Telemetria do processo em tempo real (RAM, CPU, Threads e Handles do SO).

5. **Console de Auditoria Inferior**:
   - `TMemo` com console em estilo terminal que recebe logs com timestamp de cada ação do usuário.

---

## 🛠️ Como Compilar e Executar no Delphi:

1. Abra o **Embarcadero Delphi 12 Athens+**.
2. Acesse o menu **File -> Open Project...** e selecione o arquivo `DlpComponentsDemo.dproj`.
3. Pressione **F9** (Run) ou compile via **MSBuild**:
```bash
msbuild DlpComponentsDemo.dproj /p:Configuration=Release /p:Platform=Win32
```
