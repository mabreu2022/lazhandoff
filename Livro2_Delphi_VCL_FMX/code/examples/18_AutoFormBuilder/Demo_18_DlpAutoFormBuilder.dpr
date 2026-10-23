program Demo_18_DlpAutoFormBuilder;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_18_DlpAutoFormBuilder';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
