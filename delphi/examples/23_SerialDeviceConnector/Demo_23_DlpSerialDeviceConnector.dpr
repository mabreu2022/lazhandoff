program Demo_23_DlpSerialDeviceConnector;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_23_DlpSerialDeviceConnector';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
