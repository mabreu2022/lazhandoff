program Demo_31_DlpDataExportPipeline;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_31_DlpDataExportPipeline';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
