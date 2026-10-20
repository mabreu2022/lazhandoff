{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 36: Motor de Permissões Baseadas em Papéis (TDlpSecurityRoleManager)
  Componente: TDlpSecurityRoleManager
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / Windows / Multiplataforma)
  Descrição: Motor declarativo de autorização RBAC (Role-Based Access Control)
             para interfaces gráficas VCL. Inspeciona a árvore hierárquica de
             controles do formulário ativo e impõe restrições visuais (ocultar,
             desabilitar, mascarar valores ou travar edição) conforme as credenciais
             do usuário logado na sessão corporativa.
==============================================================================}
unit DlpSecurityRoleManager;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Forms;

type
  { Ação aplicada sobre o controle na ausência de permissão }
  TDlpUnauthorizedAction = (uaHide, uaDisable, uaMask, uaReadOnly);

  { Item de configuração de regra RBAC }
  TDlpRolePermissionRule = class(TCollectionItem)
  private
    FControlName: string;
    FRequiredPermission: string;
    FAction: TDlpUnauthorizedAction;
    FMaskPlaceholder: string;
  published
    property ControlName: string read FControlName write FControlName;
    property RequiredPermission: string read FRequiredPermission write FRequiredPermission;
    property Action: TDlpUnauthorizedAction read FAction write FAction default uaDisable;
    property MaskPlaceholder: string read FMaskPlaceholder write FMaskPlaceholder;
  end;

  { Coleção tipada de regras de segurança }
  TDlpRolePermissionRules = class(TCollection)
  private
    FOwnerManager: TComponent;
    function GetItem(Index: Integer): TDlpRolePermissionRule;
    procedure SetItem(Index: Integer; const Value: TDlpRolePermissionRule);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    function AddRule(const AControlName, APermission: string;
      AAction: TDlpUnauthorizedAction = uaDisable; const APlaceholder: string = '***'): TDlpRolePermissionRule;
    property Items[Index: Integer]: TDlpRolePermissionRule read GetItem write SetItem; default;
  end;

  {============================================================================
    Componente: TDlpSecurityRoleManager
    Orquestrador RBAC em tempo de execução para formulários VCL
  ============================================================================}
  TDlpSecurityRoleManager = class(TComponent)
  private
    FCurrentUserRoles: TStringList;
    FCurrentUserPermissions: TStringList;
    FRules: TDlpRolePermissionRules;
    FActiveUserId: string;

    procedure SetRules(const Value: TDlpRolePermissionRules);
    function FindRuleForControl(const AControlName: string): TDlpRolePermissionRule;
    procedure ApplyRuleToControl(AControl: TControl; ARule: TDlpRolePermissionRule);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetUserSession(const AUserId: string; const ARoles, APermissions: array of string);
    procedure ClearUserSession;
    function HasRole(const ARole: string): Boolean;
    function HasPermission(const APermission: string): Boolean;

    procedure ApplySecurity(AContainer: TWinControl);
  published
    property ActiveUserId: string read FActiveUserId;
    property Rules: TDlpRolePermissionRules read FRules write SetRules;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpSecurityRoleManager]);
end;

{ TDlpRolePermissionRules }

constructor TDlpRolePermissionRules.Create(AOwner: TComponent);
begin
  inherited Create(TDlpRolePermissionRule);
  FOwnerManager := AOwner;
end;

function TDlpRolePermissionRules.GetOwner: TPersistent;
begin
  Result := FOwnerManager;
end;

function TDlpRolePermissionRules.GetItem(Index: Integer): TDlpRolePermissionRule;
begin
  Result := TDlpRolePermissionRule(inherited GetItem(Index));
end;

procedure TDlpRolePermissionRules.SetItem(Index: Integer; const Value: TDlpRolePermissionRule);
begin
  inherited SetItem(Index, Value);
end;

function TDlpRolePermissionRules.AddRule(const AControlName, APermission: string;
  AAction: TDlpUnauthorizedAction; const APlaceholder: string): TDlpRolePermissionRule;
begin
  Result := TDlpRolePermissionRule(inherited Add);
  Result.ControlName := AControlName;
  Result.RequiredPermission := APermission;
  Result.Action := AAction;
  Result.MaskPlaceholder := APlaceholder;
