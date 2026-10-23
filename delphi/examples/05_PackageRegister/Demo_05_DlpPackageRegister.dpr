program Demo_05_DlpPackageRegister;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_05_DlpPackageRegister';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
