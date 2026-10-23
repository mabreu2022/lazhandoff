program Demo_32_DlpFiscalXmlValidator;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_32_DlpFiscalXmlValidator';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
