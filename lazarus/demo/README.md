# 🚀 Aplicativo de Demonstração Interativa dos Componentes Lazarus & LCL

Este projeto de demonstração oficial (**`LazComponentsDemo.lpi`**) apresenta a utilização prática em tempo de execução dos **50 componentes profissionais** desenvolvidos no livro.

## 🧭 O que a Demonstração Apresenta:

1. **Aba 1: Instrumentação & Dashboards Industriais**
   - **`TLazAnalogGauge`**: Mostrador analógico circular (velocímetro) animado com Double Buffering suave a 60 FPS.
   - **`TLazIndustrialTankGauge`**: Medidor de nível de tanques industriais e reservatórios com alarme sonoro/visual.
   - **`TLazVectorDonutChart`**: Gráfico vetorial de rosca com fatias coloridas e cálculo trigonométrico polar.
   - **`TLazMatrixHeatmap`**: Mapa de calor térmico matricial dinâmico com botão para regenerar matriz aleatória.
   - **`TLazProductStockIndicator`**: Badge visual de análise de estoque crítico, normal e excesso.

2. **Aba 2: Contêineres & Interface Moderna**
   - **`TLazAccordionContainer`**: Painel sanfonado colapsável com controles filhos embutidos via `csAcceptsControls`.
   - **`TLazCustomTabBar`**: Barra moderna de guias com coleções tipadas e badges de contagem de notificações.
   - **`TLazHighDpiThemedPanel`**: Painel moderno com cantos arredondados adaptável a High-DPI (4K).
   - **`TLazCRUDOperationsBar`**: Barra de navegação e manutenção de registros (Novo, Editar, Gravar, Excluir).

3. **Aba 3: Segurança, Criptografia & Tokens**
   - **`TLazCryptoVaultStorage`**: Cofre em memória com blindagem contra inspeção e memory dumps.
   - **`TLazJwtSecurityManager`**: Emissão e validação criptográfica de tokens JWT HMAC-SHA256.
   - **`TLazBinaryBlobContainer`**: Compressão de buffers binários com ZLib diretamente no streaming LFM.
   - **`TLazFiscalXmlValidator`**: Validador de chaves de acesso de DF-e de 44 dígitos com algoritmo Módulo 11.

4. **Aba 4: Diagnóstico, RTTI & Benchmarks**
   - **`TLazTypeInfoInspector`**: Inspeção profunda da árvore de herança RTTI e propriedades publicadas.
   - **`TLazCodeBenchmarkHarness`**: Medição estatística de tempo de execução com precisão de nanossegundos.
   - **`TLazSystemMetricsProbe`**: Telemetria do processo em tempo real (RAM, CPU, Threads e Handles do SO).

5. **Console de Auditoria Inferior**:
   - `TMemo` com console em estilo terminal que recebe logs com timestamp de cada ação do usuário.

---

## 🛠️ Como Compilar e Executar:

### Opção 1: Pela Interface do Lazarus IDE
1. Abra o Lazarus.
2. Acesse o menu **Projeto -> Abrir Projeto...** e selecione o arquivo `LazComponentsDemo.lpi`.
3. Pressione **F9** (Executar).

### Opção 2: Pela Linha de Comando (lazbuild)
```bash
lazbuild --build-all LazComponentsDemo.lpi
./LazComponentsDemo
```
