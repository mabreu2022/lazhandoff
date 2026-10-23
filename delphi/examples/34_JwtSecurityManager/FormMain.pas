unit FormMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  DlpJwtSecurityManager;

type
  TFrmMain = class(TForm)
    PnlHeader: TPanel;
    LblTitle: TLabel;
    LblSubtitle: TLabel;
    PnlWorkArea: TPanel;
    PnlContainer: TPanel;
    PnlActions: TPanel;
    BtnRunAction: TButton;
    PnlLog: TPanel;
    MemoLog: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure BtnRunActionClick(Sender: TObject);
  private
    FComp: TDlpJwtSecurityManager;
    procedure LogMessage(const Msg: string);
    procedure DummyProc;
  public
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  LogMessage('Iniciando exemplo do Módulo 34: TDlpJwtSecurityManager (Delphi)...');
  FComp := TDlpJwtSecurityManager.Create(Self);
  FComp.SecretKey := 'SegredoSuperForte2026';
  FComp.DefaultIssuer := 'MinhaEmpresa';
  LogMessage('TDlpJwtSecurityManager pronto para uso.');
end;

procedure TFrmMain.LogMessage(const Msg: string);
begin
  MemoLog.Lines.Add(FormatDateTime('[hh:nn:ss.zzz] ', Now) + Msg);
  MemoLog.SelStart := Length(MemoLog.Text);
end;

procedure TFrmMain.DummyProc;
var i: Integer; d: Double;
begin
  d := 1.0;
  for i := 1 to 500 do d := d * 1.0001;
end;

procedure TFrmMain.BtnRunActionClick(Sender: TObject);
var Tok: string; Claims: TJwtClaims;
begin
  Tok := FComp.GenerateToken('usuario_teste', 'tok_01');
  LogMessage('TDlpJwtSecurityManager: Token gerado: ' + Copy(Tok, 1, 40) + '...');
  if FComp.ValidateToken(Tok, Claims) = jvsValid then
    LogMessage('TDlpJwtSecurityManager: Token validado com sucesso! Subject: ' + Claims.Subject);
end;

end.
