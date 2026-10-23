program Demo_47_DlpDatabaseConnectionPool;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_47_DlpDatabaseConnectionPool';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
