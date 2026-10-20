{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 01: Arquitetura Orientada a Componentes e Hierarquia de Classes
  Componente: TDlpTypeHierarchyInspector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e Multiplataforma)
  Descrição: Componente não-visual que inspeciona a hierarquia de herança,
             a RTTI clássica (TypInfo) e a RTTI estendida moderna (System.Rtti),
             incluindo atributos customizados anotados em classes e propriedades.
==============================================================================}
unit DlpTypeHierarchyInspector;

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections;

type
  { Atributo customizado para demonstrar anotação semântica em componentes }
  ComponentDocAttribute = class(TCustomAttribute)
  private
    FDescription: string;
    FVersion: string;
  public
    constructor Create(const ADescription, AVersion: string);
    property Description: string read FDescription;
    property Version: string read FVersion;
  end;

  { Nível de profundidade de inspeção de herança }
  TDlpInspectionDepth = (
    idImmediateOnly,    // Apenas a classe alvo
    idUntilComponent,   // Até TComponent
    idFullToTObject     // Até a raiz universal TObject
  );

  { Registro com metadados de propriedade obtidos via System.Rtti }
  TDlpPropertyExtendedMeta = record
    PropName: string;
    TypeName: string;
    Visibility: string;
    IsReadable: Boolean;
    IsWritable: Boolean;
    CustomAttributeCount: Integer;
    AttributesSummary: string;
  end;

  { Array dinâmico com os metadados das propriedades }
  TDlpPropertyExtendedMetaArray = TArray<TDlpPropertyExtendedMeta>;

  { Eventos para callbacks e reatividade na UI }
  TOnClassNodeFound = procedure(Sender: TObject; const AClassName: string;
    AClassRef: TClass; ADepth: Integer) of object;
  TOnPropertyInspected = procedure(Sender: TObject;
    const AMeta: TDlpPropertyExtendedMeta) of object;

  {============================================================================
    Classe: TDlpTypeHierarchyInspector
    Componente não-visual projetado para Delphi 12 Athens+
  ============================================================================}
  [ComponentDoc('Inspetor avançado de RTTI estendida e genealogia para Delphi 12', '1.0.0')]
  TDlpTypeHierarchyInspector = class(TComponent)
  private
    FTargetComponent: TComponent;
    FInspectionDepth: TDlpInspectionDepth;
    FIncludePrivateProps: Boolean;
    FOnClassNodeFound: TOnClassNodeFound;
    FOnPropertyInspected: TOnPropertyInspected;

    procedure SetTargetComponent(const AValue: TComponent);
    function VisibilityToString(AVis: TMemberVisibility): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos de extração de relatórios e inspeção via RTTI }
    function GetClassAncestry(AInstance: TObject = nil): TStrings;
    function GetExtendedProperties(AInstance: TObject = nil): TDlpPropertyExtendedMetaArray;
    function GenerateMarkdownDocumentation(AInstance: TObject = nil): string;
  published
    property TargetComponent: TComponent read FTargetComponent write SetTargetComponent;
    property InspectionDepth: TDlpInspectionDepth read FInspectionDepth write FInspectionDepth default idFullToTObject;
    property IncludePrivateProps: Boolean read FIncludePrivateProps write FIncludePrivateProps default False;

    property OnClassNodeFound: TOnClassNodeFound read FOnClassNodeFound write FOnClassNodeFound;
    property OnPropertyInspected: TOnPropertyInspected read FOnPropertyInspected write FOnPropertyInspected;
  end;

{ Procedimento oficial de registro na Tool Palette do Delphi }
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpTypeHierarchyInspector]);
end;

{ ComponentDocAttribute }

constructor ComponentDocAttribute.Create(const ADescription, AVersion: string);
begin
  inherited Create;
  FDescription := ADescription;
  FVersion := AVersion;
end;

{ TDlpTypeHierarchyInspector }

constructor TDlpTypeHierarchyInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTargetComponent := nil;
  FInspectionDepth := idFullToTObject;
  FIncludePrivateProps := False;
end;

