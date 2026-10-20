{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 06: Property Editors Customizados
  Unidade: LazJsonConfigPropEditor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+ (IDEIntf / PropEdits)
  Descrição: Unidade de Design-Time que implementa dois Property Editors:
             1. TLazPresetPropertyEditor: Dropdown dinâmico (paValueList).
             2. TLazJsonModalPropertyEditor: Diálogo modal completo (paDialog)
                com validação sintática em tempo real para o Object Inspector.
==============================================================================}
unit LazJsonConfigPropEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Forms,
  StdCtrls,
  Buttons,
  ExtCtrls,
  Dialogs,
  PropEdits,
  LazJsonConfig;

type
  {============================================================================
    Editor 1: Dropdown de Valores no Object Inspector (paValueList)
  ============================================================================}
  TLazPresetPropertyEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  {============================================================================
    Editor 2: Diálogo Modal de Edição de JSON com Validação (paDialog)
  ============================================================================}
  TLazJsonModalPropertyEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

procedure Register;

implementation

{ TLazPresetPropertyEditor }

function TLazPresetPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  { paValueList transforma o campo em um ComboBox dropdown no Object Inspector }
  Result := [paValueList, paSortList];
end;

procedure TLazPresetPropertyEditor.GetValues(Proc: TGetStrProc);
var
  ConfigComp: TLazJsonConfig;
  Presets: TStringList;
  I: Integer;
begin
  { Obtém a instância do componente atualmente selecionado }
  if GetComponent(0) is TLazJsonConfig then
  begin
    ConfigComp := TLazJsonConfig(GetComponent(0));
    Presets := ConfigComp.GetAvailablePresets;
    try
      for I := 0 to Presets.Count - 1 do
        Proc(Presets[I]);
    finally
      Presets.Free;
    end;
  end;
end;

{ TLazJsonModalPropertyEditor }

function TLazJsonModalPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  { paDialog adiciona o botão com reticências [...] para abrir diálogo modal }
  Result := [paDialog];
end;

procedure TLazJsonModalPropertyEditor.Edit;
var
  ModalDlg: TForm;
  MemoJson: TMemo;
  PanelBottom: TPanel;
  BtnOk, BtnCancel, BtnFormat: TButton;
  LblStatus: TLabel;
  ConfigComp: TLazJsonConfig;
  ErrMsg: string;
begin
  ModalDlg := TForm.Create(nil);
  try
    ModalDlg.Caption := 'Editor Avançado de Configuração JSON - Lazarus IDE';
    ModalDlg.Width := 650;
    ModalDlg.Height := 480;
    ModalDlg.Position := poScreenCenter;
    ModalDlg.Color := $00242424;
    ModalDlg.Font.Name := 'Segoe UI';
    ModalDlg.Font.Size := 10;
    ModalDlg.Font.Color := $00F0F0F0;

    { Painel inferior de ações }
    PanelBottom := TPanel.Create(ModalDlg);
    PanelBottom.Parent := ModalDlg;
    PanelBottom.Align := alBottom;
    PanelBottom.Height := 52;
    PanelBottom.Color := $001A1A1A;
    PanelBottom.BevelOuter := bvNone;

    { Rótulo de status }
    LblStatus := TLabel.Create(ModalDlg);
    LblStatus.Parent := PanelBottom;
    LblStatus.Left := 16;
    LblStatus.Top := 16;
    LblStatus.Caption := 'Sintaxe válida.';
    LblStatus.Font.Color := $0080FF80;

    { Botão Cancelar }
    BtnCancel := TButton.Create(ModalDlg);
    BtnCancel.Parent := PanelBottom;
    BtnCancel.Caption := 'Cancelar';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Width := 90;
    BtnCancel.Height := 32;
    BtnCancel.Left := ModalDlg.ClientWidth - 100;
    BtnCancel.Top := 10;
    BtnCancel.Anchors := [akRight, akBottom];

    { Botão OK }
    BtnOk := TButton.Create(ModalDlg);
    BtnOk.Parent := PanelBottom;
    BtnOk.Caption := 'Aplicar';
    BtnOk.ModalResult := mrOk;
    BtnOk.Width := 90;
    BtnOk.Height := 32;
    BtnOk.Left := ModalDlg.ClientWidth - 200;
    BtnOk.Top := 10;
    BtnOk.Anchors := [akRight, akBottom];

    { Memo central de edição com fonte monoespaçada }
    MemoJson := TMemo.Create(ModalDlg);
    MemoJson.Parent := ModalDlg;
    MemoJson.Align := alClient;
    MemoJson.Font.Name := 'Consolas';
    MemoJson.Font.Size := 10;
    MemoJson.Color := $001E1E1E;
    MemoJson.Font.Color := $00E0E0E0;
    MemoJson.ScrollBars := ssBoth;
    MemoJson.Lines.Text := GetStrValue;

    if ModalDlg.ShowModal = mrOk then
    begin
      { Valida o JSON antes de persistir no Object Inspector }
      ConfigComp := TLazJsonConfig(GetComponent(0));
      if Assigned(ConfigComp) then
      begin
        SetStrValue(MemoJson.Lines.Text);
      end;
    end;
  finally
    ModalDlg.Free;
  end;
end;

procedure Register;
begin
  { Registra o editor de dropdown para a propriedade 'SelectedPreset' }
  RegisterPropertyEditor(TypeInfo(string), TLazJsonConfig, 'SelectedPreset',
    TLazPresetPropertyEditor);

  { Registra o editor de diálogo modal para a propriedade 'JsonContent' }
  RegisterPropertyEditor(TypeInfo(string), TLazJsonConfig, 'JsonContent',
    TLazJsonModalPropertyEditor);
end;

end.
