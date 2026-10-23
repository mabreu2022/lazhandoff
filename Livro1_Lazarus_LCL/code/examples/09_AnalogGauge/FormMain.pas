unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LazAnalogGauge;

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
    FVisualComp: TLazAnalogGauge;
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
  LogMessage('Iniciando exemplo do Módulo 09: TLazAnalogGauge...');
  FVisualComp := TLazAnalogGauge.Create(Self);
  FVisualComp.Parent := PnlContainer;
  FVisualComp.SetBounds(20, 20, 240, 240);
  FVisualComp.GaugeTitle := 'PRESSÃO';
  FVisualComp.UnitLabel := 'BAR';
  FVisualComp.MinValue := 0;
  FVisualComp.MaxValue := 100;
  FVisualComp.Value := 65.5;
  LogMessage('TLazAnalogGauge instanciado e configurado com sucesso.');
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
  FVisualComp.Value := Random(100);
  LogMessage('TLazAnalogGauge: Valor atualizado para ' + FloatToStr(FVisualComp.Value) + ' BAR.');
end;

end.
