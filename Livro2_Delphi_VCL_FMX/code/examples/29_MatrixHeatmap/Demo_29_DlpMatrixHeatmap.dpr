program Demo_29_DlpMatrixHeatmap;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_29_DlpMatrixHeatmap';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
