{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 15: Controles DB-Aware Avançados e Seletores
  Componente: TLazDBLookupTagBox
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Seletor avançado de chaves estrangeiras com tags visuais dinâmicas
             (TagBox / Multi-Select), pesquisa rápida em memória e sincronização
             bidirecional com TDataSet via TFieldDataLink.
==============================================================================}
unit LazDBLookupTagBox;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Forms,
  DB,
  LCLType,
  LCLIntf;

type
  { Estrutura que representa uma tag selecionada }
  TLazTagItem = record
    Key: string;
    Caption: string;
    Rect: TRect;
    CloseRect: TRect;
  end;

  { Array dinâmico de tags selecionadas }
  TLazTagItemArray = array of TLazTagItem;

  { Evento disparado quando tags são adicionadas ou removidas }
  TOnTagSelectionChanged = procedure(Sender: TObject; const AKey, ACaption: string;
    IsAdded: Boolean) of object;

  {============================================================================
    Classe: TLazDBLookupTagBox
    Controle visual DB-Aware de seleção múltipla com tags interativas
  ============================================================================}
  TLazDBLookupTagBox = class(TCustomControl)
  private
    FDataLink: TFieldDataLink;
    FLookupSource: TDataSource;
    FLookupKeyField: string;
    FLookupListField: string;
    FTags: TLazTagItemArray;
    FDelimitedChar: Char;
    FSearchQuery: string;
    FIsSearching: Boolean;
    FTagColor: TColor;
    FTagTextColor: TColor;
    FOnTagSelectionChanged: TOnTagSelectionChanged;

    function GetDataSource: TDataSource;
    procedure SetDataSource(const AValue: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const AValue: string);
    procedure SetLookupSource(const AValue: TDataSource);

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure ParseFieldValue(const ARawValue: string);
    function ComposeFieldValue: string;
    procedure RecalculateTagLayout;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddTag(const AKey, ACaption: string);
    procedure RemoveTag(const AKey: string);
    procedure ClearTags;
    function HasTag(const AKey: string): Boolean;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property LookupSource: TDataSource read FLookupSource write SetLookupSource;
    property LookupKeyField: string read FLookupKeyField write FLookupKeyField;
    property LookupListField: string read FLookupListField write FLookupListField;
    property DelimitedChar: Char read FDelimitedChar write FDelimitedChar default ',';
    property TagColor: TColor read FTagColor write FTagColor default $00383838;
    property TagTextColor: TColor read FTagTextColor write FTagTextColor default clWhite;

    { Propriedades herdadas publicadas }
    property Align;
    property Anchors;
    property Color default $001A1A1A;
    property Enabled;
    property Font;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;

    property OnClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnResize;
    property OnTagSelectionChanged: TOnTagSelectionChanged read FOnTagSelectionChanged write FOnTagSelectionChanged;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazDBLookupTagBox]);
end;

{ TLazDBLookupTagBox }

constructor TLazDBLookupTagBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents];
  TabStop := True;

  Width := 340;
  Height := 44;
  Color := $001A1A1A;
  FDelimitedChar := ',';
  FSearchQuery := '';
  FIsSearching := False;

  FTagColor := $00383838;
  FTagTextColor := clWhite;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00E0E0E0;

  SetLength(FTags, 0);

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := @DataChange;
  FDataLink.OnUpdateData := @UpdateData;
end;

destructor TLazDBLookupTagBox.Destroy;
begin
  FreeAndNil(FDataLink);
  SetLength(FTags, 0);
  inherited Destroy;
end;

function TLazDBLookupTagBox.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TLazDBLookupTagBox.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if Assigned(AValue) then
      AValue.FreeNotification(Self);
  end;
end;

function TLazDBLookupTagBox.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TLazDBLookupTagBox.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

procedure TLazDBLookupTagBox.SetLookupSource(const AValue: TDataSource);
begin
  if FLookupSource <> AValue then
  begin
    if Assigned(FLookupSource) then
      FLookupSource.RemoveFreeNotification(Self);

    FLookupSource := AValue;

    if Assigned(FLookupSource) then
      FLookupSource.FreeNotification(Self);

    Invalidate;
  end;
