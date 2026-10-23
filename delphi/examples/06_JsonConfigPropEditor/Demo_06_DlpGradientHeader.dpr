program Demo_06_DlpGradientHeader;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_06_DlpGradientHeader';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
