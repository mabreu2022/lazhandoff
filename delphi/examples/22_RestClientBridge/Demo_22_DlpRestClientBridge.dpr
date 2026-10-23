program Demo_22_DlpRestClientBridge;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_22_DlpRestClientBridge';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
