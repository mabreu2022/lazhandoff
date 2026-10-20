{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 01: Arquitetura Orientada a Componentes e Hierarquia de Classes
  Componente: TLazTypeInfoInspector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Componente não-visual que inspeciona dinamicamente a árvore
             genealógica de classes e metadados RTTI (propriedades publicadas,
             métodos e tipos) de qualquer objeto ou componente LCL.
==============================================================================}
unit LazTypeInfoInspector;

{$mode objfpc}{$H+}
{$TYPEINFO ON} // Habilita geração explícita de RTTI para a unit

interface

uses
  Classes,
  SysUtils,
  TypInfo;

type
  { Enum para especificar o nível de profundidade da inspeção genealógica }
  TLazInspectionDepth = (
    idImmediateClass,   // Apenas a classe imediata do componente
    idFullHierarchy,    // Até a raiz TObject
    idComponentAncestry // Até a classe TComponent
  );

  { Tipo de registro estruturado para metadados de uma propriedade RTTI }
  TLazPropertyMetadata = record
    PropName: string;
    TypeName: string;
    PropTypeKind: TTypeKind;
    HasGetter: Boolean;
    HasSetter: Boolean;
    IsStored: Boolean;
  end;

  { Array dinâmico de metadados de propriedades }
  TLazPropertyMetadataArray = array of TLazPropertyMetadata;

  { Evento disparado quando um novo nível genealógico é identificado }
  TOnClassDiscovered = procedure(Sender: TObject; const AClassName: string;
    AClassRef: TClass; ADepthLevel: Integer) of object;

  { Evento disparado para cada propriedade RTTI encontrada }
  TOnPropertyDiscovered = procedure(Sender: TObject;
    const AMetadata: TLazPropertyMetadata) of object;

  {============================================================================
    Classe: TLazTypeInfoInspector
    Herda diretamente de TComponent para ter ciclo de vida gerenciado,
    suporte a Owner, visibilidade na Tool Palette e no Object Inspector.
  ============================================================================}
  TLazTypeInfoInspector = class(TComponent)
  private
    FTargetComponent: TComponent;
    FInspectionDepth: TLazInspectionDepth;
    FIncludeInheritedProps: Boolean;
    FOnClassDiscovered: TOnClassDiscovered;
    FOnPropertyDiscovered: TOnPropertyDiscovered;

    procedure SetTargetComponent(const AValue: TComponent);
    function TypeKindToString(AKind: TTypeKind): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos públicos de execução da inspeção }
    function GetAncestryReport(AInstance: TObject = nil): TStrings;
    function GetPublishedProperties(AInstance: TObject = nil): TLazPropertyMetadataArray;
    function GenerateMarkdownSummary(AInstance: TObject = nil): string;
  published
    { Propriedade publicada para selecionar o componente alvo no Object Inspector }
    property TargetComponent: TComponent read FTargetComponent write SetTargetComponent;
    property InspectionDepth: TLazInspectionDepth read FInspectionDepth write FInspectionDepth default idFullHierarchy;
    property IncludeInheritedProps: Boolean read FIncludeInheritedProps write FIncludeInheritedProps default True;

    { Eventos publicados para integração com a UI da aplicação }
    property OnClassDiscovered: TOnClassDiscovered read FOnClassDiscovered write FOnClassDiscovered;
    property OnPropertyDiscovered: TOnPropertyDiscovered read FOnPropertyDiscovered write FOnPropertyDiscovered;
  end;

{ Procedimento oficial de registro na IDE Lazarus }
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazTypeInfoInspector]);
end;

{ TLazTypeInfoInspector }

constructor TLazTypeInfoInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTargetComponent := nil;
  FInspectionDepth := idFullHierarchy;
  FIncludeInheritedProps := True;
end;

destructor TLazTypeInfoInspector.Destroy;
begin
  FTargetComponent := nil;
  inherited Destroy;
end;

procedure TLazTypeInfoInspector.SetTargetComponent(const AValue: TComponent);
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

procedure TLazTypeInfoInspector.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  { Limpeza segura de referência em tempo de design e execução }
  if (Operation = opRemove) and (AComponent = FTargetComponent) then
    FTargetComponent := nil;
end;

function TLazTypeInfoInspector.TypeKindToString(AKind: TTypeKind): string;
begin
  case AKind of
    tkUnknown:      Result := 'Unknown';
    tkInteger:      Result := 'Integer';
    tkChar:         Result := 'Char';
    tkEnumeration:  Result := 'Enumeration';
    tkFloat:        Result := 'Float';
    tkSet:          Result := 'Set';
    tkMethod:       Result := 'Method/Event';
    tkSString:      Result := 'ShortString';
    tkLString:      Result := 'LongString/AnsiString';
    tkAString:      Result := 'AnsiString';
    tkWString:      Result := 'WideString';
    tkVariant:      Result := 'Variant';
    tkArray:        Result := 'Array';
    tkRecord:       Result := 'Record';
    tkInterface:    Result := 'Interface';
    tkClass:        Result := 'Class';
    tkObject:       Result := 'Object';
    tkWChar:        Result := 'WideChar';
    tkBool:         Result := 'Boolean';
    tkInt64:        Result := 'Int64';
    tkQWord:        Result := 'QWord';
    tkDynArray:     Result := 'DynamicArray';
    tkUString:      Result := 'UnicodeString';
    tkUChar:        Result := 'UnicodeChar';
    tkHelper:       Result := 'Helper';
    tkFile:         Result := 'File';
    tkClassRef:     Result := 'ClassReference';
    tkPointer:      Result := 'Pointer';
  else
    Result := 'CustomType';
  end;
