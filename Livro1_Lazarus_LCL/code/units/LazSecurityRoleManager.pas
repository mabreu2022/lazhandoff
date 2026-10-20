{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 36: Motor de Permissões Baseadas em Papéis (TLazSecurityRoleManager)
  Componente: TLazSecurityRoleManager
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Motor de controle de acesso baseado em papéis (RBAC - Role-Based
             Access Control) para aplicações LCL. Varre recursivamente árvores de
             componentes em formulários e painéis, aplicando ações de restrição
             (ocultar, desabilitar, mascarar ou tornar somente leitura) de acordo
             com os privilégios do usuário autenticado.
==============================================================================}
unit LazSecurityRoleManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  StdCtrls,
  Forms;

type
  { Ação a ser aplicada quando o usuário não possuir o privilégio exigido }
  TUnauthorizedAction = (uaHide, uaDisable, uaMask, uaReadOnly);

  { Regra de permissão vinculada a um controle visual }
  TRolePermissionRule = class(TCollectionItem)
  private
    FControlName: string;
    FRequiredPermission: string;
    FAction: TUnauthorizedAction;
    FMaskPlaceholder: string;
  published
    property ControlName: string read FControlName write FControlName;
    property RequiredPermission: string read FRequiredPermission write FRequiredPermission;
    property Action: TUnauthorizedAction read FAction write FAction default uaDisable;
    property MaskPlaceholder: string read FMaskPlaceholder write FMaskPlaceholder;
  end;

  { Coleção tipada de regras de segurança }
  TRolePermissionRules = class(TCollection)
  private
    FOwnerManager: TComponent;
    function GetItem(Index: Integer): TRolePermissionRule;
    procedure SetItem(Index: Integer; const Value: TRolePermissionRule);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    function AddRule(const AControlName, APermission: string;
      AAction: TUnauthorizedAction = uaDisable; const APlaceholder: string = '***'): TRolePermissionRule;
    property Items[Index: Integer]: TRolePermissionRule read GetItem write SetItem; default;
  end;

  {============================================================================
    Componente: TLazSecurityRoleManager
    Orquestrador RBAC em tempo de execução para formulários LCL
  ============================================================================}
  TLazSecurityRoleManager = class(TComponent)
  private
    FCurrentUserRoles: TStringList;
    FCurrentUserPermissions: TStringList;
    FRules: TRolePermissionRules;
    FActiveUserId: string;

    procedure SetRules(const Value: TRolePermissionRules);
    function FindRuleForControl(const AControlName: string): TRolePermissionRule;
    procedure ApplyRuleToControl(AControl: TControl; ARule: TRolePermissionRule);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Gestão de Sessão do Usuário }
    procedure SetUserSession(const AUserId: string; const ARoles, APermissions: array of string);
    procedure ClearUserSession;
    function HasRole(const ARole: string): Boolean;
    function HasPermission(const APermission: string): Boolean;

    { Aplicação de Segurança Recursiva na Interface }
    procedure ApplySecurity(AContainer: TWinControl);
  published
    property ActiveUserId: string read FActiveUserId;
    property Rules: TRolePermissionRules read FRules write SetRules;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Engenharia Avancada', [TLazSecurityRoleManager]);
end;

{ TRolePermissionRules }

constructor TRolePermissionRules.Create(AOwner: TComponent);
begin
  inherited Create(TRolePermissionRule);
  FOwnerManager := AOwner;
end;

function TRolePermissionRules.GetOwner: TPersistent;
begin
  Result := FOwnerManager;
end;

function TRolePermissionRules.GetItem(Index: Integer): TRolePermissionRule;
begin
  Result := TRolePermissionRule(inherited GetItem(Index));
end;

procedure TRolePermissionRules.SetItem(Index: Integer; const Value: TRolePermissionRule);
begin
  inherited SetItem(Index, Value);
end;

function TRolePermissionRules.AddRule(const AControlName, APermission: string;
  AAction: TUnauthorizedAction; const APlaceholder: string): TRolePermissionRule;
begin
  Result := TRolePermissionRule(inherited Add);
  Result.ControlName := AControlName;
  Result.RequiredPermission := APermission;
  Result.Action := AAction;
  Result.MaskPlaceholder := APlaceholder;
end;

{ TLazSecurityRoleManager }

constructor TLazSecurityRoleManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCurrentUserRoles := TStringList.Create;
  FCurrentUserRoles.Sorted := True;
  FCurrentUserRoles.Duplicates := dupIgnore;

  FCurrentUserPermissions := TStringList.Create;
  FCurrentUserPermissions.Sorted := True;
  FCurrentUserPermissions.Duplicates := dupIgnore;

  FRules := TRolePermissionRules.Create(Self);
  FActiveUserId := '';
end;

destructor TLazSecurityRoleManager.Destroy;
begin
  FRules.Free;
  FCurrentUserPermissions.Free;
  FCurrentUserRoles.Free;
  inherited Destroy;
end;

procedure TLazSecurityRoleManager.SetRules(const Value: TRolePermissionRules);
begin
  FRules.Assign(Value);
end;

procedure TLazSecurityRoleManager.SetUserSession(const AUserId: string;
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

procedure TLazSecurityRoleManager.ClearUserSession;
begin
  FActiveUserId := '';
  FCurrentUserRoles.Clear;
  FCurrentUserPermissions.Clear;
end;

function TLazSecurityRoleManager.HasRole(const ARole: string): Boolean;
begin
  Result := (FCurrentUserRoles.IndexOf(UpperCase(Trim(ARole))) >= 0);
end;

function TLazSecurityRoleManager.HasPermission(const APermission: string): Boolean;
begin
  Result := (FCurrentUserPermissions.IndexOf(UpperCase(Trim(APermission))) >= 0);
end;

function TLazSecurityRoleManager.FindRuleForControl(const AControlName: string): TRolePermissionRule;
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

procedure TLazSecurityRoleManager.ApplyRuleToControl(AControl: TControl; ARule: TRolePermissionRule);
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

procedure TLazSecurityRoleManager.ApplySecurity(AContainer: TWinControl);
var
  i: Integer;
  Ctrl: TControl;
  Rule: TRolePermissionRule;
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

    { Recursão se o controle for um contêiner janelado (TPanel, TGroupBox, TPageControl) }
    if Ctrl is TWinControl then
      ApplySecurity(TWinControl(Ctrl));
  end;
end;

end.
