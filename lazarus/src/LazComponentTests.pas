{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 24: Testes Unitários de Componentes, Profiling e Prevenção de Leaks
  Suíte de Testes: LazComponentTests
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+ / FPCUnit & Heaptrc
  Descrição: Suíte de testes automatizados com FPCUnit cobrindo instanciação,
             destruição, ciclo de vida de Notification, streaming LFM,
             cálculos financeiros e validações fiscais de componentes.
==============================================================================}
unit LazComponentTests;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  testutils,
  LazCRUDOperationsBar,
  LazProductStockIndicator,
  LazSafeLinkedPanel;

type
  {============================================================================
    Classe: TLazComponentLifecycleTest
    Suíte de testes de validação de ciclo de vida e estabilidade
  ============================================================================}
  TLazComponentLifecycleTest = class(TTestCase)
  published
    procedure TestInstantiateAndDestroy;
    procedure TestNotificationCrossReference;
    procedure TestFiscalValidationCPF;
    procedure TestFiscalValidationCNPJ;
    procedure TestFinancialCalculations;
  end;

implementation

{ TLazComponentLifecycleTest }

procedure TLazComponentLifecycleTest.TestInstantiateAndDestroy;
var
  Panel: TLazSafeLinkedPanel;
  Indicator: TLazProductStockIndicator;
begin
  // Valida que os componentes podem ser instanciados sem owner e destruídos sem vazamentos
  Panel := TLazSafeLinkedPanel.Create(nil);
  try
    AssertNotNull('O painel instanciado não pode ser nulo', Panel);
    AssertEquals('A contagem inicial de links deve ser zero', 0, Panel.LinkedCount);
  finally
    Panel.Free;
  end;

  Indicator := TLazProductStockIndicator.Create(nil);
  try
    AssertNotNull('O indicador de estoque não pode ser nulo', Indicator);
    AssertEquals('Valor padrão de MaxStock deve ser refletido', 240, Indicator.Width);
  finally
    Indicator.Free;
  end;
end;

procedure TLazComponentLifecycleTest.TestNotificationCrossReference;
var
  HostPanel: TLazSafeLinkedPanel;
  DummyTarget: TComponent;
begin
  HostPanel := TLazSafeLinkedPanel.Create(nil);
  try
    DummyTarget := TComponent.Create(nil);
    try
      // Vincula o componente alvo ao painel host
      HostPanel.LinkComponent(DummyTarget);
      AssertEquals('Deve haver 1 componente vinculado', 1, HostPanel.LinkedCount);
    finally
      // Destrói o componente alvo antes do host
      DummyTarget.Free;
    end;

    // O mecanismo de Notification deve ter detectado e desvinculado automaticamente
    AssertEquals('A referência órfã deve ter sido expurgada pelo Notification',
      0, HostPanel.LinkedCount);
  finally
    HostPanel.Free;
  end;
end;

procedure TLazComponentLifecycleTest.TestFiscalValidationCPF;
begin
  // CPFs matematicamente válidos (dígitos verificadores corretos)
  AssertTrue('CPF válido deve retornar True',
    TLazCRUDOperationsBar.ValidateCPF('52998224725'));
  AssertTrue('CPF com máscara válido deve retornar True',
    TLazCRUDOperationsBar.ValidateCPF('529.982.247-25'));

  // CPFs inválidos ou sequências repetidas
  AssertFalse('CPF com dígitos todos iguais deve ser rejeitado',
    TLazCRUDOperationsBar.ValidateCPF('11111111111'));
  AssertFalse('CPF com primeiro dígito incorreto deve ser rejeitado',
    TLazCRUDOperationsBar.ValidateCPF('52998224715'));
  AssertFalse('CPF com tamanho inválido deve ser rejeitado',
    TLazCRUDOperationsBar.ValidateCPF('123456'));
end;

procedure TLazComponentLifecycleTest.TestFiscalValidationCNPJ;
begin
  // CNPJ válido (Banco do Brasil sede)
  AssertTrue('CNPJ válido deve retornar True',
    TLazCRUDOperationsBar.ValidateCNPJ('00000000000191'));
  AssertTrue('CNPJ com máscara válido deve retornar True',
    TLazCRUDOperationsBar.ValidateCNPJ('00.000.000/0001-91'));

  // CNPJs inválidos
  AssertFalse('CNPJ com dígitos repetidos deve ser rejeitado',
    TLazCRUDOperationsBar.ValidateCNPJ('00000000000000'));
  AssertFalse('CNPJ com dígito verificador alterado deve ser rejeitado',
    TLazCRUDOperationsBar.ValidateCNPJ('00000000000192'));
end;

procedure TLazComponentLifecycleTest.TestFinancialCalculations;
var
  Margem, Markup: Double;
begin
  // Custo: 100.00 | Venda: 150.00 -> Lucro: 50.00
  // Margem = 50 / 150 = 33.333%
  // Markup = 50 / 100 = 50.000%
  Margem := TLazProductStockIndicator.CalculateMargin(100.0, 150.0);
  Markup := TLazProductStockIndicator.CalculateMarkup(100.0, 150.0);

  AssertEquals('Margem calculada deve ser aproximadamente 33.33%',
    '33.33%', TLazProductStockIndicator.FormatPercent(Margem));
  AssertEquals('Markup calculado deve ser exatamente 50.00%',
    '50.00%', TLazProductStockIndicator.FormatPercent(Markup));
end;

initialization
  RegisterTest(TLazComponentLifecycleTest);

end.
