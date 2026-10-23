unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LazCustomTabBar;

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
    FVisualComp: TLazCustomTabBar;
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
  LogMessage('Iniciando exemplo do Módulo 11: TLazCustomTabBar...');
  FVisualComp := TLazCustomTabBar.Create(Self);
  FVisualComp.Parent := PnlContainer;
  FVisualComp.Align := alTop;
  FVisualComp.Height := 42;
  FVisualComp.Tabs.AddTab('Principal', -1, False);
  FVisualComp.Tabs.AddTab('Alertas [3]', -1, True);
  FVisualComp.Tabs.AddTab('Relatórios', -1, True);
  LogMessage('TLazCustomTabBar instanciado e configurado com sucesso.');
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
  FVisualComp.Tabs.AddTab('Nova Aba [' + IntToStr(FVisualComp.Tabs.Count + 1) + ']', -1, True);
  LogMessage('TLazCustomTabBar: Nova aba inserida na coleção tipada.');
end;

end.
