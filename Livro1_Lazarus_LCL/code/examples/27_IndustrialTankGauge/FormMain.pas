unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LazIndustrialTankGauge;

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
    FVisualComp: TLazIndustrialTankGauge;
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
  LogMessage('Iniciando exemplo do Módulo 27: TLazIndustrialTankGauge...');
  FVisualComp := TLazIndustrialTankGauge.Create(Self);
  FVisualComp.Parent := PnlContainer;
  FVisualComp.SetBounds(20, 20, 160, 260);
  FVisualComp.Capacity := 10000;
  FVisualComp.CurrentLevel := 6500;
  FVisualComp.UnitOfMeasure := 'LITROS';
  LogMessage('TLazIndustrialTankGauge instanciado e configurado com sucesso.');
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
  FVisualComp.CurrentLevel := Random(9000) + 500;
  LogMessage('TLazIndustrialTankGauge: Nível atualizado para ' + FloatToStr(FVisualComp.CurrentLevel) + ' L.');
end;

end.