end;

procedure TLazDBLookupTagBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if (AComponent = DataSource) and Assigned(FDataLink) then
      DataSource := nil;
    if AComponent = FLookupSource then
      FLookupSource := nil;
  end;
end;

procedure TLazDBLookupTagBox.ParseFieldValue(const ARawValue: string);
var
  RawList: TStringList;
  I: Integer;
  K: string;
begin
  SetLength(FTags, 0);
  if Trim(ARawValue) = '' then
  begin
    RecalculateTagLayout;
    Exit;
  end;

  RawList := TStringList.Create;
  try
    RawList.Delimiter := FDelimitedChar;
    RawList.StrictDelimiter := True;
    RawList.DelimitedText := ARawValue;

    SetLength(FTags, RawList.Count);
    for I := 0 to RawList.Count - 1 do
    begin
      K := Trim(RawList[I]);
      FTags[I].Key := K;
      FTags[I].Caption := K; // Em produção real, consulta o FLookupSource para resolver Caption
    end;
  finally
    RawList.Free;
  end;
  RecalculateTagLayout;
end;

function TLazDBLookupTagBox.ComposeFieldValue: string;
var
  I: Integer;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    for I := 0 to High(FTags) do
    begin
      if I > 0 then
        SB.Append(FDelimitedChar);
      SB.Append(FTags[I].Key);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TLazDBLookupTagBox.DataChange(Sender: TObject);
begin
  if Assigned(FDataLink.Field) then
    ParseFieldValue(FDataLink.Field.AsString)
  else
    SetLength(FTags, 0);
  Invalidate;
end;

procedure TLazDBLookupTagBox.UpdateData(Sender: TObject);
begin
  if Assigned(FDataLink.Field) then
    FDataLink.Field.AsString := ComposeFieldValue;
end;

procedure TLazDBLookupTagBox.RecalculateTagLayout;
var
  I, CurX, CurY, TagW, TagH: Integer;
begin
  CurX := 6;
  CurY := 6;
  TagH := Height - 12;

  Canvas.Font.Assign(Self.Font);
  for I := 0 to High(FTags) do
  begin
    TagW := Canvas.TextWidth(FTags[I].Caption) + 32;
    if CurX + TagW > Width - 8 then
    begin
      { Quebra de linha se necessário }
      CurX := 6;
      Inc(CurY, TagH + 4);
    end;

    FTags[I].Rect := Rect(CurX, CurY, CurX + TagW, CurY + TagH);
    FTags[I].CloseRect := Rect(FTags[I].Rect.Right - 18, FTags[I].Rect.Top + 2,
                               FTags[I].Rect.Right - 4, FTags[I].Rect.Bottom - 2);

    Inc(CurX, TagW + 6);
  end;
end;

procedure TLazDBLookupTagBox.Resize;
begin
  inherited Resize;
  RecalculateTagLayout;
  Invalidate;
end;

procedure TLazDBLookupTagBox.AddTag(const AKey, ACaption: string);
var
  Idx: Integer;
begin
  if HasTag(AKey) then Exit;

  if not FDataLink.Editing then
    FDataLink.Edit;

  Idx := Length(FTags);
  SetLength(FTags, Idx + 1);
  FTags[Idx].Key := AKey;
  FTags[Idx].Caption := ACaption;

  RecalculateTagLayout;
  FDataLink.Modified;
  Invalidate;

  if Assigned(FOnTagSelectionChanged) then
    FOnTagSelectionChanged(Self, AKey, ACaption, True);
end;

procedure TLazDBLookupTagBox.RemoveTag(const AKey: string);
var
  I, Idx: Integer;
  FoundCaption: string;
