program Demo_01_DlpTypeHierarchyInspector;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_01_DlpTypeHierarchyInspector';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
