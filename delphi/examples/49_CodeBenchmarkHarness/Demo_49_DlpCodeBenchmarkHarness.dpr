program Demo_49_DlpCodeBenchmarkHarness;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_49_DlpCodeBenchmarkHarness';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
