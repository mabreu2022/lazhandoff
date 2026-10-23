program Demo_04_DlpWindowsMessageInterceptor;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_04_DlpWindowsMessageInterceptor';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
