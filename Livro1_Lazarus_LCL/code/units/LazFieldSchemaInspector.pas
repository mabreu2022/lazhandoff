{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 17: Engenharia de Arrastar e Soltar (Drag & Drop) no Designer
  Componente / Motor: LazFieldSchemaInspector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Motor de introspecção de metadados de esquemas relacionais,
             extração de TFieldDefs e mapeamento determinístico para controles
             visuais da LCL.
==============================================================================}
unit LazFieldSchemaInspector;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  DB;

type
  { Classificação semântica do controle visual sugerido para o campo }
  TLazControlKind = (
    ckTextEdit,      // TDBEdit (Strings curtas, identificadores)
    ckNumberEdit,    // TLazDBNumberEdit (Moeda, valores decimais, inteiros)
    ckDatePicker,    // TDateTimePicker / TDBDateEdit (Datas e timestamps)
    ckCheckBox,      // TDBCheckBox (Booleanos, flags 0/1)
    ckMemo,          // TDBMemo (Textos longos, observações)
    ckImageBlob,     // TDBImage / Foto (Binários de imagem)
    ckTagLookup      // TLazDBLookupTagBox (Chaves multivaloradas / Foreign Keys)
  );

  { Registro de especificação do campo inspecionado }
  TLazFieldSchemaItem = record
    FieldName: string;
    FieldType: TFieldType;
    Size: Integer;
    Required: Boolean;
    DisplayLabel: string;
    RecommendedControl: TLazControlKind;
    SuggestedWidth: Integer;
    SuggestedHeight: Integer;
  end;

  TLazFieldSchemaArray = array of TLazFieldSchemaItem;

  {============================================================================
    Classe: TLazFieldSchemaInspector
    Motor não-visual de análise de esquemas relacionais
  ============================================================================}
  TLazFieldSchemaInspector = class(TComponent)
  private
    FDataSet: TDataSet;
    procedure SetDataSet(const AValue: TDataSet);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    { Executa a introspecção completa do esquema do DataSet vinculado }
    function InspectSchema: TLazFieldSchemaArray;

    { Mapeia um tipo específico de TFieldType para a categoria de controle recomendada }
    class function ResolveControlKind(AFieldType: TFieldType; ASize: Integer): TLazControlKind;
    class function ControlKindToString(AKind: TLazControlKind): string;
  published
    property DataSet: TDataSet read FDataSet write SetDataSet;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazFieldSchemaInspector]);
end;

{ TLazFieldSchemaInspector }

constructor TLazFieldSchemaInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataSet := nil;
end;

procedure TLazFieldSchemaInspector.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDataSet) then
    FDataSet := nil;
end;

procedure TLazFieldSchemaInspector.SetDataSet(const AValue: TDataSet);
begin
  if FDataSet <> AValue then
  begin
    FDataSet := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
  end;
end;

class function TLazFieldSchemaInspector.ResolveControlKind(
  AFieldType: TFieldType; ASize: Integer): TLazControlKind;
begin
  case AFieldType of
    ftString, ftFixedChar, ftWideString, ftFixedWideChar:
    begin
      if ASize > 255 then
        Result := ckMemo
      else
        Result := ckTextEdit;
    end;

    ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD, ftLargeint, ftFMTBcd:
      Result := ckNumberEdit;

    ftDate, ftTime, ftDateTime, ftTimeStamp:
      Result := ckDatePicker;

    ftBoolean:
      Result := ckCheckBox;

    ftBlob, ftGraphic, ftParadoxOle, ftDBaseOle:
      Result := ckImageBlob;

    ftMemo, ftWideMemo:
      Result := ckMemo;

    else
      Result := ckTextEdit;
  end;
end;

class function TLazFieldSchemaInspector.ControlKindToString(AKind: TLazControlKind): string;
begin
  case AKind of
    ckTextEdit:   Result := 'TDBEdit';
    ckNumberEdit: Result := 'TLazDBNumberEdit';
    ckDatePicker: Result := 'TDBDateEdit';
    ckCheckBox:   Result := 'TDBCheckBox';
    ckMemo:       Result := 'TDBMemo';
    ckImageBlob:  Result := 'TDBImage';
    ckTagLookup:  Result := 'TLazDBLookupTagBox';
  end;
end;

function TLazFieldSchemaInspector.InspectSchema: TLazFieldSchemaArray;
var
  i, TotalFields: Integer;
  FieldObj: TField;
  Kind: TLazControlKind;
begin
  SetLength(Result, 0);
  if FDataSet = nil then
    Exit;

  // Garante que os metadados de campos estejam disponíveis
  if not FDataSet.Active and (FDataSet.FieldDefs.Count = 0) then
  begin
    try
      FDataSet.FieldDefs.Update;
    except
      { Se o dataset não puder carregar os FieldDefs desconectado, sai com array vazio }
      Exit;
    end;
  end;

  if FDataSet.Fields.Count > 0 then
  begin
    TotalFields := FDataSet.Fields.Count;
    SetLength(Result, TotalFields);

    for i := 0 to TotalFields - 1 do
    begin
      FieldObj := FDataSet.Fields[i];
      Kind := ResolveControlKind(FieldObj.DataType, FieldObj.Size);

      Result[i].FieldName := FieldObj.FieldName;
      Result[i].FieldType := FieldObj.DataType;
      Result[i].Size := FieldObj.Size;
      Result[i].Required := FieldObj.Required;
      Result[i].DisplayLabel := FieldObj.DisplayLabel;
      Result[i].RecommendedControl := Kind;

      // Sugestões de layout inicial
      case Kind of
        ckTextEdit:
        begin
          Result[i].SuggestedWidth := 200;
          Result[i].SuggestedHeight := 24;
        end;
        ckNumberEdit:
        begin
          Result[i].SuggestedWidth := 130;
          Result[i].SuggestedHeight := 24;
        end;
        ckDatePicker:
        begin
          Result[i].SuggestedWidth := 120;
          Result[i].SuggestedHeight := 24;
        end;
        ckCheckBox:
        begin
          Result[i].SuggestedWidth := 160;
          Result[i].SuggestedHeight := 24;
        end;
        ckMemo:
        begin
          Result[i].SuggestedWidth := 350;
          Result[i].SuggestedHeight := 70;
        end;
        ckImageBlob:
        begin
          Result[i].SuggestedWidth := 160;
          Result[i].SuggestedHeight := 140;
        end;
        ckTagLookup:
        begin
          Result[i].SuggestedWidth := 280;
          Result[i].SuggestedHeight := 42;
        end;
      end;
    end;
  end
  else if FDataSet.FieldDefs.Count > 0 then
  begin
    // Inspeção alternativa baseada em TFieldDefs
    TotalFields := FDataSet.FieldDefs.Count;
    SetLength(Result, TotalFields);

    for i := 0 to TotalFields - 1 do
    begin
      Kind := ResolveControlKind(FDataSet.FieldDefs[i].DataType, FDataSet.FieldDefs[i].Size);

      Result[i].FieldName := FDataSet.FieldDefs[i].Name;
      Result[i].FieldType := FDataSet.FieldDefs[i].DataType;
      Result[i].Size := FDataSet.FieldDefs[i].Size;
      Result[i].Required := (faRequired in FDataSet.FieldDefs[i].Attributes);
      Result[i].DisplayLabel := FDataSet.FieldDefs[i].Name;
      Result[i].RecommendedControl := Kind;
      Result[i].SuggestedWidth := 200;
      Result[i].SuggestedHeight := 24;
    end;
  end;
end;

end.
