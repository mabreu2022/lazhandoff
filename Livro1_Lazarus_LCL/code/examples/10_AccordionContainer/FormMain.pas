unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LazAccordionContainer;

type
  { TFrmMain }
  TFrmMain = class(TForm)
    PnlHeader: TPanel;
    LblTitle: TLabel;
    LblSubtitle: TLabel;
    PnlWorkArea: TPanel;
    PnlContainer: TPanel;
    PnlActions: TPanel;
    BtnRunAction: TButton;
    PnlLog: TPanel;
    MemoLog: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure BtnRunActionClick(Sender: TObject);
  private
    FVisualComp: TLazAccordionContainer;
    procedure LogMessage(const Msg: string);
    procedure DummyProc;
  public
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  LogMessage('Iniciando exemplo do Módulo 10: TLazAccordionContainer...');
  FVisualComp := TLazAccordionContainer.Create(Self);
  FVisualComp.Parent := PnlContainer;
  FVisualComp.SetBounds(20, 20, 360, 180);
  FVisualComp.HeaderCaption := '▼ Configurações Gerais (Clique para Alternar)';
  FVisualComp.ExpandedHeight := 180;
  FVisualComp.Collapsed := False;
  LogMessage('TLazAccordionContainer instanciado e configurado com sucesso.');
end;

procedure TFrmMain.LogMessage(const Msg: string);
begin
  MemoLog.Lines.Add(FormatDateTime('[hh:nn:ss.zzz] ', Now) + Msg);
  MemoLog.SelStart := Length(MemoLog.Text);
end;

procedure TFrmMain.DummyProc;
var i: Integer; d: Double;
begin
  d := 1.0;
  for i := 1 to 500 do d := d * 1.0001;
end;

procedure TFrmMain.BtnRunActionClick(Sender: TObject);
begin
  FVisualComp.Collapsed := not FVisualComp.Collapsed;
  LogMessage('TLazAccordionContainer: Estado alternado. Recolhido: ' + BoolToStr(FVisualComp.Collapsed, True));
end;

end.
