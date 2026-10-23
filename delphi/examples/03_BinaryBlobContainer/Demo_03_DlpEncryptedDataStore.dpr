program Demo_03_DlpEncryptedDataStore;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_03_DlpEncryptedDataStore';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
