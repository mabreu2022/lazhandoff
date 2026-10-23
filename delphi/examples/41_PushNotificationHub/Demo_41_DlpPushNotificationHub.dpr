program Demo_41_DlpPushNotificationHub;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_41_DlpPushNotificationHub';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