end;

function TLazTypeInfoInspector.GetAncestryReport(AInstance: TObject): TStrings;
var
  CurrentObject: TObject;
  CurrentClass: TClass;
  Depth: Integer;
  ShouldContinue: Boolean;
begin
  Result := TStringList.Create;
  try
    CurrentObject := AInstance;
    if not Assigned(CurrentObject) then
      CurrentObject := FTargetComponent;

    if not Assigned(CurrentObject) then
    begin
      Result.Add('Nenhum objeto alvo especificado para inspeção.');
      Exit;
    end;

    CurrentClass := CurrentObject.ClassType;
    Depth := 0;

    while Assigned(CurrentClass) do
    begin
      Result.Add(Format('[Nível %d] %s (Instância base: %p)',
        [Depth, CurrentClass.ClassName, Pointer(CurrentClass)]));

      if Assigned(FOnClassDiscovered) then
        FOnClassDiscovered(Self, CurrentClass.ClassName, CurrentClass, Depth);

      Inc(Depth);

      ShouldContinue := True;
      case FInspectionDepth of
        idImmediateClass:
          ShouldContinue := False;
        idComponentAncestry:
          if CurrentClass = TComponent then
            ShouldContinue := False;
        idFullHierarchy:
          if CurrentClass = TObject then
            ShouldContinue := False;
      end;

      if not ShouldContinue then
        Break;

      CurrentClass := CurrentClass.ClassParent;
    end;
  except
    on E: Exception do
    begin
      Result.Add('Erro ao inspecionar genealogia: ' + E.Message);
    end;
  end;
end;

function TLazTypeInfoInspector.GetPublishedProperties(AInstance: TObject): TLazPropertyMetadataArray;
var
  CurrentObject: TObject;
  PropList: PPropList;
  PropCount: Integer;
  I: Integer;
  TypeDataPtr: PTypeData;
  PropInfoPtr: PPropInfo;
begin
  SetLength(Result, 0);

  CurrentObject := AInstance;
  if not Assigned(CurrentObject) then
    CurrentObject := FTargetComponent;

  if not Assigned(CurrentObject) then
    Exit;

  PropCount := GetTypeData(CurrentObject.ClassInfo)^.PropCount;
  if PropCount <= 0 then
    Exit;

  GetMem(PropList, PropCount * SizeOf(PPropInfo));
  try
    PropCount := GetPropList(CurrentObject.ClassInfo, tkAny, PropList);
    SetLength(Result, PropCount);

    for I := 0 to PropCount - 1 do
    begin
      PropInfoPtr := PropList^[I];
      TypeDataPtr := GetTypeData(PropInfoPtr^.PropType);

      Result[I].PropName := PropInfoPtr^.Name;
      Result[I].PropTypeKind := PropInfoPtr^.PropType^.Kind;
      Result[I].TypeName := PropInfoPtr^.PropType^.Name;
      Result[I].HasGetter := Assigned(PropInfoPtr^.GetProc);
      Result[I].HasSetter := Assigned(PropInfoPtr^.SetProc);
      Result[I].IsStored := (PropInfoPtr^.StoredProc <> nil);

      if Assigned(FOnPropertyDiscovered) then
        FOnPropertyDiscovered(Self, Result[I]);
    end;
  finally
    FreeMem(PropList);
  end;
end;

function TLazTypeInfoInspector.GenerateMarkdownSummary(AInstance: TObject): string;
var
  AncestryList: TStrings;
  Props: TLazPropertyMetadataArray;
  SB: TStringBuilder;
  I: Integer;
  CurrentObject: TObject;
begin
  CurrentObject := AInstance;
  if not Assigned(CurrentObject) then
    CurrentObject := FTargetComponent;

  if not Assigned(CurrentObject) then
    Exit('**Erro**: Nenhum componente ou objeto alvo atribuído.');

  SB := TStringBuilder.Create;
  AncestryList := nil;
  try
    SB.AppendLine(Format('### Relatório RTTI: %s (Classe: `%s`)',
      [CurrentObject.ToString, CurrentObject.ClassName]));
    SB.AppendLine('');
    SB.AppendLine('#### 1. Árvore Genealógica de Herança:');
    SB.AppendLine('```text');

    AncestryList := GetAncestryReport(CurrentObject);
    for I := 0 to AncestryList.Count - 1 do
      SB.AppendLine(AncestryList[I]);

    SB.AppendLine('```');
    SB.AppendLine('');
    SB.AppendLine('#### 2. Tabela de Propriedades Published:');
    SB.AppendLine('');
    SB.AppendLine('| Propriedade | Tipo Pascal | Categoria RTTI | Leitura (Get) | Escrita (Set) | Persistível |');
    SB.AppendLine('| :--- | :--- | :--- | :---: | :---: | :---: |');

    Props := GetPublishedProperties(CurrentObject);
    for I := Low(Props) to High(Props) do
    begin
      SB.AppendLine(Format('| `%s` | `%s` | %s | %s | %s | %s |', [
        Props[I].PropName,
        Props[I].TypeName,
        TypeKindToString(Props[I].PropTypeKind),
        BoolToStr(Props[I].HasGetter, 'Sim', 'Não'),
        BoolToStr(Props[I].HasSetter, 'Sim', 'Não'),
        BoolToStr(Props[I].IsStored, 'Sim', 'Não')
      ]));
    end;

    Result := SB.ToString;
  finally
    AncestryList.Free;
    SB.Free;
  end;
end;

end.
