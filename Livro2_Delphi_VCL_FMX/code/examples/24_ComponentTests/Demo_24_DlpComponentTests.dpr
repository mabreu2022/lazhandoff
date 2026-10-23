program Demo_24_DlpComponentTests;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_24_DlpComponentTests';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
