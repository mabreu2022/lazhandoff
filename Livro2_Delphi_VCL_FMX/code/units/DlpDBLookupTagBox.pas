{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 15: Controles DB-Aware Avançados e Seletores
  Componente: TDlpDBLookupTagBox
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ / VCL
  Descrição: Seletor moderno de dados relacionais e chaves multivaloradas
             com interface estilo TagBox / Chip Selector, busca incremental
             em memória e sincronização bidirecional via TFieldDataLink.
==============================================================================}
unit DlpDBLookupTagBox;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Data.DB,
  Vcl.DBCtrls,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Themes;

type
  /// <summary>
  /// Estrutura geométrica que define uma tag individual no controle.
  /// </summary>
  TDlpTagItem = record
    Key: string;
    Caption: string;
    Rect: TRect;
    CloseRect: TRect;
  end;

  /// <summary>
  /// Coleção dinâmica de tags selecionadas.
  /// </summary>
  TDlpTagItemArray = TArray<TDlpTagItem>;

  /// <summary>
  /// Notificação de evento para inclusão ou remoção de tags.
  /// </summary>
  TOnDlpTagSelectionChanged = procedure(Sender: TObject; const AKey, ACaption: string;
    IsAdded: Boolean) of object;

  /// <summary>
  /// Controle visual DB-Aware para seleção múltipla baseada em tags visuais.
  /// </summary>
  TDlpDBLookupTagBox = class(TCustomControl)
  private
    FDataLink: TFieldDataLink;
    FLookupSource: TDataSource;
    FLookupKeyField: string;
    FLookupListField: string;
    FTags: TDlpTagItemArray;
    FDelimitedChar: Char;
    FSearchQuery: string;
    FIsSearching: Boolean;
    FTagColor: TColor;
    FTagTextColor: TColor;
    FOnTagSelectionChanged: TOnDlpTagSelectionChanged;

    function GetDataSource: TDataSource;
    procedure SetDataSource(const AValue: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const AValue: string);
    procedure SetLookupSource(const AValue: TDataSource);
    procedure SetTagColor(const AValue: TColor);
    procedure SetTagTextColor(const AValue: TColor);

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure ParseFieldValue(const ARawValue: string);
    function ComposeFieldValue: string;
    procedure RecalculateTagLayout;
    function ResolveLookupCaption(const AKey: string): string;
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
    function TagCount: Integer;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property LookupSource: TDataSource read FLookupSource write SetLookupSource;
    property LookupKeyField: string read FLookupKeyField write FLookupKeyField;
    property LookupListField: string read FLookupListField write FLookupListField;
    property DelimitedChar: Char read FDelimitedChar write FDelimitedChar default ',';
    property TagColor: TColor read FTagColor write SetTagColor default $004A3B2C;
    property TagTextColor: TColor read FTagTextColor write SetTagTextColor default clWhite;
    property OnTagSelectionChanged: TOnDlpTagSelectionChanged read FOnTagSelectionChanged write FOnTagSelectionChanged;

    { Propriedades herdadas publicadas para integração RAD }
    property Align;
    property Anchors;
    property Color default clWindow;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Component Engineering', [TDlpDBLookupTagBox]);
end;

{ TDlpDBLookupTagBox }

constructor TDlpDBLookupTagBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csCaptureMouse, csClickEvents, csOpaque, csDoubleClicks];
  DoubleBuffered := True;
  TabStop := True;
  Width := 280;
  Height := 42;
  Color := clWindow;
  FTagColor := $004A3B2C; // Azul/cinza escuro moderno
  FTagTextColor := clWhite;
  FDelimitedChar := ',';
  FSearchQuery := '';
  FIsSearching := False;
  SetLength(FTags, 0);

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;
end;

destructor TDlpDBLookupTagBox.Destroy;
begin
  FreeAndNil(FDataLink);
  SetLength(FTags, 0);
  inherited Destroy;
end;

function TDlpDBLookupTagBox.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDlpDBLookupTagBox.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
  end;
end;

function TDlpDBLookupTagBox.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TDlpDBLookupTagBox.SetDataField(const AValue: string);
begin
  if FDataLink.FieldName <> AValue then
  begin
    FDataLink.FieldName := AValue;
    DataChange(Self);
  end;
end;

procedure TDlpDBLookupTagBox.SetLookupSource(const AValue: TDataSource);
begin
  if FLookupSource <> AValue then
  begin
    FLookupSource := AValue;
    if AValue <> nil then
      AValue.FreeNotification(Self);
    DataChange(Self);
  end;
