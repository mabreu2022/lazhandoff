{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 19: Caso de Estudo Real 1 — Gerador do Cadastro Completo de Clientes
  Componente: TLazCRUDOperationsBar
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Barra corporativa de operações CRUD com máquina de estados de
             formulário, controle de botões (Inserir, Editar, Gravar, Cancelar,
             Excluir) e rotinas integradas de validação e formatação de CPF/CNPJ.
==============================================================================}
unit LazCRUDOperationsBar;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Forms,
  Buttons,
  ExtCtrls,
  Dialogs,
  DB;

type
  { Máquina de estados operacionais de formulários de cadastro }
  TFormOperationState = (osBrowsing, osInserting, osEditing);

  { Assinatura de evento de validação antes de persistir o registro }
  TOnValidateRecordEvent = procedure(Sender: TObject; var CanSave: Boolean) of object;

  {============================================================================
    Classe: TLazCRUDOperationsBar
    Barra de ferramentas de operações CRUD com sincronização automática a TDataSet
  ============================================================================}
  TLazCRUDOperationsBar = class(TCustomPanel)
  private
    FDataSource: TDataSource;
    FBtnInsert: TSpeedButton;
    FBtnEdit: TSpeedButton;
    FBtnSave: TSpeedButton;
    FBtnCancel: TSpeedButton;
    FBtnDelete: TSpeedButton;
    FBtnClose: TSpeedButton;
    FState: TFormOperationState;
    FOnValidateRecord: TOnValidateRecordEvent;

    procedure SetDataSource(const AValue: TDataSource);
    procedure UpdateButtonsState;
    procedure BtnInsertClick(Sender: TObject);
    procedure BtnEditClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Funções utilitárias estáticas de validação fiscal }
    class function ValidateCPF(const ACPF: string): Boolean;
    class function ValidateCNPJ(const ACNPJ: string): Boolean;
    class function FormatCPF_CNPJ(const ADocument: string): string;
    class function OnlyDigits(const AText: string): string;

    property State: TFormOperationState read FState;
  published
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property OnValidateRecord: TOnValidateRecordEvent
      read FOnValidateRecord write FOnValidateRecord;

    { Propriedades visuais publicadas }
    property Align default alTop;
    property Anchors;
    property Color default $00F5F5F5;
    property Enabled;
    property Font;
    property Height default 44;
    property ParentColor default False;
    property ParentFont;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Lazarus Component Engineering', [TLazCRUDOperationsBar]);
end;

{ Funções Utilitárias de CPF e CNPJ }

