program Demo_50_DlpReleasePipeline;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_50_DlpReleasePipeline';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
