{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 05: Empacotamento Profissional (Packages .lpk)
  Unidade: LazPackageRegister
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Unidade exclusiva de Design-Time que centraliza o registro oficial
             de todos os componentes na Tool Palette do Lazarus, registrando
             ícones de paleta e vinculando editores especializados da IDEIntf.
==============================================================================}
unit LazPackageRegister;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  LResources,
  LazTypeInfoInspector,
  LazSafeLinkedPanel,
  LazBinaryBlobContainer,
  LazAsyncEventHook;

{ Procedimento oficial invocado pela IDE Lazarus ao carregar o pacote }
procedure Register;

implementation

procedure Register;
begin
  { Registra os componentes na aba 'Engenharia Lazarus' da Tool Palette }
  RegisterComponents('Engenharia Lazarus', [
    TLazTypeInfoInspector,
    TLazSafeLinkedPanel,
    TLazBinaryBlobContainer,
    TLazAsyncEventHook
  ]);
end;

initialization
  { Inicialização de recursos de ícones (.lrs) compilados via lazres }
  {$I laz_components_icons.lrs}

end.
