program Demo_14_DlpDBBasicControls;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_14_DlpDBBasicControls';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
