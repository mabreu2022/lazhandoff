# MÓDULO 23: Componentes de Hardware, I/O e Comunicação Serial (TLazSerialDeviceConnector)

A automação comercial e industrial (PDVs de supermercado, balanças rodoviárias e de checkout, leitores ópticos de código de barras, impressoras de etiquetas térmicas e controladores PLC) depende prioritariamente da comunicação serial (padrões RS-232, RS-485 e Virtual COM sobre USB CDC). Em aplicações de checkout, o software de frente de caixa não pode travar ou perder leituras de pesagem enquanto o operador posiciona mercadorias sobre o prato da balança.

Neste módulo, implementamos o componente não-visual **`TLazSerialDeviceConnector`**, fornecendo comunicação serial nativa multiplataforma (Windows e Linux) no **Lazarus / Free Pascal**, dotado de thread de escuta contínua, decodificador de balanças Toledo/Filizola e sincronização segura com a UI thread.

---

## 1. Arquitetura de I/O de Baixo Nível: Windows vs. Linux

O componente abstrai as diferenças estruturais de acesso a portas físicas entre os sistemas operacionais através de diretivas de compilação condicional:

```mermaid
graph TD
    subgraph Aplicacao LCL
        A[Tela de Checkout PDV] -->|RequestWeight| B[TLazSerialDeviceConnector]
    end

    subgraph Camada do Sistema Operacional
        B -->|WINDOWS: CreateFile / DCB| C[\\.\COM1 a COM256]
        B -->|LINUX: fpopen / termios| D[/dev/ttyUSB0 ou /dev/ttyS0]
    end

    subgraph Thread de Escuta
        C --> E[TLazSerialListenerThread]
        D --> E
        E -->|Application.QueueAsyncCall| F[LCL Event Loop]
    end

    subgraph Eventos de Negocio
        F --> G[OnDataReceived: String Bruta]
        F --> H[OnWeightReceived: Peso em KG Decodificado]
    end
```

### 1.1 O Prefixo de Proteção de Portas no Windows
Ao acessar portas seriais com identificadores superiores a `COM9` (ex.: `COM10`, `COM24`), a API do Windows falha caso a string seja passada crua. É obrigatório injetar o prefixo de dispositivo `\\.\`:

```pascal
PortPath := '\\.\' + FPort; // '\\.\COM12'
FPortHandle := CreateFile(PChar(PortPath), GENERIC_READ or GENERIC_WRITE,
  0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
```

---

## 2. Decodificação de Protocolos de Balanças de Checkout

As principais balanças comerciais do mercado brasileiro (Toledo Prix 3, Toledo 9094, Filizola Platina, Urano POP) operam sob o protocolo padrão de interrogação:

1. A aplicação envia o caractere de controle **`ENQ` (`#5`)** requisitando a leitura.
2. A balança devolve um quadro contendo delimitadores de início e fim (`STX` `#2` e `ETX` `#3`) e 5 dígitos representando o peso em gramas:

$$
\text{Quadro Retornado:} \quad [\text{STX}] \, \mathbf{0} \, \mathbf{2} \, \mathbf{4} \, \mathbf{5} \, \mathbf{0} \, [\text{ETX}] \implies 2.450 \text{ kg}
$$

O método estático `ParseToledoWeight` realiza a extração e conversão automática para `Double`:

```pascal
class function TLazSerialDeviceConnector.ParseToledoWeight(const ARaw: string): Double;
var
  CleanDigits: string;
  i, ValInt: Integer;
begin
  Result := 0.0;
  CleanDigits := '';
  for i := 1 to Length(ARaw) do
  begin
    if ARaw[i] in ['0'..'9'] then
      CleanDigits := CleanDigits + ARaw[i];
  end;

  if Length(CleanDigits) >= 5 then
  begin
    CleanDigits := Copy(CleanDigits, Length(CleanDigits) - 4, 5);
    ValInt := StrToIntDef(CleanDigits, 0);
    Result := ValInt / 1000.0;
  end;
end;
```

---

## 3. Código-Fonte Integral do Componente

A unidade com a implementação completa, incluindo suporte multiplataforma com termios e Windows API, está localizada em:

👉 **Arquivo:** [`code/units/LazSerialDeviceConnector.pas`](file:///d:/Projetos%20AntiGravity/Livros%20componentes/Livro1_Lazarus_LCL/code/units/LazSerialDeviceConnector.pas)
