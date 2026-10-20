{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 17: Engenharia de Arrastar e Soltar (Drag & Drop) no Designer
  Componente / Motor: DlpFieldSchemaInspector
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL
  Descrição: Motor corporativo de introspecção de metadados relacionais,
             extração de TFieldDefs em FireDAC e mapeamento algorítmico
             para controles visuais da VCL.
==============================================================================}
unit DlpFieldSchemaInspector;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB;

type
  /// <summary>
  /// Classificação semântica do controle visual sugerido para o campo de banco de dados.
  /// </summary>
  TDlpControlKind = (
    ckTextEdit,      // TDBEdit (Strings curtas, identificadores alfanuméricos)
    ckNumberEdit,    // TDlpDBNumberEdit (Moeda, valores decimais, numéricos)
    ckDatePicker,    // TDateTimePicker (Datas, horas e timestamps)
    ckCheckBox,      // TDBCheckBox (Valores booleanos e flags)
    ckMemo,          // TDBMemo (Textos longos e observações)
    ckImageBlob,     // TDBImage (Imagens e binários gráficos)
    ckTagLookup      // TDlpDBLookupTagBox (Chaves multivaloradas / Foreign Keys)
  );

  /// <summary>
  /// Estrutura de dados contendo as características do campo inspecionado.
  /// </summary>
  TDlpFieldSchemaItem = record
    FieldName: string;
    FieldType: TFieldType;
    Size: Integer;
    Required: Boolean;
    DisplayLabel: string;
    RecommendedControl: TDlpControlKind;
    SuggestedWidth: Integer;
    SuggestedHeight: Integer;
  end;

  /// <summary>
  /// Array dinâmico com a relação de campos do esquema analisado.
  /// </summary>
  TDlpFieldSchemaArray = TArray<TDlpFieldSchemaItem>;

  /// <summary>
  /// Motor não-visual de análise de esquemas de datasets e mapeamento de controles.
  /// </summary>
  TDlpFieldSchemaInspector = class(TComponent)
  private
    FDataSet: TDataSet;
    procedure SetDataSet(const AValue: TDataSet);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    /// <summary>
    /// Realiza a inspeção profunda de metadados do dataset vinculado.
    /// </summary>
    function InspectSchema: TDlpFieldSchemaArray;

    /// <summary>
    /// Resolve o tipo de controle visual ideal baseado no TFieldType e tamanho.
    /// </summary>
    class function ResolveControlKind(AFieldType: TFieldType; ASize: Integer): TDlpControlKind;

    /// <summary>
    /// Retorna o nome da classe VCL em formato textual.
    /// </summary>
    class function ControlKindToString(AKind: TDlpControlKind): string;
  published
    property DataSet: TDataSet read FDataSet write SetDataSet;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Component Engineering', [TDlpFieldSchemaInspector]);
end;

{ TDlpFieldSchemaInspector }

constructor TDlpFieldSchemaInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataSet := nil;
end;

procedure TDlpFieldSchemaInspector.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDataSet) then
    FDataSet := nil;
end;

procedure TDlpFieldSchemaInspector.SetDataSet(const AValue: TDataSet);
begin
  if FDataSet <> AValue then
  begin
    FDataSet := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
  end;
end;

class function TDlpFieldSchemaInspector.ResolveControlKind(
  AFieldType: TFieldType; ASize: Integer): TDlpControlKind;
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

class function TDlpFieldSchemaInspector.ControlKindToString(AKind: TDlpControlKind): string;
begin
  case AKind of
    ckTextEdit:   Result := 'TDBEdit';
    ckNumberEdit: Result := 'TDlpDBNumberEdit';
    ckDatePicker: Result := 'TDateTimePicker';
    ckCheckBox:   Result := 'TDBCheckBox';
    ckMemo:       Result := 'TDBMemo';
    ckImageBlob:  Result := 'TDBImage';
    ckTagLookup:  Result := 'TDlpDBLookupTagBox';
  end;
end;

function TDlpFieldSchemaInspector.InspectSchema: TDlpFieldSchemaArray;
var
  i, TotalFields: Integer;
  FieldObj: TField;
  Kind: TDlpControlKind;
begin
  SetLength(Result, 0);
  if FDataSet = nil then
    Exit;

  // Atualiza FieldDefs caso o dataset esteja inativo
  if not FDataSet.Active and (FDataSet.FieldDefs.Count = 0) then
  begin
    try
      FDataSet.FieldDefs.Update;
    except
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
