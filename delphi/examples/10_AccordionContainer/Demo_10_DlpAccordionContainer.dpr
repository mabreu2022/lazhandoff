program Demo_10_DlpAccordionContainer;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_10_DlpAccordionContainer';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
