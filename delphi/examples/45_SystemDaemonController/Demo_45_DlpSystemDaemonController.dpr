program Demo_45_DlpSystemDaemonController;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_45_DlpSystemDaemonController';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