class function TLazCRUDOperationsBar.OnlyDigits(const AText: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(AText) do
  begin
    if AText[i] in ['0'..'9'] then
      Result := Result + AText[i];
  end;
end;

class function TLazCRUDOperationsBar.ValidateCPF(const ACPF: string): Boolean;
var
  Digits: string;
  i, Sum, Remainder, Digit1, Digit2: Integer;
  AllSame: Boolean;
begin
  Digits := OnlyDigits(ACPF);
  if Length(Digits) <> 11 then
    Exit(False);

  AllSame := True;
  for i := 2 to 11 do
  begin
    if Digits[i] <> Digits[1] then
    begin
      AllSame := False;
      Break;
    end;
  end;
  if AllSame then
    Exit(False);

  // Primeiro dígito verificador
  Sum := 0;
  for i := 1 to 9 do
    Sum := Sum + (Ord(Digits[i]) - Ord('0')) * (11 - i);
  Remainder := (Sum * 10) mod 11;
  if Remainder = 10 then
    Remainder := 0;
  Digit1 := Remainder;

  // Segundo dígito verificador
  Sum := 0;
  for i := 1 to 10 do
    Sum := Sum + (Ord(Digits[i]) - Ord('0')) * (12 - i);
  Remainder := (Sum * 10) mod 11;
  if Remainder = 10 then
    Remainder := 0;
  Digit2 := Remainder;

  Result := (Digit1 = (Ord(Digits[10]) - Ord('0'))) and
            (Digit2 = (Ord(Digits[11]) - Ord('0')));
end;

class function TLazCRUDOperationsBar.ValidateCNPJ(const ACNPJ: string): Boolean;
const
  Weight1: array[1..12] of Integer = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
  Weight2: array[1..13] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
var
  Digits: string;
  i, Sum, Remainder, Digit1, Digit2: Integer;
  AllSame: Boolean;
begin
  Digits := OnlyDigits(ACNPJ);
  if Length(Digits) <> 14 then
    Exit(False);

  AllSame := True;
  for i := 2 to 14 do
  begin
    if Digits[i] <> Digits[1] then
    begin
      AllSame := False;
      Break;
    end;
  end;
  if AllSame then
    Exit(False);

  // Primeiro dígito
  Sum := 0;
  for i := 1 to 12 do
    Sum := Sum + (Ord(Digits[i]) - Ord('0')) * Weight1[i];
  Remainder := Sum mod 11;
  if Remainder < 2 then
    Digit1 := 0
  else
    Digit1 := 11 - Remainder;

  // Segundo dígito
  Sum := 0;
  for i := 1 to 13 do
    Sum := Sum + (Ord(Digits[i]) - Ord('0')) * Weight2[i];
  Remainder := Sum mod 11;
  if Remainder < 2 then
    Digit2 := 0
  else
    Digit2 := 11 - Remainder;

  Result := (Digit1 = (Ord(Digits[13]) - Ord('0'))) and
            (Digit2 = (Ord(Digits[14]) - Ord('0')));
end;

class function TLazCRUDOperationsBar.FormatCPF_CNPJ(const ADocument: string): string;
var
  Digits: string;
begin
  Digits := OnlyDigits(ADocument);
  if Length(Digits) = 11 then
    Result := Format('%s.%s.%s-%s', [
      Copy(Digits, 1, 3), Copy(Digits, 4, 3), Copy(Digits, 7, 3), Copy(Digits, 10, 2)
    ])
  else if Length(Digits) = 14 then
    Result := Format('%s.%s.%s/%s-%s', [
      Copy(Digits, 1, 2), Copy(Digits, 3, 3), Copy(Digits, 6, 3), Copy(Digits, 9, 4), Copy(Digits, 13, 2)
    ])
  else
    Result := ADocument;
end;

{ TLazCRUDOperationsBar }

constructor TLazCRUDOperationsBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  Height := 44;
  Color := $00F5F5F5;
  BevelOuter := bvNone;
  FState := osBrowsing;

  // Botão Inserir
  FBtnInsert := TSpeedButton.Create(Self);
  FBtnInsert.Parent := Self;
  FBtnInsert.Caption := 'Novo';
  FBtnInsert.Left := 8;
  FBtnInsert.Top := 6;
  FBtnInsert.Width := 74;
  FBtnInsert.Height := 32;
  FBtnInsert.OnClick := @BtnInsertClick;

  // Botão Editar
  FBtnEdit := TSpeedButton.Create(Self);
  FBtnEdit.Parent := Self;
  FBtnEdit.Caption := 'Alterar';
  FBtnEdit.Left := 86;
  FBtnEdit.Top := 6;
  FBtnEdit.Width := 74;
  FBtnEdit.Height := 32;
  FBtnEdit.OnClick := @BtnEditClick;

  // Botão Salvar
  FBtnSave := TSpeedButton.Create(Self);
  FBtnSave.Parent := Self;
  FBtnSave.Caption := 'Salvar';
  FBtnSave.Left := 164;
  FBtnSave.Top := 6;
  FBtnSave.Width := 74;
  FBtnSave.Height := 32;
  FBtnSave.OnClick := @BtnSaveClick;

  // Botão Cancelar
  FBtnCancel := TSpeedButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.Caption := 'Cancelar';
  FBtnCancel.Left := 242;
  FBtnCancel.Top := 6;
  FBtnCancel.Width := 74;
  FBtnCancel.Height := 32;
  FBtnCancel.OnClick := @BtnCancelClick;

  // Botão Excluir
  FBtnDelete := TSpeedButton.Create(Self);
  FBtnDelete.Parent := Self;
  FBtnDelete.Caption := 'Excluir';
  FBtnDelete.Left := 320;
  FBtnDelete.Top := 6;
  FBtnDelete.Width := 74;
  FBtnDelete.Height := 32;
  FBtnDelete.OnClick := @BtnDeleteClick;

  // Botão Fechar
  FBtnClose := TSpeedButton.Create(Self);
  FBtnClose.Parent := Self;
  FBtnClose.Caption := 'Fechar';
  FBtnClose.Top := 6;
  FBtnClose.Width := 74;
  FBtnClose.Height := 32;
  FBtnClose.Anchors := [akTop, akRight];
  FBtnClose.OnClick := @BtnCloseClick;

  UpdateButtonsState;
end;

destructor TLazCRUDOperationsBar.Destroy;
begin
  inherited Destroy;
end;

procedure TLazCRUDOperationsBar.Resize;
begin
  inherited Resize;
  if FBtnClose <> nil then
    FBtnClose.Left := Width - FBtnClose.Width - 8;
end;

procedure TLazCRUDOperationsBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDataSource) then
  begin
    FDataSource := nil;
    UpdateButtonsState;
  end;
