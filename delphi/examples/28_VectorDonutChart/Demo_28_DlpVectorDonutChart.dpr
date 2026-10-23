program Demo_28_DlpVectorDonutChart;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_28_DlpVectorDonutChart';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
