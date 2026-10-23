program Demo_36_DlpSecurityRoleManager;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_36_DlpSecurityRoleManager';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
