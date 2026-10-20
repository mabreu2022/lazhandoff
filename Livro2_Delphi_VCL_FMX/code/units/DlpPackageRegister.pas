{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 05: Empacotamento Profissional (Packages .dpk)
  Unidade: DlpPackageRegister
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Unidade de registro de Design-Time que realiza o cadastro oficial
             dos componentes na Tool Palette do Delphi 12 Athens+, vinculando
             recursos de ícones compilados e categorias semânticas.
==============================================================================}
unit DlpPackageRegister;

interface

uses
  System.Classes,
  DesignIntf,
  DlpTypeHierarchyInspector,
  DlpSafeLinkedContainer,
  DlpEncryptedDataStore,
  DlpWindowsMessageInterceptor;

{ Procedimento oficial invocado pela IDE do Delphi para registro }
procedure Register;

implementation

{$R dlp_components_icons.res}

procedure Register;
begin
  { Registra os componentes na categoria 'Engenharia Delphi 12' da Tool Palette }
  RegisterComponents('Engenharia Delphi 12', [
    TDlpTypeHierarchyInspector,
    TDlpSafeLinkedContainer,
    TDlpEncryptedDataStore,
    TDlpWindowsMessageInterceptor
  ]);
end;

end.
