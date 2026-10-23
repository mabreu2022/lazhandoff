program Demo_12_DlpHighDpiThemedPanel;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_12_DlpHighDpiThemedPanel';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
