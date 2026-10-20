# MÓDULO 43: Parser de Respostas Estruturadas JSON (TLazAiStructuredExtractor)

Modelos de linguagem generativos (LLMs) são probabilísticos por definição. Mesmo quando instruídos explicitamente através de comandos como *"Responda apenas com JSON válido"*, é comum que o modelo envolva o payload em blocos de formatação Markdown decorativos (` ```json ... ``` `), adicione textos introdutórios conversacionais (*"Aqui está o JSON solicitado:"*) ou gere pequenas imperfeições sintáticas, como vírgulas sobrando antes do fechamento de chaves (`{"id": 10, }`).

Essas anomalias quebram parsers JSON estritos convencionais. Neste módulo, construímos o **`TLazAiStructuredExtractor`**, um componente para Free Pascal e Lazarus LCL projetado especificamente para sanitizar saídas de IA, corrigir sintaxes imperfeitas e realizar a hidratação determinística de records e classes Pascal com tipagem estrita.

---

## 1. Pipeline de Higienização de Saídas de IA

```mermaid
graph TD
    A[Saída Bruta do LLM com Markdown e Texto] --> B[CleanMarkdownFences]
    B --> C[Isola substring entre primeiro '{' e último '}']
    C --> D[RepairJsonSyntax]
    D --> E[Substitui Aspas Simples por Duplas]
    E --> F[Elimina Trailing Commas ', }' e ', ]']
    F --> G[JSON Rigorosamente Válido]
    G --> H[ParseCustomerIntent / Hydration]
    H --> I[Record Pascal Tipado: Intent, Confidence, Sentiment]
```

---

## 2. Tipagem Direta em Records Pascal

A integração com o ecossistema corporativo não deve forçar o desenvolvedor a manipular chaves genéricas de dicionários em tempo de execução. O componente mapeia a estrutura validada para um `record` fortemente tipado:

```pascal
type
  TCustomerIntentRecord = record
    Intent: string;
    Confidence: Double;
    Sentiment: string;
    NeedsHumanAgent: Boolean;
    Summary: string;
    ExtractedEntities: TStringList;
  end;
```

A conversão numérica garante a leitura de casas decimais independentemente do separador regional do sistema operacional (PT-BR `,` vs US `.`).

---

## 3. Código-Fonte e Registro LCL

O código integral encontra-se em [`LazAiStructuredExtractor.pas`](file:///d:/Projetos%20AntiGravity/Livros%20componentes/Livro1_Lazarus_LCL/code/units/LazAiStructuredExtractor.pas).

O componente é registrado na paleta `'Lazarus Engenharia Avancada'`, oferecendo uma ponte sólida entre o processamento probabilístico da IA e o rigor tipado do Object Pascal.
