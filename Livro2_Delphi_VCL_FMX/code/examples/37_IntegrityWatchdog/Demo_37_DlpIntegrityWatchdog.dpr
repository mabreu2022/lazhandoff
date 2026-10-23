program Demo_37_DlpIntegrityWatchdog;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_37_DlpIntegrityWatchdog';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
