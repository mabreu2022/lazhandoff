program Demo_39_DlpEmbeddedWebhookServer;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_39_DlpEmbeddedWebhookServer';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