destructor TDlpTypeHierarchyInspector.Destroy;
begin
  FTargetComponent := nil;
  inherited Destroy;
end;

procedure TDlpTypeHierarchyInspector.SetTargetComponent(const AValue: TComponent);
begin
  if FTargetComponent <> AValue then
  begin
    if Assigned(FTargetComponent) then
      FTargetComponent.RemoveFreeNotification(Self);

    FTargetComponent := AValue;

    if Assigned(FTargetComponent) then
      FTargetComponent.FreeNotification(Self);
  end;
end;

procedure TDlpTypeHierarchyInspector.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  { Proteção contra referências pendentes ao deletar componentes no form designer }
  if (Operation = opRemove) and (AComponent = FTargetComponent) then
    FTargetComponent := nil;
end;

function TDlpTypeHierarchyInspector.VisibilityToString(AVis: TMemberVisibility): string;
begin
  case AVis of
    mvPrivate:   Result := 'private';
    mvProtected: Result := 'protected';
    mvPublic:    Result := 'public';
    mvPublished: Result := 'published';
  else
    Result := 'unknown';
  end;
end;

function TDlpTypeHierarchyInspector.GetClassAncestry(AInstance: TObject): TStrings;
var
  CurrentObj: TObject;
  CurrentClass: TClass;
  Depth: Integer;
  ShouldStop: Boolean;
begin
  Result := TStringList.Create;
  try
    CurrentObj := AInstance;
    if not Assigned(CurrentObj) then
      CurrentObj := FTargetComponent;

    if not Assigned(CurrentObj) then
    begin
      Result.Add('Nenhum componente ou objeto selecionado para inspeção.');
      Exit;
    end;

    CurrentClass := CurrentObj.ClassType;
    Depth := 0;

    while Assigned(CurrentClass) do
    begin
      Result.Add(Format('[Nível %d] %s (Endereço VMT: %p)',
        [Depth, CurrentClass.ClassName, Pointer(CurrentClass)]));

      if Assigned(FOnClassNodeFound) then
        FOnClassNodeFound(Self, CurrentClass.ClassName, CurrentClass, Depth);

      Inc(Depth);

      ShouldStop := False;
      case FInspectionDepth of
        idImmediateOnly:
          ShouldStop := True;
        idUntilComponent:
          if CurrentClass = TComponent then
            ShouldStop := True;
        idFullToTObject:
          if CurrentClass = TObject then
            ShouldStop := True;
      end;

      if ShouldStop then
        Break;

      CurrentClass := CurrentClass.ClassParent;
    end;
  except
    on E: Exception do
      Result.Add('Falha durante introspecção de classe: ' + E.Message);
  end;
end;

function TDlpTypeHierarchyInspector.GetExtendedProperties(AInstance: TObject): TDlpPropertyExtendedMetaArray;
var
  CurrentObj: TObject;
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  RttiAttr: TCustomAttribute;
  List: TList<TDlpPropertyExtendedMeta>;
  Meta: TDlpPropertyExtendedMeta;
  AttrSb: TStringBuilder;
  I: Integer;
begin
  CurrentObj := AInstance;
  if not Assigned(CurrentObj) then
    CurrentObj := FTargetComponent;

  if not Assigned(CurrentObj) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  List := TList<TDlpPropertyExtendedMeta>.Create;
  AttrSb := TStringBuilder.Create;
  try
    RttiContext := TRttiContext.Create;
    try
      RttiType := RttiContext.GetType(CurrentObj.ClassType);
      if Assigned(RttiType) then
      begin
        for RttiProp in RttiType.GetProperties do
        begin
          if (not FIncludePrivateProps) and (RttiProp.Visibility in [mvPrivate, mvProtected]) then
            Continue;

          Meta.PropName := RttiProp.Name;
          if Assigned(RttiProp.PropertyType) then
            Meta.TypeName := RttiProp.PropertyType.Name
          else
            Meta.TypeName := 'UnknownType';

          Meta.Visibility := VisibilityToString(RttiProp.Visibility);
          Meta.IsReadable := RttiProp.IsReadable;
          Meta.IsWritable := RttiProp.IsWritable;

          { Inspeciona Atributos Customizados da propriedade }
          AttrSb.Clear;
          Meta.CustomAttributeCount := Length(RttiProp.GetAttributes);
          for RttiAttr in RttiProp.GetAttributes do
          begin
            if AttrSb.Length > 0 then
              AttrSb.Append(', ');
            AttrSb.Append(RttiAttr.ClassName);
          end;
          Meta.AttributesSummary := AttrSb.ToString;

          List.Add(Meta);

          if Assigned(FOnPropertyInspected) then
            FOnPropertyInspected(Self, Meta);
        end;
      end;
    finally
      RttiContext.Free;
    end;

    Result := List.ToArray;
  finally
    AttrSb.Free;
    List.Free;
  end;
