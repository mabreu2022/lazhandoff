program Demo_30_DlpFastPdfReport;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_30_DlpFastPdfReport';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
