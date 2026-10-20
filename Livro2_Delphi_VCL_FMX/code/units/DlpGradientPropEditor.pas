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
  TDlpGradientPresetPropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  {============================================================================
    Editor 2: Diálogo Modal de Customização de Gradiente (paDialog)
  ============================================================================}
  TDlpGradientModalPropertyEditor = class(TStringProperty)
  private
    FSelectedStart: TColor;
    FSelectedEnd: TColor;
    FPreviewPanel: TDlpGradientHeader;
    FColorDlg: TColorDialog;
    procedure HandleStartColorClick(Sender: TObject);
    procedure HandleEndColorClick(Sender: TObject);
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

procedure TDlpGradientModalPropertyEditor.HandleStartColorClick(Sender: TObject);
begin
  FColorDlg.Color := FSelectedStart;
  if FColorDlg.Execute then
  begin
    FSelectedStart := FColorDlg.Color;
    if Assigned(FPreviewPanel) then
      FPreviewPanel.StartColor := FSelectedStart;
  end;
end;

procedure TDlpGradientModalPropertyEditor.HandleEndColorClick(Sender: TObject);
begin
  FColorDlg.Color := FSelectedEnd;
  if FColorDlg.Execute then
  begin
    FSelectedEnd := FColorDlg.Color;
    if Assigned(FPreviewPanel) then
      FPreviewPanel.EndColor := FSelectedEnd;
  end;
end;

procedure TDlpGradientModalPropertyEditor.Edit;
var
  Dlg: TForm;
  BtnOk, BtnCancel, BtnStartColor, BtnEndColor: TButton;
  HeaderComp: TDlpGradientHeader;
begin
  HeaderComp := TDlpGradientHeader(GetComponent(0));
  if not Assigned(HeaderComp) then
    Exit;

  FSelectedStart := HeaderComp.StartColor;
  FSelectedEnd := HeaderComp.EndColor;

  Dlg := TForm.Create(nil);
  try
    FColorDlg := TColorDialog.Create(Dlg);
    Dlg.Caption := 'Editor Avançado de Gradiente - Delphi 12 Athens';
    Dlg.Width := 520;
    Dlg.Height := 280;
    Dlg.Position := poScreenCenter;
    Dlg.Color := $00242424;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;
    Dlg.Font.Color := clWhite;

    { Preview visual em tempo real dentro do diálogo modal }
    FPreviewPanel := TDlpGradientHeader.Create(Dlg);
    FPreviewPanel.Parent := Dlg;
    FPreviewPanel.Left := 20;
    FPreviewPanel.Top := 20;
    FPreviewPanel.Width := 460;
    FPreviewPanel.Height := 80;
    FPreviewPanel.StartColor := FSelectedStart;
    FPreviewPanel.EndColor := FSelectedEnd;
    FPreviewPanel.TitleText := 'Preview do Gradiente';
    FPreviewPanel.SubtitleText := 'Edição interativa em Design-Time';

    { Botão de Seleção da Cor Inicial }
    BtnStartColor := TButton.Create(Dlg);
    BtnStartColor.Parent := Dlg;
    BtnStartColor.Left := 20;
    BtnStartColor.Top := 120;
    BtnStartColor.Width := 140;
    BtnStartColor.Height := 32;
    BtnStartColor.Caption := 'Cor Inicial...';
    BtnStartColor.OnClick := HandleStartColorClick;

    { Botão de Seleção da Cor Final }
    BtnEndColor := TButton.Create(Dlg);
    BtnEndColor.Parent := Dlg;
    BtnEndColor.Left := 180;
    BtnEndColor.Top := 120;
    BtnEndColor.Width := 140;
    BtnEndColor.Height := 32;
    BtnEndColor.Caption := 'Cor Final...';
    BtnEndColor.OnClick := HandleEndColorClick;

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
      HeaderComp.StartColor := FSelectedStart;
      HeaderComp.EndColor := FSelectedEnd;
      SetStrValue(Format('#%0.6X -> #%0.6X', [FSelectedStart, FSelectedEnd]));
      Designer.Modified;
    end;
  finally
    FPreviewPanel := nil;
    FColorDlg := nil;
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
