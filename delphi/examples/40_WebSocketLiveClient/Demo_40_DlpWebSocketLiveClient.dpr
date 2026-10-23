program Demo_40_DlpWebSocketLiveClient;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_40_DlpWebSocketLiveClient';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
