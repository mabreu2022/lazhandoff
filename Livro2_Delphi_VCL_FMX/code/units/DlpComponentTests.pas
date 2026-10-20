{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 24: Testes Unitários de Componentes, Profiling e Prevenção de Leaks
  Suíte de Testes: DlpComponentTests
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / DUnitX & FastMM5
  Descrição: Suíte corporativa de testes unitários automatizados em DUnitX
             cobrindo ciclo de vida, integridade de referências cruzadas,
             regras de validação fiscal e fórmulas comerciais.
==============================================================================}
unit DlpComponentTests;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DlpSafeLinkedContainer,
  DlpCRUDOperationsBar,
  DlpProductStockIndicator;

type
  /// <summary>
  /// Suíte de testes de validação do ciclo de vida e cálculos dos componentes.
  /// </summary>
  [TestFixture]
  TDlpComponentLifecycleTest = class
  public
    [Test]
    procedure TestInstantiateAndDestroy;

    [Test]
    procedure TestNotificationCrossReference;

    [Test]
    procedure TestFiscalValidationCPF;

    [Test]
    procedure TestFiscalValidationCNPJ;

    [Test]
    procedure TestFinancialCalculations;
  end;

implementation

{ TDlpComponentLifecycleTest }

procedure TDlpComponentLifecycleTest.TestInstantiateAndDestroy;
var
  Container: TDlpSafeLinkedContainer;
  Indicator: TDlpProductStockIndicator;
begin
  Container := TDlpSafeLinkedContainer.Create(nil);
  try
    Assert.IsNotNull(Container, 'O contêiner instanciado não pode ser nulo.');
    Assert.AreEqual(0, Container.LinkedCount, 'A contagem inicial de links deve ser 0.');
  finally
    Container.Free;
  end;

  Indicator := TDlpProductStockIndicator.Create(nil);
  try
    Assert.IsNotNull(Indicator, 'O indicador de estoque não pode ser nulo.');
    Assert.AreEqual(240, Indicator.Width, 'A largura padrão deve ser 240 pixels.');
  finally
    Indicator.Free;
  end;
end;

procedure TDlpComponentLifecycleTest.TestNotificationCrossReference;
var
  HostContainer: TDlpSafeLinkedContainer;
  TargetObj: TComponent;
begin
  HostContainer := TDlpSafeLinkedContainer.Create(nil);
  try
    TargetObj := TComponent.Create(nil);
    try
      HostContainer.LinkComponent(TargetObj);
      Assert.AreEqual(1, HostContainer.LinkedCount, 'Deve constar 1 componente vinculado.');
    finally
      // Destrói o componente dependente antes do contêiner host
      TargetObj.Free;
    end;

    // A rotina de Notification deve ter expurgado a referência órfã
    Assert.AreEqual(0, HostContainer.LinkedCount,
      'A referência órfã deve ter sido expurgada pelo mecanismo Notification.');
  finally
    HostContainer.Free;
  end;
end;

procedure TDlpComponentLifecycleTest.TestFiscalValidationCPF;
begin
  Assert.IsTrue(TDlpCRUDOperationsBar.ValidateCPF('52998224725'),
    'CPF válido puro deve retornar True.');
  Assert.IsTrue(TDlpCRUDOperationsBar.ValidateCPF('529.982.247-25'),
    'CPF válido formatado com máscara deve retornar True.');

  Assert.IsFalse(TDlpCRUDOperationsBar.ValidateCPF('11111111111'),
    'CPF com dígitos repetidos deve ser rejeitado.');
  Assert.IsFalse(TDlpCRUDOperationsBar.ValidateCPF('52998224715'),
    'CPF com dígito verificador errado deve ser rejeitado.');
  Assert.IsFalse(TDlpCRUDOperationsBar.ValidateCPF('12345'),
    'CPF incompleto deve ser rejeitado.');
end;

procedure TDlpComponentLifecycleTest.TestFiscalValidationCNPJ;
begin
  Assert.IsTrue(TDlpCRUDOperationsBar.ValidateCNPJ('00000000000191'),
    'CNPJ válido puro deve retornar True.');
  Assert.IsTrue(TDlpCRUDOperationsBar.ValidateCNPJ('00.000.000/0001-91'),
    'CNPJ válido formatado deve retornar True.');

  Assert.IsFalse(TDlpCRUDOperationsBar.ValidateCNPJ('00000000000000'),
    'CNPJ com dígitos repetidos deve ser rejeitado.');
  Assert.IsFalse(TDlpCRUDOperationsBar.ValidateCNPJ('00000000000192'),
    'CNPJ com dígito verificador incorreto deve ser rejeitado.');
end;

procedure TDlpComponentLifecycleTest.TestFinancialCalculations;
var
  Margem, Markup: Double;
begin
  Margem := TDlpProductStockIndicator.CalculateMargin(100.0, 150.0);
  Markup := TDlpProductStockIndicator.CalculateMarkup(100.0, 150.0);

  Assert.AreEqual('33.33%', TDlpProductStockIndicator.FormatPercent(Margem),
    'Margem de lucro deve ser 33.33%.');
  Assert.AreEqual('50.00%', TDlpProductStockIndicator.FormatPercent(Markup),
    'Markup deve ser 50.00%.');
end;

initialization
  TDUnitX.RegisterTestFixture(TDlpComponentLifecycleTest);

end.
