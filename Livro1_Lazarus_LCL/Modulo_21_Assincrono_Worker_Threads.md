# MÓDULO 21: Componentes de Execução Assíncrona e Worker Threads (TLazAsyncTaskRunner)

O congelamento da interface gráfica (*UI Freeze*) durante operações computacionalmente intensivas (processamento de relatórios pesados, importação de planilhas gigantes, chamadas a serviços remotos ou consultas SQL demoradas) é um dos fatores mais nocivos para a experiência do usuário. No entanto, introduzir threads de trabalho (*Worker Threads*) na **LCL (Lazarus Component Library)** sem uma arquitetura sólida introduz riscos graves de *Race Conditions*, corrupção de memória e *Deadlocks*.

Neste módulo, concebemos e construímos o componente **`TLazAsyncTaskRunner`**, fornecendo um framework não-visual de execução em segundo plano com cancelamento cooperativo e despacho assíncrono não-bloqueante via **`Application.QueueAsyncCall`**.

---

## 1. Concorrência Segura na LCL: O Perigo de Acessar a UI Fora da Main Thread

No Object Pascal e na LCL, os componentes visuais são estritamente monoposto (*Single-Threaded Affinity*). O acesso a qualquer propriedade de um `TControl`, `TCanvas` ou `TDataSet` deve ocorrer exclusivamente no contexto da **Thread Principal (UI Thread)**:

```
[ Worker Thread (Segundo Plano) ] ---- X NUNCA ACESSE DIRETAMENTE X ----> [ TLabel / TProgressBar ]
                 |
                 +-----> Enfileira com Application.QueueAsyncCall -----> [ LCL Event Loop ]
                                                                                |
                                                                                v
                                                                   [ Atualiza UI com Segurança ]
```

### 1.1 `TThread.Synchronize` vs. `Application.QueueAsyncCall`
Embora a RTL forneça o método `Synchronize`, ele força a thread de segundo plano a suspender sua execução até que a thread principal processe a requisição. Se a tela tentar destruir a thread ou invocar `WaitFor`, ocorre um **Deadlock fatal**. 

A LCL resolve essa vulnerabilidade através de `Application.QueueAsyncCall`: o worker thread empacota os dados de progresso e continua executando sem interrupção, enquanto o loop de mensagens da aplicação desempacota os dados quando estiver ocioso.

---

## 2. Anatomia do `TLazAsyncTaskRunner`

O componente organiza a execução assíncrona desacoplando a tarefa (`OnExecuteTask`), as notificações parciais (`OnProgress`) e a finalização (`OnComplete`):

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Formulário LCL
    participant Runner as TLazAsyncTaskRunner
    participant Worker as TLazWorkerThread
    participant Loop as LCL Event Loop

    Dev->>Runner: RunAsync()
    Runner->>Worker: Create(Suspended) & Start()
    loop Processamento em Segundo Plano
        Worker->>Worker: Executa fatia da tarefa
        Worker->>Loop: Application.QueueAsyncCall(AsyncHandleProgress)
        Loop->>Dev: OnProgress(Sender, Current, Total, StatusMsg)
    end
    Worker->>Loop: Application.QueueAsyncCall(AsyncHandleComplete)
    Loop->>Dev: OnComplete(Sender, Success, ErrorMsg)
    Loop->>Worker: WaitFor() & Free
```

---

## 3. Cancelamento Cooperativo e Destruição à Prova de Falhas

O cancelamento em arquiteturas multithread modernas nunca deve matar a thread de forma abrupta (`TerminateThread`), o que deixaria conexões, arquivos e memória em estado corrompido. O `TLazAsyncTaskRunner` utiliza o padrão **Cancelamento Cooperativo**:

```pascal
procedure TFormProcessamento.AsyncTaskRunnerExecuteTask(Sender: TObject; var Cancelled: Boolean);
var
  i: Integer;
begin
  for i := 1 to 1000 do
  begin
    // A tarefa inspeciona periodicamente a flag de cancelamento
    if Cancelled then
      Exit;

    // Executa o trabalho real
    ProcessarItem(i);

    // Notifica o progresso para a UI thread
    AsyncTaskRunner.NotifyProgress(i, 1000, Format('Processando item %d...', [i]));
  end;
end;
```

No destrutor do componente, todas as chamadas assíncronas pendentes são limpas via `Application.RemoveAsyncCalls(Self)`, garantindo vazamento zero e estabilidade absoluta.

---

## 4. Código-Fonte Integral do Componente

A implementação completa do executor assíncrono `TLazAsyncTaskRunner` para Free Pascal e Lazarus está disponível em:

👉 **Arquivo:** [`code/units/LazAsyncTaskRunner.pas`](file:///d:/Projetos%20AntiGravity/Livros%20componentes/Livro1_Lazarus_LCL/code/units/LazAsyncTaskRunner.pas)
