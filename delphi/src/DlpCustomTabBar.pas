{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 11: Coleções Tipadas e Sub-Propriedades Complexas
  Componente: TDlpCustomTabBar
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Barra de abas moderna para Delphi 12 que exemplifica o uso de
             TOwnedCollection e TCollectionItem, com suporte a TCustomImageList,
             badges dinâmicos, botões de fechamento [x] e total integração com
             o Collection Editor do Object Inspector.
==============================================================================}
unit DlpCustomTabBar;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.ImgList;

type
  { Item individual de Aba }
  TDlpTabItem = class(TCollectionItem)
  private
    FCaption: string;
    FImageIndex: Integer;
    FClosable: Boolean;
    FVisible: Boolean;
    FBadgeText: string;
    FBadgeColor: TColor;

    procedure SetCaption(const AValue: string);
    procedure SetImageIndex(const AValue: Integer);
    procedure SetClosable(const AValue: Boolean);
    procedure SetVisible(const AValue: Boolean);
    procedure SetBadgeText(const AValue: string);
    procedure SetBadgeColor(const AValue: TColor);
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    function GetDisplayName: string; override;
  published
    property Caption: string read FCaption write SetCaption;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
    property Closable: Boolean read FClosable write SetClosable default True;
    property Visible: Boolean read FVisible write SetVisible default True;
    property BadgeText: string read FBadgeText write SetBadgeText;
    property BadgeColor: TColor read FBadgeColor write SetBadgeColor default $0055AA00;
  end;

  { Coleção tipada de Abas }
  TDlpTabCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TDlpTabItem;
    procedure SetItem(Index: Integer; const AValue: TDlpTabItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function AddTab(const ACaption: string; AImgIdx: Integer = -1; ACanClose: Boolean = True): TDlpTabItem;
    property Items[Index: Integer]: TDlpTabItem read GetItem write SetItem; default;
  end;

  { Eventos da Barra de Abas }
  TDlpTabChangeEvent = procedure(Sender: TObject; NewIndex: Integer) of object;
  TDlpTabCloseEvent = procedure(Sender: TObject; AIndex: Integer; var CanClose: Boolean) of object;

  {============================================================================
    Classe: TDlpCustomTabBar
    Controle visual de barra de abas moderna para Delphi 12
  ============================================================================}
  TDlpCustomTabBar = class(TCustomControl)
  private
    FTabs: TDlpTabCollection;
    FTabIndex: Integer;
    FImages: TCustomImageList;
    FTabHeight: Integer;
    FActiveTabColor: TColor;
    FInactiveTabColor: TColor;
    FCloseHoverIndex: Integer;
    FOnTabChange: TDlpTabChangeEvent;
    FOnTabClose: TDlpTabCloseEvent;

    procedure SetTabs(const AValue: TDlpTabCollection);
    procedure SetTabIndex(const AValue: Integer);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetTabHeight(const AValue: Integer);
    procedure SetActiveTabColor(const AValue: TColor);
    procedure SetInactiveTabColor(const AValue: TColor);

    function GetTabRect(Index: Integer): TRect;
    function GetCloseButtonRect(const ATabRect: TRect): TRect;
    function TabIndexFromPoint(X, Y: Integer): Integer;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function ActiveTab: TDlpTabItem;
    procedure CloseTab(Index: Integer);
  published
    property Tabs: TDlpTabCollection read FTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default 0;
    property Images: TCustomImageList read FImages write SetImages;
    property TabHeight: Integer read FTabHeight write SetTabHeight default 36;
    property ActiveTabColor: TColor read FActiveTabColor write SetActiveTabColor default $002A2A2A;
    property InactiveTabColor: TColor read FInactiveTabColor write SetInactiveTabColor default $001A1A1A;

    { Propriedades herdadas publicadas }
    property Align;
    property Anchors;
    property Color default $00141414;
    property DoubleBuffered default True;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Eventos }
    property OnClick;
    property OnDblClick;
    property OnResize;
    property OnTabChange: TDlpTabChangeEvent read FOnTabChange write FOnTabChange;
    property OnTabClose: TDlpTabCloseEvent read FOnTabClose write FOnTabClose;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpCustomTabBar]);