end;

function BoolToStrCustom(AValue: Boolean; const ATrueStr, AFalseStr: string): string;
begin
  if AValue then
    Result := ATrueStr
  else
    Result := AFalseStr;
end;

function TDlpTypeHierarchyInspector.GenerateMarkdownDocumentation(AInstance: TObject): string;
var
  CurrentObj: TObject;
  Ancestry: TStrings;
  Props: TDlpPropertyExtendedMetaArray;
  SB: TStringBuilder;
  I: Integer;
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiAttr: TCustomAttribute;
begin
  CurrentObj := AInstance;
  if not Assigned(CurrentObj) then
    CurrentObj := FTargetComponent;

  if not Assigned(CurrentObj) then
    Exit('**Erro**: Nenhum componente ou objeto alvo atribuído.');

  SB := TStringBuilder.Create;
  Ancestry := nil;
  try
    SB.AppendLine(Format('### Documentação Técnica RTTI: `%s`', [CurrentObj.ClassName]));
    SB.AppendLine('');

    { Exibe atributos customizados da própria classe }
    RttiContext := TRttiContext.Create;
    try
      RttiType := RttiContext.GetType(CurrentObj.ClassType);
      if Assigned(RttiType) then
      begin
        SB.AppendLine('#### Atributos da Classe:');
        for RttiAttr in RttiType.GetAttributes do
        begin
          if RttiAttr is ComponentDocAttribute then
          begin
            SB.AppendLine(Format('- **Descricão**: %s (Versão: `%s`)',
              [ComponentDocAttribute(RttiAttr).Description, ComponentDocAttribute(RttiAttr).Version]));
          end
          else
          begin
            SB.AppendLine(Format('- **Atributo**: `%s`', [RttiAttr.ClassName]));
          end;
        end;
        SB.AppendLine('');
      end;
    finally
      RttiContext.Free;
    end;

    SB.AppendLine('#### 1. Árvore Genealógica de Herança:');
    SB.AppendLine('```text');
    Ancestry := GetClassAncestry(CurrentObj);
    for I := 0 to Ancestry.Count - 1 do
      SB.AppendLine(Ancestry[I]);
    SB.AppendLine('```');
    SB.AppendLine('');

    SB.AppendLine('#### 2. Propriedades Inspecionadas via Enhanced RTTI:');
    SB.AppendLine('');
    SB.AppendLine('| Propriedade | Tipo | Visibilidade | Leitura | Escrita | Atributos Customizados |');
    SB.AppendLine('| :--- | :--- | :---: | :---: | :---: | :--- |');

    Props := GetExtendedProperties(CurrentObj);
    for I := Low(Props) to High(Props) do
    begin
      SB.AppendLine(Format('| `%s` | `%s` | `%s` | %s | %s | %s |', [
        Props[I].PropName,
        Props[I].TypeName,
        Props[I].Visibility,
        BoolToStrCustom(Props[I].IsReadable, 'Sim', 'Não'),
        BoolToStrCustom(Props[I].IsWritable, 'Sim', 'Não'),
        Props[I].AttributesSummary
      ]));
    end;

    Result := SB.ToString;
  finally
    Ancestry.Free;
    SB.Free;
  end;
end;

end.
