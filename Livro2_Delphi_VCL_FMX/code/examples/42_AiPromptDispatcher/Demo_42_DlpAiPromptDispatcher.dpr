program Demo_42_DlpAiPromptDispatcher;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_42_DlpAiPromptDispatcher';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
