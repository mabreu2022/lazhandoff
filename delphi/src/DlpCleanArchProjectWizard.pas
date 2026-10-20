{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 08: Assistentes de Projeto e Extensão da IDE (ToolsAPI Profunda)
  Unidade: DlpCleanArchProjectWizard
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (ToolsAPI)
  Descrição: Assistente corporativo (Project & Repository Wizard) implementado
             via Open Tools API (OTA) do Delphi 12, injetando uma estrutura
             completa em camadas (Domain, UseCase e View) com um clique na IDE.
==============================================================================}
unit DlpCleanArchProjectWizard;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Dialogs,
  ToolsAPI;

type
  { Buffer de código em memória para criação dinâmica de módulos OTA }
  TDlpOTAFileBuffer = class(TInterfacedObject, IOTAFile)
  private
    FSourceCode: string;
  public
    constructor Create(const ASource: string);
    function GetSource: string;
    function GetAge: TDateTime;
  end;

  { Criador de módulos que gera uma unidade com arquitetura Clean }
  TDlpCleanModuleCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  public
    { IOTACreator }
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;

    { IOTAModuleCreator }
    function GetAncestorName: string;
    function GetImplFileName: string;
    function GetIntfFileName: string;
    function GetFormName: string;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
    function NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    procedure FormCreated(const FormEditor: IOTAFormEditor);
  end;

  {============================================================================
    Classe: TDlpCleanArchProjectWizard
    Implementa o Wizard completo para a galeria 'File -> New -> Other...'
  ============================================================================}
  TDlpCleanArchProjectWizard = class(TNotifierObject, IOTAWizard, IOTARepositoryWizard, IOTAMenuWizard)
  public
    { IOTAWizard }
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;

    { IOTARepositoryWizard }
    function GetAuthor: string;
    function GetComment: string;
    function GetPage: string;
    function GetGlyph: Cardinal;

    { IOTAMenuWizard }
    function GetMenuText: string;
  end;

procedure Register;

implementation

procedure Register;
begin
  { Registra o assistente na ToolsAPI da IDE do Delphi }
  RegisterPackageWizard(TDlpCleanArchProjectWizard.Create as IOTAWizard);
end;

{ TDlpOTAFileBuffer }

constructor TDlpOTAFileBuffer.Create(const ASource: string);
begin
  inherited Create;
  FSourceCode := ASource;
end;

function TDlpOTAFileBuffer.GetSource: string;
begin
  Result := FSourceCode;
end;

function TDlpOTAFileBuffer.GetAge: TDateTime;
begin
  Result := -1; // Arquivo novo em memória
end;

{ TDlpCleanModuleCreator }

function TDlpCleanModuleCreator.GetCreatorType: string;
begin
  Result := sUnit;
end;

function TDlpCleanModuleCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TDlpCleanModuleCreator.GetFileSystem: string;
begin
  Result := '';
end;

function TDlpCleanModuleCreator.GetOwner: IOTAModule;
begin
  Result := nil;
end;

function TDlpCleanModuleCreator.GetUnnamed: Boolean;
begin
  Result := True;
end;

function TDlpCleanModuleCreator.GetAncestorName: string;
begin
  Result := '';
end;

function TDlpCleanModuleCreator.GetImplFileName: string;
begin
  Result := '';
end;

function TDlpCleanModuleCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TDlpCleanModuleCreator.GetFormName: string;
begin
  Result := '';
end;

function TDlpCleanModuleCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TDlpCleanModuleCreator.GetShowForm: Boolean;
begin
  Result := False;
end;

function TDlpCleanModuleCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TDlpCleanModuleCreator.NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TDlpCleanModuleCreator.NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TDlpCleanModuleCreator.NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine(Format('unit %s;', [ModuleIdent]));
    SB.AppendLine('');
    SB.AppendLine('interface');
    SB.AppendLine('');
    SB.AppendLine('uses');
    SB.AppendLine('  System.SysUtils, System.Classes;');
    SB.AppendLine('');
    SB.AppendLine('type');
    SB.AppendLine('  { Camada de Domínio: Contrato do Repositório }');
    SB.AppendLine('  ICustomerRepository = interface');
    SB.AppendLine('    [''{A5F2D981-8B3C-4D2A-93E1-6B4F8C9A1D20}'']');
    SB.AppendLine('    function GetCustomerName(const AID: Integer): string;');
    SB.AppendLine('  end;');
    SB.AppendLine('');
    SB.AppendLine('  { Camada de Casos de Uso: Serviço de Negócio }');
    SB.AppendLine('  TCustomerService = class');
    SB.AppendLine('  private');
    SB.AppendLine('    FRepo: ICustomerRepository;');
    SB.AppendLine('  public');
    SB.AppendLine('    constructor Create(ARepo: ICustomerRepository);');
    SB.AppendLine('    function ExecuteProcess(const AID: Integer): string;');
    SB.AppendLine('  end;');
    SB.AppendLine('');
    SB.AppendLine('implementation');
    SB.AppendLine('');
    SB.AppendLine('{ TCustomerService }');
    SB.AppendLine('');
    SB.AppendLine('constructor TCustomerService.Create(ARepo: ICustomerRepository);');
    SB.AppendLine('begin');
    SB.AppendLine('  inherited Create;');
    SB.AppendLine('  FRepo := ARepo;');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine('function TCustomerService.ExecuteProcess(const AID: Integer): string;');
    SB.AppendLine('begin');
    SB.AppendLine('  if Assigned(FRepo) then');
    SB.AppendLine('    Result := ''Cliente Processado: '' + FRepo.GetCustomerName(AID)');
    SB.AppendLine('  else');
    SB.AppendLine('    Result := ''Repositório indisponível'';');
    SB.AppendLine('end;');
    SB.AppendLine('');
    SB.AppendLine('end.');

    Result := TDlpOTAFileBuffer.Create(SB.ToString);
  finally
    SB.Free;
  end;
end;

procedure TDlpCleanModuleCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
end;

{ TDlpCleanArchProjectWizard }

function TDlpCleanArchProjectWizard.GetIDString: string;
begin
  Result := 'Dlp.Enterprise.CleanArchWizard.12';
end;

function TDlpCleanArchProjectWizard.GetName: string;
begin
  Result := 'Clean Architecture Module Wizard';
end;

function TDlpCleanArchProjectWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

function TDlpCleanArchProjectWizard.GetAuthor: string;
begin
  Result := 'Engenharia de Software Especializada';
end;

function TDlpCleanArchProjectWizard.GetComment: string;
begin
  Result := 'Gera módulos corporativos com camadas de Domínio e Casos de Uso desacoplados.';
end;

function TDlpCleanArchProjectWizard.GetPage: string;
begin
  Result := 'Engenharia Delphi 12';
end;

function TDlpCleanArchProjectWizard.GetGlyph: Cardinal;
begin
  Result := 0; // Usa ícone padrão da galeria da IDE
end;

function TDlpCleanArchProjectWizard.GetMenuText: string;
begin
  Result := 'Novo Módulo Clean Architecture...';
end;

procedure TDlpCleanArchProjectWizard.Execute;
var
  ModServices: IOTAModuleServices;
begin
  if Supports(BorlandIDEServices, IOTAModuleServices, ModServices) then
  begin
    { Cria e injeta o novo módulo gerado diretamente no editor da IDE }
    ModServices.CreateModule(TDlpCleanModuleCreator.Create);
  end;
end;

end.