end;

procedure TDlpDBLookupTagBox.SetTagColor(const AValue: TColor);
begin
  if FTagColor <> AValue then
  begin
    FTagColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpDBLookupTagBox.SetTagTextColor(const AValue: TColor);
begin
  if FTagTextColor <> AValue then
  begin
    FTagTextColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpDBLookupTagBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if (FDataLink <> nil) and (AComponent = DataSource) then
      DataSource := nil;
    if AComponent = FLookupSource then
      FLookupSource := nil;
  end;
end;

function TDlpDBLookupTagBox.HasTag(const AKey: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(FTags) do
  begin
    if SameText(FTags[i].Key, AKey) then
      Exit(True);
  end;
end;

function TDlpDBLookupTagBox.TagCount: Integer;
begin
  Result := Length(FTags);
end;

function TDlpDBLookupTagBox.ResolveLookupCaption(const AKey: string): string;
var
  KeyField, ListField: TField;
begin
  Result := AKey;
  if (FLookupSource = nil) or (FLookupSource.DataSet = nil) or not FLookupSource.DataSet.Active then
    Exit;

  if (FLookupKeyField = '') or (FLookupListField = '') then
    Exit;

  KeyField := FLookupSource.DataSet.FindField(FLookupKeyField);
  ListField := FLookupSource.DataSet.FindField(FLookupListField);

  if (KeyField <> nil) and (ListField <> nil) then
  begin
    if FLookupSource.DataSet.Locate(FLookupKeyField, AKey, [loCaseInsensitive]) then
      Result := ListField.AsString;
  end;
end;

procedure TDlpDBLookupTagBox.AddTag(const AKey, ACaption: string);
var
  Idx: Integer;
begin
  if HasTag(AKey) then
    Exit;

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

procedure TDlpDBLookupTagBox.RemoveTag(const AKey: string);
var
  i, j, Total: Integer;
  FoundCaption: string;
begin
  Total := Length(FTags);
  for i := 0 to Total - 1 do
  begin
    if SameText(FTags[i].Key, AKey) then
    begin
      FoundCaption := FTags[i].Caption;
      if not FDataLink.Editing then
        FDataLink.Edit;

      for j := i to Total - 2 do
        FTags[j] := FTags[j + 1];

      SetLength(FTags, Total - 1);
      RecalculateTagLayout;
      FDataLink.Modified;
      Invalidate;

      if Assigned(FOnTagSelectionChanged) then
        FOnTagSelectionChanged(Self, AKey, FoundCaption, False);
      Break;
    end;
  end;
end;

procedure TDlpDBLookupTagBox.ClearTags;
begin
  if Length(FTags) = 0 then
    Exit;

  if not FDataLink.Editing then
    FDataLink.Edit;

  SetLength(FTags, 0);
  RecalculateTagLayout;
  FDataLink.Modified;
  Invalidate;
end;

procedure TDlpDBLookupTagBox.RecalculateTagLayout;
var
  i, CurrentX, CurrentY, TagH, TextW, TagW: Integer;
begin
  Canvas.Font.Assign(Self.Font);
  TagH := 24;
  CurrentX := 4;
  CurrentY := 4;

  for i := 0 to High(FTags) do
  begin
    TextW := Canvas.TextWidth(FTags[i].Caption);
    TagW := TextW + 28;

    if (CurrentX + TagW > Width - 8) and (CurrentX > 4) then
    begin
      CurrentX := 4;
      Inc(CurrentY, TagH + 4);
    end;

    FTags[i].Rect := Rect(CurrentX, CurrentY, CurrentX + TagW, CurrentY + TagH);
    FTags[i].CloseRect := Rect(CurrentX + TagW - 18, CurrentY + 3, CurrentX + TagW - 2, CurrentY + TagH - 3);

    Inc(CurrentX, TagW + 6);
  end;
end;

procedure TDlpDBLookupTagBox.ParseFieldValue(const ARawValue: string);
var
  Tokens: TStringList;
  i: Integer;
  KeyItem, CapItem: string;
begin
  SetLength(FTags, 0);
  if ARawValue = '' then
  begin
    RecalculateTagLayout;
    Invalidate;
    Exit;
  end;

  Tokens := TStringList.Create;
  try
    Tokens.StrictDelimiter := True;
    Tokens.Delimiter := FDelimitedChar;
    Tokens.DelimitedText := ARawValue;

    SetLength(FTags, Tokens.Count);
    for i := 0 to Tokens.Count - 1 do
    begin
      KeyItem := Trim(Tokens[i]);
      CapItem := ResolveLookupCaption(KeyItem);
      FTags[i].Key := KeyItem;
      FTags[i].Caption := CapItem;
    end;
  finally
    Tokens.Free;
  end;

  RecalculateTagLayout;
  Invalidate;
end;

function TDlpDBLookupTagBox.ComposeFieldValue: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(FTags) do
  begin
    if Result <> '' then
      Result := Result + FDelimitedChar;
    Result := Result + FTags[i].Key;
  end;
end;

procedure TDlpDBLookupTagBox.DataChange(Sender: TObject);
begin
  if (FDataLink <> nil) and (FDataLink.Field <> nil) then
    ParseFieldValue(FDataLink.Field.AsString)
  else
    ClearTags;
end;

procedure TDlpDBLookupTagBox.UpdateData(Sender: TObject);
begin
  if (FDataLink <> nil) and (FDataLink.Field <> nil) then
    FDataLink.Field.AsString := ComposeFieldValue;
end;

procedure TDlpDBLookupTagBox.Resize;
begin
  inherited Resize;
  RecalculateTagLayout;
  Invalidate;
end;

procedure TDlpDBLookupTagBox.Paint;
var
  i: Integer;
  OldBkMode: Integer;
  BorderClr: TColor;
  TxtRect: TRect;
begin
  Canvas.Font.Assign(Self.Font);

  // Fundo do controle
  Canvas.Brush.Color := Self.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  // Borda visual
  if Focused then
    BorderClr := clHighlight
  else
    BorderClr := $00C5C5C5;

  Canvas.Pen.Color := BorderClr;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(0, 0, Width, Height);

  OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
  try
    // Desenha cada Tag
    for i := 0 to High(FTags) do
    begin
      // Cápsula arredondada da Tag
      Canvas.Brush.Color := FTagColor;
      Canvas.Pen.Color := FTagColor;
      Canvas.RoundRect(FTags[i].Rect.Left, FTags[i].Rect.Top,
                       FTags[i].Rect.Right, FTags[i].Rect.Bottom, 6, 6);

      // Texto da Tag
      Canvas.Font.Color := FTagTextColor;
      TxtRect := FTags[i].Rect;
      Inc(TxtRect.Left, 6);
      Dec(TxtRect.Right, 18);
      DrawText(Canvas.Handle, PChar(FTags[i].Caption), -1, TxtRect,
        DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS);

      // Botão 'x'
      Canvas.Font.Color := clSilver;
      DrawText(Canvas.Handle, '×', 1, FTags[i].CloseRect,
        DT_SINGLELINE or DT_CENTER or DT_VCENTER);
    end;

    // Indicador de busca se houver texto
    if FSearchQuery <> '' then
    begin
      Canvas.Font.Color := clGray;
      Canvas.TextOut(Width - Canvas.TextWidth(FSearchQuery) - 10, 8, FSearchQuery);
    end;
  finally
    SetBkMode(Canvas.Handle, OldBkMode);
  end;
end;

procedure TDlpDBLookupTagBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  Pt: TPoint;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if CanFocus and not Focused then
    SetFocus;

  Pt := Point(X, Y);
  for i := 0 to High(FTags) do
  begin
    if PtInRect(FTags[i].CloseRect, Pt) then
    begin
      RemoveTag(FTags[i].Key);
      Exit;
    end;
  end;
end;

procedure TDlpDBLookupTagBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_BACK) and (FSearchQuery = '') and (Length(FTags) > 0) then
  begin
    RemoveTag(FTags[High(FTags)].Key);
    Key := 0;
  end
  else if (Key = VK_ESCAPE) then
  begin
    FSearchQuery := '';
    Invalidate;
    Key := 0;
  end;

  inherited KeyDown(Key, Shift);
end;

procedure TDlpDBLookupTagBox.KeyPress(var Key: Char);
begin
  if Key in [#32..#126] then
  begin
    FSearchQuery := FSearchQuery + Key;
    Invalidate;
  end
  else if Key = #8 then
  begin
    if Length(FSearchQuery) > 0 then
    begin
      Delete(FSearchQuery, Length(FSearchQuery), 1);
      Invalidate;
    end;
  end;

  inherited KeyPress(Key);
end;

procedure TDlpDBLookupTagBox.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TDlpDBLookupTagBox.DoExit;
begin
  if (FDataLink <> nil) and FDataLink.Editing then
    FDataLink.UpdateRecord;

  FSearchQuery := '';
  inherited DoExit;
  Invalidate;
end;

end.
