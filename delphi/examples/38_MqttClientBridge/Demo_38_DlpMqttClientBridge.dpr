program Demo_38_DlpMqttClientBridge;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_38_DlpMqttClientBridge';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
