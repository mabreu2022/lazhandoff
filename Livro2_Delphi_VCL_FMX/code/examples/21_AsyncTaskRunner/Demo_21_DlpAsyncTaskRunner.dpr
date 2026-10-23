program Demo_21_DlpAsyncTaskRunner;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_21_DlpAsyncTaskRunner';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