end;

{ TDlpSecurityRoleManager }

constructor TDlpSecurityRoleManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCurrentUserRoles := TStringList.Create;
  FCurrentUserRoles.Sorted := True;
  FCurrentUserRoles.Duplicates := dupIgnore;

  FCurrentUserPermissions := TStringList.Create;
  FCurrentUserPermissions.Sorted := True;
  FCurrentUserPermissions.Duplicates := dupIgnore;

  FRules := TDlpRolePermissionRules.Create(Self);
  FActiveUserId := '';
end;

destructor TDlpSecurityRoleManager.Destroy;
begin
  FRules.Free;
  FCurrentUserPermissions.Free;
  FCurrentUserRoles.Free;
  inherited Destroy;
end;

procedure TDlpSecurityRoleManager.SetRules(const Value: TDlpRolePermissionRules);
begin
  FRules.Assign(Value);
end;

procedure TDlpSecurityRoleManager.SetUserSession(const AUserId: string;
  const ARoles, APermissions: array of string);
var
  i: Integer;
begin
  FActiveUserId := AUserId;
  FCurrentUserRoles.Clear;
  for i := Low(ARoles) to High(ARoles) do
    FCurrentUserRoles.Add(UpperCase(Trim(ARoles[i])));

  FCurrentUserPermissions.Clear;
  for i := Low(APermissions) to High(APermissions) do
    FCurrentUserPermissions.Add(UpperCase(Trim(APermissions[i])));
end;

procedure TDlpSecurityRoleManager.ClearUserSession;
begin
  FActiveUserId := '';
  FCurrentUserRoles.Clear;
  FCurrentUserPermissions.Clear;
end;

function TDlpSecurityRoleManager.HasRole(const ARole: string): Boolean;
begin
  Result := (FCurrentUserRoles.IndexOf(UpperCase(Trim(ARole))) >= 0);
end;

function TDlpSecurityRoleManager.HasPermission(const APermission: string): Boolean;
begin
  Result := (FCurrentUserPermissions.IndexOf(UpperCase(Trim(APermission))) >= 0);
end;

function TDlpSecurityRoleManager.FindRuleForControl(const AControlName: string): TDlpRolePermissionRule;
var
  i: Integer;
begin
  for i := 0 to FRules.Count - 1 do
  begin
    if SameText(FRules[i].ControlName, AControlName) then
      Exit(FRules[i]);
  end;
  Result := nil;
end;

procedure TDlpSecurityRoleManager.ApplyRuleToControl(AControl: TControl; ARule: TDlpRolePermissionRule);
var
  Authorized: Boolean;
begin
  Authorized := HasPermission(ARule.RequiredPermission) or HasRole('ADMIN');

  if not Authorized then
  begin
    case ARule.Action of
      uaHide:
        AControl.Visible := False;

      uaDisable:
        AControl.Enabled := False;

      uaReadOnly:
        begin
          if AControl is TCustomEdit then
            TCustomEdit(AControl).ReadOnly := True
          else
            AControl.Enabled := False;
        end;

      uaMask:
        begin
          if AControl is TCustomEdit then
          begin
            TCustomEdit(AControl).Text := ARule.MaskPlaceholder;
            TCustomEdit(AControl).ReadOnly := True;
          end
          else if AControl is TLabel then
            TLabel(AControl).Caption := ARule.MaskPlaceholder;
        end;
    end;
  end;
end;

procedure TDlpSecurityRoleManager.ApplySecurity(AContainer: TWinControl);
var
  i: Integer;
  Ctrl: TControl;
  Rule: TDlpRolePermissionRule;
begin
  if not Assigned(AContainer) then Exit;

  for i := 0 to AContainer.ControlCount - 1 do
  begin
    Ctrl := AContainer.Controls[i];
    if Ctrl.Name <> '' then
    begin
      Rule := FindRuleForControl(Ctrl.Name);
      if Assigned(Rule) then
        ApplyRuleToControl(Ctrl, Rule);
    end;

    if Ctrl is TWinControl then
      ApplySecurity(TWinControl(Ctrl));
  end;
end;

end.
