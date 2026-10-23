program Demo_13_DlpCustomDBConnector;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_13_DlpCustomDBConnector';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
