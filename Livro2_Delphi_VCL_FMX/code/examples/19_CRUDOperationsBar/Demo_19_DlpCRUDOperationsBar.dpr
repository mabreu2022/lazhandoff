program Demo_19_DlpCRUDOperationsBar;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_19_DlpCRUDOperationsBar';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
