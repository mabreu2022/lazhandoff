program Demo_46_DlpSystemMetricsProbe;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_46_DlpSystemMetricsProbe';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
