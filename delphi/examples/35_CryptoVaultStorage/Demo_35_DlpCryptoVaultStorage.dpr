program Demo_35_DlpCryptoVaultStorage;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_35_DlpCryptoVaultStorage';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
