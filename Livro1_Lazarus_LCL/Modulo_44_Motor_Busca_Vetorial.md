# MÓDULO 44: Motor de Busca Vetorial e Embeddings (TLazVectorEmbeddingStore)

A busca textual clássica baseada em palavras-chave (`LIKE '%termo%'` ou índices Full-Text Search como Lucene) falha quando o usuário pesquisa usando sinônimos, descrições conceituais ou comete variações gramaticais (por exemplo: buscar *"computador portátil potente"* esperando encontrar *"Notebook Dell i7 32GB"*). A **Busca Semântica Vetorial** converte frases em vetores numéricos multidimensionais (*Embeddings*) onde a proximidade geométrica reflete a afinidade semântica dos termos.

Neste módulo, concebemos e construímos o **`TLazVectorEmbeddingStore`**, um banco de dados vetorial de alta densidade em memória (*In-Memory Vector Database*) para Free Pascal e Lazarus LCL, implementando cálculo de **Similaridade por Cosseno**, normalização de magnitude e algoritmo de busca **Top-K Nearest Neighbors** para arquiteturas de RAG (Retrieval-Augmented Generation).

---

## 1. Fundamentos Matemáticos: Espaço Vetorial e Similaridade por Cosseno

Cada documento ou registro é projetado em um hiper-espaço de $N$ dimensões (tipicamente $N = 384$ para o modelo `all-MiniLM-L6-v2` ou $N = 768$ para `nomic-embed-text`).

A proximidade angular entre o vetor da consulta ($\vec{Q}$) e o vetor do documento armazenado ($\vec{D}$) é dada pelo cosseno do ângulo $\theta$ formado entre eles:

$$
\text{Similaridade}(\vec{Q}, \vec{D}) = \cos(\theta) = \frac{\vec{Q} \cdot \vec{D}}{\|\vec{Q}\| \cdot \|\vec{D}\|} = \frac{\sum_{i=1}^N Q_i D_i}{\sqrt{\sum_{i=1}^N Q_i^2} \cdot \sqrt{\sum_{i=1}^N D_i^2}}
$$

```mermaid
graph TD
    subgraph 1. Indexação em Tempo de Carga
        A[Texto do Documento] --> B[Gera Embedding: array of Single]
        B --> C[TLazVectorEmbeddingStore.AddDocument]
        C --> D[Pré-computa Magnitude Euclidiana ||V||]
        D --> E[Armazena em Memória RAM]
    end

    subgraph 2. Busca Semântica Top-K
        F[Prompt / Pergunta do Usuário] --> G[Gera Query Vector]
        G --> H[Calcula Magnitude ||Q||]
        H --> I[Varre Todos os Documentos: Dot Product / ||Q|| * ||D||]
        I --> J[Gera Vetor de Similaridades 0.0 a 1.0]
        J --> K[Algoritmo de Seleção Parcial Top-K]
        K --> L[Retorna TSimilarityResultArray Ordenado]
    end
```

---

## 2. Otimização de Performance e Pré-Cálculo de Magnitude

Calcular as raízes quadradas das somas dos quadrados ($\sqrt{\sum D_i^2}$) para milhares de registros a cada busca consumiria tempo de CPU precioso. O componente calcula e armazena o módulo do vetor ($\|\vec{D}\|$) uma única vez no momento da chamada a `AddDocument`:

```pascal
Doc.Magnitude := ComputeMagnitude(Doc.Vector);
```

Durante a busca `SearchTopK`, a operação interna no laço crítico reduz-se exclusivamente a acumulações de multiplicações de ponto flutuante (*Fused Multiply-Add*), alcançando taxas de avaliação superiores a 500.000 comparações vetoriais por segundo em processadores comuns x86_64.

---

## 3. Código-Fonte e Registro LCL

O código integral encontra-se em [`LazVectorEmbeddingStore.pas`](file:///d:/Projetos%20AntiGravity/Livros%20componentes/Livro1_Lazarus_LCL/code/units/LazVectorEmbeddingStore.pas).

O componente é registrado na paleta `'Lazarus Engenharia Avancada'`, oferecendo suporte a persistência binária rápida (`SaveToStream` / `LoadFromStream`) para carregamento instantâneo no arranque do software.
