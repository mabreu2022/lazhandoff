# MÓDULO 31: Pipeline de Exportação em Segundo Plano (TDlpDataExportPipeline)

Em aplicações corporativas construídas sobre a suíte FireDAC ou instâncias heterogêneas de `TDataSet` no Delphi 12 Athens+, a conversão e o despejo de grandes massas de dados para formatos interoperáveis (CSV, JSONL, planilhas) pode consumir dezenas de segundos ou minutos. A retenção da thread de interface durante esse processamento acarreta degradação severa da experiência do operador.

Neste módulo, implementamos o **`TDlpDataExportPipeline`**, projetado para desacoplar integralmente a exportação de dados através de `TThread` autônoma, garantindo segurança transacional, desativação de controles visuais com `DisableControls` e feedback de progresso sem concorrência.

---

## 1. Topologia de Concorrência e Tratamento Transacional

```mermaid
graph TD
    subgraph UI Thread - VCL/FMX
        A[Invocação: TDlpDataExportPipeline.StartExport] --> B[Validação de Estado e Propriedades]
        B --> C[Disparo de TDlpDataExportWorkerThread]
        H[Disparo de OnProgress na GUI] --> I[Atualização de TProgressBar]
        J[Disparo de OnComplete] --> K[Habilitação de Botões e Alerta de Sucesso]
    end

    subgraph Worker Thread em Segundo Plano
        C --> D[DataSet.DisableControls]
        D --> E[Abre TFileStream em Disco]
        E --> F[Laço de Leitura EOF com Serialização de Linhas]
        F -->|A cada 100 linhas| G[Synchronize: Notifica Main Thread]
        G --> H
        F -->|EOF ou Terminated| L[Fecha TFileStream]
        L --> M[DataSet.EnableControls]
        M --> N[Synchronize: Finalização]
        N --> J
    end
```

### Isolamento de Falhas e Cancelamento Graceful

A thread respeita a propriedade `Terminated` em cada iteração do laço. Se o usuário clicar no botão Cancelar, o pipeline interrompe imediatamente a gravação e limpa os recursos sem corromper o cursor do banco de dados:

```pascal
procedure TDlpDataExportPipeline.CancelExport;
begin
  if FIsBusy and Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FreeAndNil(FWorkerThread);
    FIsBusy := False;
  end;
end;
```

---

## 2. Formatos Suportados: CSV, JSONL e Planilhas XML

1. **CSV (RFC 4180):** Separação por ponto-e-vírgula (`;`) ou vírgula, com sanitização de quebras de linha e escape de aspas duplas.
2. **JSONL (JSON Lines):** O padrão universal para pipelines de Machine Learning, pipelines de embeddings e exportações para Elasticsearch / MongoDB.
3. **XML Spreadsheet:** Documentos em conformidade com o esquema Microsoft Office 2003, permitindo abertura nativa no Excel com formatação sem necessitar de instalação de DLLs COM/ActiveX.

---

## 3. Código-Fonte e Registro na Paleta

O código integral encontra-se em [`DlpDataExportPipeline.pas`](file:///d:/Projetos%20AntiGravity/Livros%20componentes/Livro2_Delphi_VCL_FMX/code/units/DlpDataExportPipeline.pas).

O componente é registrado na paleta `'Delphi Engenharia Avancada'`, pronto para uso em projetos VCL e FireMonkey.