end;

{ TDlpTabItem }

constructor TDlpTabItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FCaption := 'Nova Aba';
  FImageIndex := -1;
  FClosable := True;
  FVisible := True;
  FBadgeText := '';
  FBadgeColor := $0055AA00;
end;

procedure TDlpTabItem.Assign(Source: TPersistent);
var
  Src: TDlpTabItem;
begin
  if Source is TDlpTabItem then
  begin
    Src := TDlpTabItem(Source);
    FCaption := Src.Caption;
    FImageIndex := Src.ImageIndex;
    FClosable := Src.Closable;
    FVisible := Src.Visible;
    FBadgeText := Src.BadgeText;
    FBadgeColor := Src.BadgeColor;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TDlpTabItem.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TDlpTabItem.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Changed(False);
  end;
end;

procedure TDlpTabItem.SetImageIndex(const AValue: Integer);
begin
  if FImageIndex <> AValue then
  begin
    FImageIndex := AValue;
    Changed(False);
  end;
end;

procedure TDlpTabItem.SetClosable(const AValue: Boolean);
begin
  if FClosable <> AValue then
  begin
    FClosable := AValue;
    Changed(False);
  end;
end;

procedure TDlpTabItem.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    Changed(False);
  end;
end;

procedure TDlpTabItem.SetBadgeText(const AValue: string);
begin
  if FBadgeText <> AValue then
  begin
    FBadgeText := AValue;
    Changed(False);
  end;
end;

procedure TDlpTabItem.SetBadgeColor(const AValue: TColor);
begin
  if FBadgeColor <> AValue then
  begin
    FBadgeColor := AValue;
    Changed(False);
  end;
end;

{ TDlpTabCollection }

constructor TDlpTabCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDlpTabItem);
end;

function TDlpTabCollection.GetItem(Index: Integer): TDlpTabItem;
begin
  Result := TDlpTabItem(inherited GetItem(Index));
end;

procedure TDlpTabCollection.SetItem(Index: Integer; const AValue: TDlpTabItem);
begin
  inherited SetItem(Index, AValue);
end;

procedure TDlpTabCollection.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if GetOwner is TControl then
    TControl(GetOwner).Invalidate;
end;

function TDlpTabCollection.AddTab(const ACaption: string; AImgIdx: Integer; ACanClose: Boolean): TDlpTabItem;
begin
  Result := TDlpTabItem(Add);
  Result.Caption := ACaption;
  Result.ImageIndex := AImgIdx;
  Result.Closable := ACanClose;
end;

{ TDlpCustomTabBar }

constructor TDlpCustomTabBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents, csDoubleClicks];
  DoubleBuffered := True;
  Width := 460;
  FTabHeight := 36;
  Height := FTabHeight;
  FTabIndex := 0;
  FImages := nil;
  FCloseHoverIndex := -1;

  Color := $00141414;
  FActiveTabColor := $002A2A2A;
  FInactiveTabColor := $001A1A1A;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00F0F0F0;

  FTabs := TDlpTabCollection.Create(Self);
  FTabs.AddTab('Geral', -1, False);
  FTabs.AddTab('Financeiro', -1, True);
  FTabs.AddTab('Auditoria', -1, True);
end;

destructor TDlpCustomTabBar.Destroy;
begin
  FreeAndNil(FTabs);
  inherited Destroy;
end;

procedure TDlpCustomTabBar.SetTabs(const AValue: TDlpTabCollection);
begin
  FTabs.Assign(AValue);
end;

procedure TDlpCustomTabBar.SetTabIndex(const AValue: Integer);
begin
  if (AValue >= -1) and (AValue < FTabs.Count) and (FTabIndex <> AValue) then
  begin
    FTabIndex := AValue;
    Invalidate;
    if Assigned(FOnTabChange) then
      FOnTabChange(Self, FTabIndex);
  end;
end;

procedure TDlpCustomTabBar.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    if Assigned(FImages) then
      FImages.RemoveFreeNotification(Self);

    FImages := AValue;

    if Assigned(FImages) then
      FImages.FreeNotification(Self);

    Invalidate;
  end;
