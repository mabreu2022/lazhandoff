unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LazJwtSecurityManager;

type
  { TFrmMain }
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
    FComp: TLazJwtSecurityManager;
    procedure LogMessage(const Msg: string);
    procedure DummyProc;
  public
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  LogMessage('Iniciando exemplo do Módulo 34: TLazJwtSecurityManager...');
  FComp := TLazJwtSecurityManager.Create(Self);
  FComp.SecretKey := 'SegredoSuperForte2026';
  FComp.DefaultIssuer := 'MinhaEmpresa';
  LogMessage('TLazJwtSecurityManager instanciado e configurado com sucesso.');
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
  LogMessage('TLazJwtSecurityManager: Token gerado: ' + Copy(Tok, 1, 40) + '...');
  if FComp.ValidateToken(Tok, Claims) = jvsValid then
    LogMessage('TLazJwtSecurityManager: Token validado com sucesso! Subject: ' + Claims.Subject);
end;

end.
