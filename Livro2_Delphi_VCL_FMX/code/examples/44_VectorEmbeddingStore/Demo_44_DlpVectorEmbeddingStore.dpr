program Demo_44_DlpVectorEmbeddingStore;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demo_44_DlpVectorEmbeddingStore';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
