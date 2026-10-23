program DlpComponentsDemo;

uses
  Vcl.Forms,
  FormMainDemo in 'FormMainDemo.pas' {FrmMainDemo};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Demonstrador de Componentes Delphi (VCL & FMX)';
  Application.CreateForm(TFrmMainDemo, FrmMainDemo);
  Application.Run;
end.
