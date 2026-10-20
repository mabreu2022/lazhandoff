{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 06: Property Editors Customizados
  Componente: TLazJsonConfig
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Componente não-visual para armazenamento de configurações JSON
             estruturadas, demonstrando a integração com Property Editors
             customizados (dropdown de presets e diálogo modal de edição).
==============================================================================}
unit LazJsonConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpjson,
  jsonparser;

type
  { Evento disparado quando o JSON é atualizado }
  TOnJsonUpdatedEvent = procedure(Sender: TObject; AIsValid: Boolean;
    const AErrorMsg: string) of object;

  {============================================================================
    Classe: TLazJsonConfig
    Componente para gestão de configurações em JSON com validação
  ============================================================================}
  TLazJsonConfig = class(TComponent)
  private
    FJsonContent: string;
    FSelectedPreset: string;
    FSchemaVersion: Integer;
    FPrettyPrint: Boolean;
    FOnJsonUpdated: TOnJsonUpdatedEvent;

    procedure SetJsonContent(const AValue: string);
    procedure SetSelectedPreset(const AValue: string);
    procedure SetPrettyPrint(const AValue: Boolean);
    function FormatJson(const AJsonStr: string): string;
  public
    constructor Create(AOwner: TComponent); override;

    { Validação da estrutura JSON }
    function ValidateJson(out AErrorMessage: string): Boolean;
    function GetAvailablePresets: TStringList;
    procedure ApplyPreset(const APresetName: string);
  published
    property JsonContent: string read FJsonContent write SetJsonContent;
    property SelectedPreset: string read FSelectedPreset write SetSelectedPreset;
    property SchemaVersion: Integer read FSchemaVersion write FSchemaVersion default 1;
    property PrettyPrint: Boolean read FPrettyPrint write SetPrettyPrint default True;
    property OnJsonUpdated: TOnJsonUpdatedEvent read FOnJsonUpdated write FOnJsonUpdated;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazJsonConfig]);
end;

{ TLazJsonConfig }

constructor TLazJsonConfig.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSchemaVersion := 1;
  FPrettyPrint := True;
  FSelectedPreset := 'Padrão Vazio';
  FJsonContent := '{\n  "app": "LazarusEngine",\n  "version": "1.0",\n  "active": true\n}';
end;

function TLazJsonConfig.FormatJson(const AJsonStr: string): string;
var
  Data: TJSONData;
begin
  Result := AJsonStr;
  try
    Data := GetJSON(AJsonStr);
    try
      if FPrettyPrint then
        Result := Data.FormatJSON()
      else
        Result := Data.AsJSON;
    finally
      Data.Free;
    end;
  except
    { Se não for JSON válido, preserva o texto bruto }
  end;
end;

procedure TLazJsonConfig.SetJsonContent(const AValue: string);
var
  ErrMsg: string;
  IsValid: Boolean;
begin
  if FJsonContent <> AValue then
  begin
    FJsonContent := AValue;
    IsValid := ValidateJson(ErrMsg);
    if IsValid and FPrettyPrint then
      FJsonContent := FormatJson(FJsonContent);

    if Assigned(FOnJsonUpdated) then
      FOnJsonUpdated(Self, IsValid, ErrMsg);
  end;
end;

procedure TLazJsonConfig.SetSelectedPreset(const AValue: string);
begin
  if FSelectedPreset <> AValue then
  begin
    FSelectedPreset := AValue;
    ApplyPreset(FSelectedPreset);
  end;
end;

procedure TLazJsonConfig.SetPrettyPrint(const AValue: Boolean);
begin
  if FPrettyPrint <> AValue then
  begin
    FPrettyPrint := AValue;
    if FPrettyPrint then
      FJsonContent := FormatJson(FJsonContent);
  end;
end;

function TLazJsonConfig.ValidateJson(out AErrorMessage: string): Boolean;
var
  Data: TJSONData;
begin
  AErrorMessage := '';
  try
    Data := GetJSON(FJsonContent);
    try
      Result := True;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
    begin
      Result := False;
      AErrorMessage := E.Message;
    end;
  end;
end;

function TLazJsonConfig.GetAvailablePresets: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('Padrão Vazio');
  Result.Add('Configuração de Banco de Dados');
  Result.Add('Perfil de API REST');
  Result.Add('Opções de Interface');
end;

procedure TLazJsonConfig.ApplyPreset(const APresetName: string);
begin
  if APresetName = 'Configuração de Banco de Dados' then
    JsonContent := '{\n  "host": "localhost",\n  "port": 5432,\n  "database": "corp_db",\n  "poolSize": 20\n}'
  else if APresetName = 'Perfil de API REST' then
    JsonContent := '{\n  "endpoint": "https://api.empresa.com/v1",\n  "timeout": 5000,\n  "retries": 3\n}'
  else if APresetName = 'Opções de Interface' then
    JsonContent := '{\n  "theme": "Dark",\n  "fontSize": 12,\n  "animationsEnabled": true\n}'
  else
    JsonContent := '{\n  "app": "LazarusEngine",\n  "version": "1.0",\n  "active": true\n}';
end;

end.
