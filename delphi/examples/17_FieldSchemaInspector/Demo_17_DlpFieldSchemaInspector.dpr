program Demo_17_DlpFieldSchemaInspector;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_17_DlpFieldSchemaInspector';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