end;

procedure TLazCRUDOperationsBar.SetDataSource(const AValue: TDataSource);
begin
  if FDataSource <> AValue then
  begin
    FDataSource := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
    UpdateButtonsState;
  end;
end;

procedure TLazCRUDOperationsBar.UpdateButtonsState;
var
  HasDS: Boolean;
begin
  HasDS := (FDataSource <> nil) and (FDataSource.DataSet <> nil) and FDataSource.DataSet.Active;

  if not HasDS then
  begin
    FBtnInsert.Enabled := False;
    FBtnEdit.Enabled := False;
    FBtnSave.Enabled := False;
    FBtnCancel.Enabled := False;
    FBtnDelete.Enabled := False;
    Exit;
  end;

  case FDataSource.DataSet.State of
    dsInsert:
    begin
      FState := osInserting;
      FBtnInsert.Enabled := False;
      FBtnEdit.Enabled := False;
      FBtnSave.Enabled := True;
      FBtnCancel.Enabled := True;
      FBtnDelete.Enabled := False;
    end;

    dsEdit:
    begin
      FState := osEditing;
      FBtnInsert.Enabled := False;
      FBtnEdit.Enabled := False;
      FBtnSave.Enabled := True;
      FBtnCancel.Enabled := True;
      FBtnDelete.Enabled := False;
    end;

    else
    begin
      FState := osBrowsing;
      FBtnInsert.Enabled := True;
      FBtnEdit.Enabled := not FDataSource.DataSet.IsEmpty;
      FBtnSave.Enabled := False;
      FBtnCancel.Enabled := False;
      FBtnDelete.Enabled := not FDataSource.DataSet.IsEmpty;
    end;
  end;
end;

procedure TLazCRUDOperationsBar.BtnInsertClick(Sender: TObject);
begin
  if (FDataSource <> nil) and (FDataSource.DataSet <> nil) then
  begin
    FDataSource.DataSet.Append;
    UpdateButtonsState;
  end;
end;

procedure TLazCRUDOperationsBar.BtnEditClick(Sender: TObject);
begin
  if (FDataSource <> nil) and (FDataSource.DataSet <> nil) then
  begin
    FDataSource.DataSet.Edit;
    UpdateButtonsState;
  end;
end;

procedure TLazCRUDOperationsBar.BtnSaveClick(Sender: TObject);
var
  CanSave: Boolean;
begin
  if (FDataSource <> nil) and (FDataSource.DataSet <> nil) then
  begin
    CanSave := True;
    if Assigned(FOnValidateRecord) then
      FOnValidateRecord(Self, CanSave);

    if CanSave then
    begin
      FDataSource.DataSet.Post;
      UpdateButtonsState;
    end;
  end;
end;

procedure TLazCRUDOperationsBar.BtnCancelClick(Sender: TObject);
begin
  if (FDataSource <> nil) and (FDataSource.DataSet <> nil) then
  begin
    FDataSource.DataSet.Cancel;
    UpdateButtonsState;
  end;
end;

procedure TLazCRUDOperationsBar.BtnDeleteClick(Sender: TObject);
begin
  if (FDataSource <> nil) and (FDataSource.DataSet <> nil) and not FDataSource.DataSet.IsEmpty then
  begin
    if QuestionDlg('Confirmação', 'Deseja realmente excluir o registro atual?',
                   mtConfirmation, [mrYes, mrNo], 0) = mrYes then
    begin
      FDataSource.DataSet.Delete;
      UpdateButtonsState;
    end;
  end;
end;

procedure TLazCRUDOperationsBar.BtnCloseClick(Sender: TObject);
var
  Frm: TCustomForm;
begin
  Frm := GetParentForm(Self);
  if Frm <> nil then
    Frm.Close;
end;

end.
