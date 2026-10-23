program Demo_34_DlpJwtSecurityManager;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_34_DlpJwtSecurityManager';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
