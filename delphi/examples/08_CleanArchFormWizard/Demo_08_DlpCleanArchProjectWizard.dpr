program Demo_08_DlpCleanArchProjectWizard;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_08_DlpCleanArchProjectWizard';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