end;

procedure TDlpCustomTabBar.SetTabHeight(const AValue: Integer);
begin
  if (FTabHeight <> AValue) and (AValue >= 24) then
  begin
    FTabHeight := AValue;
    Height := FTabHeight;
    Invalidate;
  end;
end;

procedure TDlpCustomTabBar.SetActiveTabColor(const AValue: TColor);
begin
  if FActiveTabColor <> AValue then
  begin
    FActiveTabColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpCustomTabBar.SetInactiveTabColor(const AValue: TColor);
begin
  if FInactiveTabColor <> AValue then
  begin
    FInactiveTabColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpCustomTabBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FImages) then
  begin
    FImages := nil;
    Invalidate;
  end;
end;

procedure TDlpCustomTabBar.Resize;
begin
  inherited Resize;
  Height := FTabHeight;
  Invalidate;
end;

function TDlpCustomTabBar.GetTabRect(Index: Integer): TRect;
var
  I, CurX, TabWidth: Integer;
  Item: TDlpTabItem;
begin
  CurX := 4;
  for I := 0 to FTabs.Count - 1 do
  begin
    Item := FTabs[I];
    if not Item.Visible then Continue;

    TabWidth := Canvas.TextWidth(Item.Caption) + 40;
    if Item.Closable then
      Inc(TabWidth, 20);
    if Item.BadgeText <> '' then
      Inc(TabWidth, Canvas.TextWidth(Item.BadgeText) + 16);

    if I = Index then
    begin
      Result := Rect(CurX, 2, CurX + TabWidth, Height);
      Exit;
    end;
    Inc(CurX, TabWidth + 2);
  end;
  Result := Rect(0, 0, 0, 0);
end;

function TDlpCustomTabBar.GetCloseButtonRect(const ATabRect: TRect): TRect;
begin
  Result := Rect(ATabRect.Right - 22, ATabRect.Top + (ATabRect.Height - 16) div 2,
                 ATabRect.Right - 6, ATabRect.Top + (ATabRect.Height + 16) div 2);
end;

function TDlpCustomTabBar.TabIndexFromPoint(X, Y: Integer): Integer;
var
  I: Integer;
  R: TRect;
