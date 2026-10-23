program Demo_09_DlpAnalogGauge;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_09_DlpAnalogGauge';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
