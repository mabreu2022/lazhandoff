program Demo_15_DlpDBLookupTagBox;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_15_DlpDBLookupTagBox';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
