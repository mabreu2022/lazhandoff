program Demo_33_DlpEncryptedZipArchive;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_33_DlpEncryptedZipArchive';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
