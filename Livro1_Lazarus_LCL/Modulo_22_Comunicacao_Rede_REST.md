# MÓDULO 22: Componentes de Comunicação de Rede e Consumo de APIs (TLazRestClientBridge)

A integração com serviços externos via protocolos web (APIs RESTful, webhooks, gateways de pagamento e autenticação OAuth2 / JWT) tornou-se requisito indispensável em qualquer ecossistema de software contemporâneo. No entanto, realizar requisições HTTP síncronas a partir da thread principal da interface gráfica trava o loop de mensagens da **LCL**, congelando a aplicação durante períodos de lentidão na rede ou alta latência do servidor.

Neste módulo, construímos o componente não-visual **`TLazRestClientBridge`**, utilizando os módulos nativos **`fphttpclient`** e **`fpjson`** do Free Pascal, provendo suporte a Bearer Tokens, headers configuráveis e chamadas assíncronas com retorno seguro na UI thread.

---

## 1. O Subsistema de Rede do Free Pascal (`fphttpclient` & `fpjson`)

A RTL do Free Pascal fornece uma pilha completa de clientes HTTP sem necessidade de componentes comerciais de terceiros:

```mermaid
graph TD
    subgraph Camada de Negocio
        A[Formulario LCL] -->|ExecuteAsync('POST', '/api/pedidos', JSON)| B[TLazRestClientBridge]
    end

    subgraph Thread de Rede
        B --> C[TLazRestWorkerThread]
        C --> D[TFPHTTPClient]
        D -->|Injeta Headers / Bearer Token| E[Endpoint HTTP Remoto]
        E -->|Retorna StatusCode + JSON Payload| D
    end

    subgraph Despacho Seguro
        D -->|Application.QueueAsyncCall| F[LCL Event Loop]
        F -->|Callback TOnRestResponseEvent| A
    end
```

### 1.1 Injeção de Segurança e Headers
O método de montagem da requisição encapsula a injeção do cabeçalho `Authorization: Bearer <token>` e o mime type `application/json`:

```pascal
Client.IOTimeout := FTimeout * 1000;
Client.AddHeader('Content-Type', 'application/json');
Client.AddHeader('Accept', 'application/json');

if FToken <> '' then
  Client.AddHeader('Authorization', 'Bearer ' + FToken);
```

---

## 2. Execução Assíncrona e Resolução na Interface

Para garantir zero travamentos na tela, o método `ExecuteAsync` cria uma `TLazRestWorkerThread` em segundo plano com `FreeOnTerminate := True`. Ao receber a resposta ou capturar uma falha de rede (ex.: timeout, DNS não resolvido), a thread empacota a estrutura `TRestResponseData` e despacha para a interface através de `Application.QueueAsyncCall`:

```pascal
procedure TFormDashboard.BtnConsultarPrecosClick(Sender: TObject);
begin
  RestClientBridge.ExecuteAsync('GET', '/v1/cotacoes', '',
    procedure(Sender: TObject; StatusCode: Integer; const ResponseBody, ErrorMsg: string)
    begin
      if StatusCode = 200 then
        ProcessarJSONRetorno(ResponseBody)
      else
        ShowMessage('Falha ao consultar cotações: ' + ErrorMsg);
    end);
end;
```

---

## 3. Código-Fonte Integral do Componente

A implementação completa do cliente RESTful `TLazRestClientBridge` para Free Pascal e Lazarus está disponível em:

👉 **Arquivo:** [`code/units/LazRestClientBridge.pas`](file:///d:/Projetos%20AntiGravity/Livros%20componentes/Livro1_Lazarus_LCL/code/units/LazRestClientBridge.pas)
