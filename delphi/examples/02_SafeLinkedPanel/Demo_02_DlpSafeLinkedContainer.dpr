program Demo_02_DlpSafeLinkedContainer;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_02_DlpSafeLinkedContainer';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