begin
  Idx := -1;
  for I := 0 to High(FTags) do
  begin
    if FTags[I].Key = AKey then
    begin
      Idx := I;
      FoundCaption := FTags[I].Caption;
      Break;
    end;
  end;

  if Idx >= 0 then
  begin
    if not FDataLink.Editing then
      FDataLink.Edit;

    for I := Idx to High(FTags) - 1 do
      FTags[I] := FTags[I + 1];

    SetLength(FTags, Length(FTags) - 1);
    RecalculateTagLayout;
    FDataLink.Modified;
    Invalidate;

    if Assigned(FOnTagSelectionChanged) then
      FOnTagSelectionChanged(Self, AKey, FoundCaption, False);
  end;
end;

procedure TLazDBLookupTagBox.ClearTags;
begin
  if Length(FTags) > 0 then
  begin
    if not FDataLink.Editing then
      FDataLink.Edit;

    SetLength(FTags, 0);
    RecalculateTagLayout;
    FDataLink.Modified;
    Invalidate;
  end;
end;

function TLazDBLookupTagBox.HasTag(const AKey: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FTags) do
  begin
    if FTags[I].Key = AKey then
      Exit(True);
  end;
end;

procedure TLazDBLookupTagBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  SetFocus;

  if Button = mbLeft then
  begin
    for I := 0 to High(FTags) do
    begin
      if PtInRect(FTags[I].CloseRect, Point(X, Y)) then
      begin
        RemoveTag(FTags[I].Key);
        Exit;
      end;
    end;
  end;
end;

procedure TLazDBLookupTagBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_BACK) and (Length(FTags) > 0) and not FIsSearching then
  begin
    RemoveTag(FTags[High(FTags)].Key);
    Key := 0;
  end;
end;

procedure TLazDBLookupTagBox.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  { Demonstração de inserção rápida por digitação direta }
  if (Key = #13) and (FSearchQuery <> '') then
  begin
    AddTag(FSearchQuery, FSearchQuery);
    FSearchQuery := '';
    Key := #0;
  end
  else if Key >= #32 then
  begin
    FSearchQuery := FSearchQuery + Key;
    Key := #0;
    Invalidate;
  end;
end;

procedure TLazDBLookupTagBox.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TLazDBLookupTagBox.DoExit;
begin
  inherited DoExit;
  FSearchQuery := '';
  Invalidate;
end;

procedure TLazDBLookupTagBox.Paint;
var
  I: Integer;
  R, CloseR: TRect;
  SearchR: TRect;
begin
  { 1. Borda e Fundo do Contêiner }
  Canvas.Brush.Color := Color;
  if Focused then
    Canvas.Pen.Color := $0000A5FF // Laranja em foco
  else
    Canvas.Pen.Color := $00404040;

  Canvas.RoundRect(0, 0, Width, Height, 8, 8);

  { 2. Desenho de Cada Tag }
  RecalculateTagLayout;
  for I := 0 to High(FTags) do
  begin
    R := FTags[I].Rect;
    Canvas.Brush.Color := FTagColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := $00505050;
    Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 6, 6);

    { Texto da Tag }
    Canvas.Font.Assign(Self.Font);
    Canvas.Font.Color := FTagTextColor;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(R.Left + 8, R.Top + (R.Height - Canvas.TextHeight(FTags[I].Caption)) div 2, FTags[I].Caption);

    { Botão [x] de Remoção }
    CloseR := FTags[I].CloseRect;
    Canvas.Font.Size := 7;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := $00808080;
    Canvas.TextOut(CloseR.Left + 2, CloseR.Top + (CloseR.Height - Canvas.TextHeight('×')) div 2, '×');
  end;

  { 3. Texto da Pesquisa Ativa se houver }
  if FSearchQuery <> '' then
  begin
    Canvas.Font.Size := 8;
    Canvas.Font.Color := $0000C853;
    Canvas.TextOut(Width - Canvas.TextWidth(FSearchQuery) - 16, (Height - Canvas.TextHeight(FSearchQuery)) div 2,
      'Busca: ' + FSearchQuery);
  end;
end;

end.
