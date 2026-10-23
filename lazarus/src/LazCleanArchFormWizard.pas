{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 08: Assistentes de Projeto e Extensão da IDE (IDEIntf)
  Unidade: LazCleanArchFormWizard
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+ (ProjectIntf / IDEIntf)
  Descrição: Assistente profissional de geração de formulários com arquitetura
             Model-View-Presenter (MVP / Clean Architecture) que se integra ao
             menu 'File -> New...' do Lazarus através de TFileDescPascalUnitWithResource.
==============================================================================}
unit LazCleanArchFormWizard;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  ProjectIntf,
  FormEditingIntf,
  LazIDEIntf;

type
  {============================================================================
    Classe: TLazCleanArchFormDescriptor
    Descritor registrado no menu 'File -> New...' da IDE Lazarus
  ============================================================================}
  TLazCleanArchFormDescriptor = class(TFileDescPascalUnitWithResource)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function CreateSource(const aFilename, aSourceName, aResourceName: string): string; override;
    function CreateLFM(const NewFilename, ResourceName: string): string; virtual;
  end;

procedure Register;

implementation

procedure Register;
begin
  { Registra o assistente de novo item no menu 'File -> New...' do Lazarus }
  RegisterProjectFileDescriptor(TLazCleanArchFormDescriptor.Create);
end;

{ TLazCleanArchFormDescriptor }

constructor TLazCleanArchFormDescriptor.Create;
begin
  inherited Create;
  Name := 'Clean Architecture MVP Form';
  ResourceClass := TForm;
  DeclareClassVariable := True;
end;

function TLazCleanArchFormDescriptor.GetLocalizedName: string;
begin
  Result := 'Formulário MVP (Clean Architecture)';
end;

function TLazCleanArchFormDescriptor.GetLocalizedDescription: string;
begin
  Result := 'Cria um novo formulário pré-configurado com a arquitetura Model-View-Presenter (MVP), ' +
            'com desacoplamento estrito entre a interface visual e a lógica de apresentação.';
end;

function TLazCleanArchFormDescriptor.CreateSource(const aFilename, aSourceName, aResourceName: string): string;
var
  TargetUnitName: string;
  SB: TStringBuilder;
begin
  if aSourceName <> '' then
    TargetUnitName := aSourceName
  else
    TargetUnitName := ChangeFileExt(ExtractFileName(aFilename), '');
  if TargetUnitName = '' then
    TargetUnitName := 'UnitCleanArch';

  SB := TStringBuilder.Create;
  try
    SB.AppendLine(Format('unit %s;', [TargetUnitName]));
    SB.AppendLine('');
    SB.AppendLine('{$mode objfpc}{$H+}');
    SB.AppendLine('');
    SB.AppendLine('interface');
    SB.AppendLine('');
    SB.AppendLine('uses');
    SB.AppendLine('  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;');
    SB.AppendLine('');
    SB.AppendLine('type');
    SB.AppendLine('  { 1. Contrato da View (Desacoplamento puro) }');
    SB.AppendLine('  ICustomerView = interface');
    SB.AppendLine('    [''{8C2A7B61-9D4E-4B52-87F3-7C12F8A4B690}'']');
    SB.AppendLine('    procedure DisplayNotification(const AMessage: string);');
    SB.AppendLine('    procedure SetActionState(AEnabled: Boolean);');
    SB.AppendLine('  end;');
    SB.AppendLine('');
    SB.AppendLine('  { 2. Presenter (Lógica de Apresentação) }');
    SB.AppendLine('  TCustomerPresenter = class');
    SB.AppendLine('  private');
    SB.AppendLine('    FView: ICustomerView;');
    SB.AppendLine('  public');
    SB.AppendLine('    constructor Create(AView: ICustomerView);');
    SB.AppendLine('    procedure ExecuteAction;');
    SB.AppendLine('  end;');
    SB.AppendLine('');
    SB.AppendLine(Format('  { 3. Formulário que implementa a View }', []));
    SB.AppendLine(Format('  T%s = class(TForm, ICustomerView)', [aResourceName]));
    SB.AppendLine('  private');
    SB.AppendLine('    FPresenter: TCustomerPresenter;');
    SB.AppendLine('  public');
    SB.AppendLine('    constructor Create(AOwner: TComponent); override;');
    SB.AppendLine('    destructor Destroy; override;');
    SB.AppendLine('    { Implementação de ICustomerView }');
    SB.AppendLine('    procedure DisplayNotification(const AMessage: string);');
    SB.AppendLine('    procedure SetActionState(AEnabled: Boolean);');
    SB.AppendLine('  end;');
    SB.AppendLine('');
    SB.AppendLine(Format('var', []));
    SB.AppendLine(Format('  %s: T%s;', [aResourceName, aResourceName]));
    SB.AppendLine('');
    SB.AppendLine('implementation');
    SB.AppendLine('');
    SB.AppendLine(Format('{$R *.lfm}', []));
    SB.AppendLine('');
    SB.AppendLine('{ TCustomerPresenter }');
    SB.AppendLine('');
    SB.AppendLine('constructor TCustomerPresenter.Create(AView: ICustomerView);');
    SB.AppendLine('begin');
    SB.AppendLine('  inherited Create;');
    SB.AppendLine('  FView := AView;');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine('procedure TCustomerPresenter.ExecuteAction;');
    SB.AppendLine('begin');
    SB.AppendLine('  if Assigned(FView) then');
    SB.AppendLine('  begin');
    SB.AppendLine('    FView.SetActionState(False);');
    SB.AppendLine('    FView.DisplayNotification(''Ação de domínio executada com sucesso pelo Presenter!'');');
    SB.AppendLine('    FView.SetActionState(True);');
    SB.AppendLine('  end;');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine(Format('{ T%s }', [aResourceName]));
    SB.AppendLine('');
    SB.AppendLine(Format('constructor T%s.Create(AOwner: TComponent);', [aResourceName]));
    SB.AppendLine('begin');
    SB.AppendLine('  inherited Create(AOwner);');
    SB.AppendLine('  FPresenter := TCustomerPresenter.Create(Self);');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine(Format('destructor T%s.Destroy;', [aResourceName]));
    SB.AppendLine('begin');
    SB.AppendLine('  FreeAndNil(FPresenter);');
    SB.AppendLine('  inherited Destroy;');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine(Format('procedure T%s.DisplayNotification(const AMessage: string);', [aResourceName]));
    SB.AppendLine('begin');
    SB.AppendLine('  ShowMessage(AMessage);');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine(Format('procedure T%s.SetActionState(AEnabled: Boolean);', [aResourceName]));
    SB.AppendLine('begin');
    SB.AppendLine('  Enabled := AEnabled;');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine('end.');

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TLazCleanArchFormDescriptor.CreateLFM(const NewFilename, ResourceName: string): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine(Format('object %s: T%s', [ResourceName, ResourceName]));
    SB.AppendLine('  Left = 320');
    SB.AppendLine('  Top = 180');
    SB.AppendLine('  Width = 500');
    SB.AppendLine('  Height = 350');
    SB.AppendLine(Format('  Caption = ''Formulário MVP - %s''', [ResourceName]));
    SB.AppendLine('  Color = clBtnFace');
    SB.AppendLine('  Font.Name = ''Segoe UI''');
    SB.AppendLine('  Position = poScreenCenter');
    SB.AppendLine('end');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