begin
  Result := -1;
  for I := 0 to FTabs.Count - 1 do
  begin
    if not FTabs[I].Visible then Continue;
    R := GetTabRect(I);
    if PtInRect(R, Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

procedure TDlpCustomTabBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ClickedIndex: Integer;
  CloseR, TabR: TRect;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    ClickedIndex := TabIndexFromPoint(X, Y);
    if ClickedIndex >= 0 then
    begin
      TabR := GetTabRect(ClickedIndex);
      if FTabs[ClickedIndex].Closable then
      begin
        CloseR := GetCloseButtonRect(TabR);
        if PtInRect(CloseR, Point(X, Y)) then
        begin
          CloseTab(ClickedIndex);
          Exit;
        end;
      end;
      TabIndex := ClickedIndex;
    end;
  end;
end;

procedure TDlpCustomTabBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  HoverIdx: Integer;
  OldHover: Integer;
  TabR, CloseR: TRect;
begin
  inherited MouseMove(Shift, X, Y);
  OldHover := FCloseHoverIndex;
  HoverIdx := TabIndexFromPoint(X, Y);
  if (HoverIdx >= 0) and FTabs[HoverIdx].Closable then
  begin
    TabR := GetTabRect(HoverIdx);
    CloseR := GetCloseButtonRect(TabR);
    if PtInRect(CloseR, Point(X, Y)) then
      FCloseHoverIndex := HoverIdx
    else
      FCloseHoverIndex := -1;
  end
  else
    FCloseHoverIndex := -1;

  if OldHover <> FCloseHoverIndex then
    Invalidate;
end;

procedure TDlpCustomTabBar.MouseLeave;
begin
  inherited MouseLeave;
  if FCloseHoverIndex <> -1 then
  begin
    FCloseHoverIndex := -1;
    Invalidate;
  end;
end;

procedure TDlpCustomTabBar.CloseTab(Index: Integer);
var
  CanClose: Boolean;
begin
  CanClose := True;
  if Assigned(FOnTabClose) then
    FOnTabClose(Self, Index, CanClose);

  if CanClose and (Index >= 0) and (Index < FTabs.Count) then
  begin
    FTabs.Delete(Index);
    if FTabIndex >= FTabs.Count then
      FTabIndex := FTabs.Count - 1;
    Invalidate;
  end;
end;

function TDlpCustomTabBar.ActiveTab: TDlpTabItem;
begin
  if (FTabIndex >= 0) and (FTabIndex < FTabs.Count) then
    Result := FTabs[FTabIndex]
  else
    Result := nil;
end;

procedure TDlpCustomTabBar.Paint;
var
  I: Integer;
  Item: TDlpTabItem;
  TabR, CloseR, BadgeR: TRect;
  TextX, TextY: Integer;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  Canvas.Pen.Color := $003A3A3A;
  Canvas.MoveTo(0, Height - 1);
  Canvas.LineTo(Width, Height - 1);

  for I := 0 to FTabs.Count - 1 do
  begin
    Item := FTabs[I];
    if not Item.Visible then Continue;

    TabR := GetTabRect(I);

    if I = FTabIndex then
    begin
      Canvas.Brush.Color := FActiveTabColor;
      Canvas.Pen.Color := $004A4A4A;
    end
    else
    begin
      Canvas.Brush.Color := FInactiveTabColor;
      Canvas.Pen.Color := $002A2A2A;
    end;

    Canvas.RoundRect(TabR.Left, TabR.Top, TabR.Right, TabR.Bottom + 4, 6, 6);

    if I = FTabIndex then
    begin
      Canvas.Brush.Color := $0000C853; // Verde accent
      Canvas.FillRect(Rect(TabR.Left + 2, TabR.Top, TabR.Right - 2, TabR.Top + 3));
    end;

    Canvas.Font.Assign(Self.Font);
    if I = FTabIndex then
    begin
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := clWhite;
    end
    else
    begin
      Canvas.Font.Style := [];
      Canvas.Font.Color := $00A0A0A0;
    end;

    Canvas.Brush.Style := bsClear;
    TextX := TabR.Left + 14;
    TextY := TabR.Top + (TabR.Height - Canvas.TextHeight(Item.Caption)) div 2;
    Canvas.TextOut(TextX, TextY, Item.Caption);
    Inc(TextX, Canvas.TextWidth(Item.Caption) + 8);

    if Item.BadgeText <> '' then
    begin
      BadgeR := Rect(TextX, TabR.Top + (TabR.Height - 16) div 2,
                     TextX + Canvas.TextWidth(Item.BadgeText) + 12,
                     TabR.Top + (TabR.Height + 16) div 2);

      Canvas.Brush.Color := Item.BadgeColor;
      Canvas.Brush.Style := bsSolid;
      Canvas.Pen.Color := Item.BadgeColor;
      Canvas.RoundRect(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom, 4, 4);

      Canvas.Font.Size := 7;
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := clWhite;
      Canvas.Brush.Style := bsClear;
      Canvas.TextOut(BadgeR.Left + 6, BadgeR.Top + 2, Item.BadgeText);
    end;

    if Item.Closable then
    begin
      CloseR := GetCloseButtonRect(TabR);
      if I = FCloseHoverIndex then
      begin
        Canvas.Brush.Color := $002A2AD5;
        Canvas.Pen.Color := $002A2AD5;
        Canvas.RoundRect(CloseR.Left, CloseR.Top, CloseR.Right, CloseR.Bottom, 4, 4);
        Canvas.Font.Color := clWhite;
      end
      else
      begin
        Canvas.Brush.Style := bsClear;
        Canvas.Font.Color := $00808080;
      end;

      Canvas.Font.Size := 8;
      Canvas.Font.Style := [fsBold];
      Vcl.Graphics.DrawText(Canvas.Handle, '×', 1, CloseR, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    end;
  end;
end;

end.
