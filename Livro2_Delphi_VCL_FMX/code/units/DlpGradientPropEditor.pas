{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 06: Property Editors Customizados
  Unidade: DlpGradientPropEditor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (DesignIntf / DesignEditors)
  Descrição: Unidade de Design-Time que implementa Property Editors para o
             Object Inspector do Delphi:
             1. TDlpGradientPresetPropertyEditor (paValueList)
             2. TDlpGradientModalPropertyEditor (paDialog) com preview ao vivo.
==============================================================================}
unit DlpGradientPropEditor;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Dialogs,
  Vcl.Graphics,
  DesignIntf,
  DesignEditors,
  DlpGradientHeader;

type
  {============================================================================
    Editor 1: Dropdown de Presets no Object Inspector (paValueList)
  ============================================================================}
  TDlpGradientPresetPropertyEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  {============================================================================
    Editor 2: Diálogo Modal de Customização de Gradiente (paDialog)
  ============================================================================}
  TDlpGradientModalPropertyEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

procedure Register;

implementation

{ TDlpGradientPresetPropertyEditor }

function TDlpGradientPresetPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList];
end;

procedure TDlpGradientPresetPropertyEditor.GetValues(Proc: TGetStrProc);
var
  HeaderComp: TDlpGradientHeader;
  PresetName: string;
begin
  if GetComponent(0) is TDlpGradientHeader then
  begin
    HeaderComp := TDlpGradientHeader(GetComponent(0));
    for PresetName in HeaderComp.GetAvailablePresets do
      Proc(PresetName);
  end;
end;

{ TDlpGradientModalPropertyEditor }

function TDlpGradientModalPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog];
end;

procedure TDlpGradientModalPropertyEditor.Edit;
var
  Dlg: TForm;
  PreviewPanel: TDlpGradientHeader;
  BtnOk, BtnCancel, BtnStartColor, BtnEndColor: TButton;
  ColorDlg: TColorDialog;
  HeaderComp: TDlpGradientHeader;
  SelectedStart, SelectedEnd: TColor;
begin
  HeaderComp := TDlpGradientHeader(GetComponent(0));
  if not Assigned(HeaderComp) then
    Exit;

  SelectedStart := HeaderComp.StartColor;
  SelectedEnd := HeaderComp.EndColor;

  Dlg := TForm.Create(nil);
  ColorDlg := TColorDialog.Create(Dlg);
  try
    Dlg.Caption := 'Editor Avançado de Gradiente - Delphi 12 Athens';
    Dlg.Width := 520;
    Dlg.Height := 280;
    Dlg.Position := poScreenCenter;
    Dlg.Color := $00242424;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;
    Dlg.Font.Color := clWhite;

    { Preview visual em tempo real dentro do diálogo modal }
    PreviewPanel := TDlpGradientHeader.Create(Dlg);
    PreviewPanel.Parent := Dlg;
    PreviewPanel.Left := 20;
    PreviewPanel.Top := 20;
    PreviewPanel.Width := 460;
    PreviewPanel.Height := 80;
    PreviewPanel.StartColor := SelectedStart;
    PreviewPanel.EndColor := SelectedEnd;
    PreviewPanel.TitleText := 'Preview do Gradiente';
    PreviewPanel.SubtitleText := 'Edição interativa em Design-Time';

    { Botão de Seleção da Cor Inicial }
    BtnStartColor := TButton.Create(Dlg);
    BtnStartColor.Parent := Dlg;
    BtnStartColor.Left := 20;
    BtnStartColor.Top := 120;
    BtnStartColor.Width := 140;
    BtnStartColor.Height := 32;
    BtnStartColor.Caption := 'Cor Inicial...';
    BtnStartColor.OnClick :=
      procedure(Sender: TObject)
      begin
        ColorDlg.Color := SelectedStart;
        if ColorDlg.Execute then
        begin
          SelectedStart := ColorDlg.Color;
          PreviewPanel.StartColor := SelectedStart;
        end;
      end;

    { Botão de Seleção da Cor Final }
    BtnEndColor := TButton.Create(Dlg);
    BtnEndColor.Parent := Dlg;
    BtnEndColor.Left := 180;
    BtnEndColor.Top := 120;
    BtnEndColor.Width := 140;
    BtnEndColor.Height := 32;
    BtnEndColor.Caption := 'Cor Final...';
    BtnEndColor.OnClick :=
      procedure(Sender: TObject)
      begin
        ColorDlg.Color := SelectedEnd;
        if ColorDlg.Execute then
        begin
          SelectedEnd := ColorDlg.Color;
          PreviewPanel.EndColor := SelectedEnd;
        end;
      end;

    { Botões de Ação }
    BtnOk := TButton.Create(Dlg);
    BtnOk.Parent := Dlg;
    BtnOk.Left := 280;
    BtnOk.Top := 190;
    BtnOk.Width := 95;
    BtnOk.Height := 32;
    BtnOk.Caption := 'Aplicar';
    BtnOk.ModalResult := mrOk;

    BtnCancel := TButton.Create(Dlg);
    BtnCancel.Parent := Dlg;
    BtnCancel.Left := 385;
    BtnCancel.Top := 190;
    BtnCancel.Width := 95;
    BtnCancel.Height := 32;
    BtnCancel.Caption := 'Cancelar';
    BtnCancel.ModalResult := mrCancel;

    if Dlg.ShowModal = mrOk then
    begin
      HeaderComp.StartColor := SelectedStart;
      HeaderComp.EndColor := SelectedEnd;
      SetStrValue(Format('#%0.6X -> #%0.6X', [SelectedStart, SelectedEnd]));
      Designer.Modified;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(string), TDlpGradientHeader, 'PresetName',
    TDlpGradientPresetPropertyEditor);

  RegisterPropertyEditor(TypeInfo(string), TDlpGradientHeader, 'TitleText',
    TDlpGradientModalPropertyEditor);
end;

end.
