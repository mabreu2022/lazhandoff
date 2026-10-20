# MÓDULO 43: Parser de Respostas Estruturadas JSON (TDlpAiStructuredExtractor)

No desenvolvimento de sistemas corporativos em Delphi 12 Athens+ integrados a modelos generativos de IA, o maior obstáculo prático para a automação de rotinas (como classificação automática de títulos a pagar, roteamento de chamados de suporte e validação de documentos fiscais digitalizados via OCR) é a instabilidade sintática do JSON retornado pelos LLMs.

Neste módulo, implementamos o **`TDlpAiStructuredExtractor`**, um extrator resiliente que higieniza saídas brutas de IA, remove marcações Markdown, corrige imperfeições sintáticas e hidrata records fortemente tipados sem falhas de runtime.

---

## 1. Topologia de Limpeza e Validação

```mermaid
graph TD
    subgraph Entrada Não-Estruturada
        A[Resposta do LLM: Aqui está o resultado ```json ...] --> B[CleanMarkdownFences]
    end

    subgraph Sanitização e Reparo Sintático
        B --> C[Localiza primeiro '{' e último '}']
        C --> D[RepairJsonSyntax: Remove Trailing Commas]
        D --> E[Substitui Delimitadores Inválidos]
    end

    subgraph Hidratação Tipada Delphi
        E --> F[ExtractField: String / Bool / Float com InvariantCulture]
        F --> G[TDlpCustomerIntentRecord Preenchido]
        G --> H[Integração Segura com Regras de Negócio e FireDAC]
    end
```

---

## 2. Robustez na Conversão de Ponto Flutuante

Divergências regionais de formatação entre o ponto decimal emitido pelo modelo generativo e a vírgula utilizada em sistemas operacionais configurados em Português do Brasil são neutralizadas pela utilização sistemática de `TFormatSettings.Invariant`:

```pascal
function TDlpAiStructuredExtractor.ExtractFloatField(const Json, FieldName: string): Double;
var
  V: string;
begin
  V := Trim(ExtractField(Json, FieldName));
  V := StringReplace(V, ',', '.', [rfReplaceAll]);
  Result := StrToFloatDef(V, 0.0, TFormatSettings.Invariant);
end;
```

---

## 3. Código-Fonte e Registro na Paleta

O código integral encontra-se em [`DlpAiStructuredExtractor.pas`](file:///d:/Projetos%20AntiGravity/Livros%20componentes/Livro2_Delphi_VCL_FMX/code/units/DlpAiStructuredExtractor.pas).

O componente é registrado na paleta `'Delphi Engenharia Avancada'`, permitindo transformar textos gerados por inteligência artificial em estruturas tipadas seguras.
