program Demo_48_DlpAutoUpdateManager;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_48_DlpAutoUpdateManager';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
