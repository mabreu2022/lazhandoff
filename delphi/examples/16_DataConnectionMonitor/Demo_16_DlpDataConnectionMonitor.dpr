program Demo_16_DlpDataConnectionMonitor;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_16_DlpDataConnectionMonitor';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
