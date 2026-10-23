unit FormMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  DlpVectorDonutChart;

type
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
    FVisualComp: TDlpVectorDonutChart;
    procedure LogMessage(const Msg: string);
    procedure DummyProc;
  public
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  LogMessage('Iniciando exemplo do Módulo 28: TDlpVectorDonutChart (Delphi)...');
  FVisualComp := TDlpVectorDonutChart.Create(Self);
  FVisualComp.Parent := PnlContainer;
  FVisualComp.SetBounds(20, 20, 280, 240);
  with FVisualComp.Slices.Add do begin Caption := 'A'; Value := 50; Color := clTeal; end;
  with FVisualComp.Slices.Add do begin Caption := 'B'; Value := 30; Color := clNavy; end;
  with FVisualComp.Slices.Add do begin Caption := 'C'; Value := 20; Color := clMaroon; end;
  LogMessage('TDlpVectorDonutChart pronto para uso.');
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
  LogMessage('TDlpVectorDonutChart: Gráfico vetorial polar renderizado.');
end;

end.
