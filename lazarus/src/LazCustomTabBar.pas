{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 11: Coleções Tipadas e Sub-Propriedades Complexas
  Componente: TLazCustomTabBar
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Barra de abas customizada (Custom TabBar) com abas tipadas gerenciadas
             via TOwnedCollection / TCollectionItem, suporte a TImageList para
             ícones, badges informativos, botões de fechamento individuais e
             integração automática com o Collection Editor do Object Inspector.
==============================================================================}
unit LazCustomTabBar;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Types,
  Controls,
  Graphics,
  Forms,
  ImgList;

type
  { Item individual de Aba }
  TLazTabItem = class(TCollectionItem)
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
  TLazTabCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TLazTabItem;
    procedure SetItem(Index: Integer; const AValue: TLazTabItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function AddTab(const ACaption: string; AImgIdx: Integer = -1; ACanClose: Boolean = True): TLazTabItem;
    property Items[Index: Integer]: TLazTabItem read GetItem write SetItem; default;
  end;

  { Eventos da Barra de Abas }
  TOnTabChangeEvent = procedure(Sender: TObject; NewIndex: Integer) of object;
  TOnTabCloseEvent = procedure(Sender: TObject; AIndex: Integer; var CanClose: Boolean) of object;

  {============================================================================
    Classe: TLazCustomTabBar
    Controle visual de barra de abas moderna com coleções tipadas
  ============================================================================}
  TLazCustomTabBar = class(TCustomControl)
  private
    FTabs: TLazTabCollection;
    FTabIndex: Integer;
    FImages: TCustomImageList;
    FTabHeight: Integer;
    FActiveTabColor: TColor;
    FInactiveTabColor: TColor;
    FCloseHoverIndex: Integer;
    FOnTabChange: TOnTabChangeEvent;
    FOnTabClose: TOnTabCloseEvent;

    procedure SetTabs(const AValue: TLazTabCollection);
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

    function ActiveTab: TLazTabItem;
    procedure CloseTab(Index: Integer);
  published
    property Tabs: TLazTabCollection read FTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default 0;
    property Images: TCustomImageList read FImages write SetImages;
    property TabHeight: Integer read FTabHeight write SetTabHeight default 34;
    property ActiveTabColor: TColor read FActiveTabColor write SetActiveTabColor default $002A2A2A;
    property InactiveTabColor: TColor read FInactiveTabColor write SetInactiveTabColor default $001A1A1A;

    { Propriedades herdadas publicadas }
    property Align;
    property Anchors;
    property Color default $00141414;
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
    property OnTabChange: TOnTabChangeEvent read FOnTabChange write FOnTabChange;
    property OnTabClose: TOnTabCloseEvent read FOnTabClose write FOnTabClose;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazCustomTabBar]);
end;

{ TLazTabItem }

constructor TLazTabItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FCaption := 'Nova Aba';
  FImageIndex := -1;
  FClosable := True;
  FVisible := True;
  FBadgeText := '';
  FBadgeColor := $0055AA00;
end;

procedure TLazTabItem.Assign(Source: TPersistent);
var
  Src: TLazTabItem;
begin
  if Source is TLazTabItem then
  begin
    Src := TLazTabItem(Source);
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

function TLazTabItem.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TLazTabItem.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Changed(False);
  end;
end;

procedure TLazTabItem.SetImageIndex(const AValue: Integer);
begin
  if FImageIndex <> AValue then
  begin
    FImageIndex := AValue;
    Changed(False);
  end;
end;

procedure TLazTabItem.SetClosable(const AValue: Boolean);
begin
  if FClosable <> AValue then
  begin
    FClosable := AValue;
    Changed(False);
  end;
end;

procedure TLazTabItem.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    Changed(False);
  end;
end;

procedure TLazTabItem.SetBadgeText(const AValue: string);
begin
  if FBadgeText <> AValue then
  begin
    FBadgeText := AValue;
    Changed(False);
  end;
end;

procedure TLazTabItem.SetBadgeColor(const AValue: TColor);
begin
  if FBadgeColor <> AValue then
  begin
    FBadgeColor := AValue;
    Changed(False);
  end;
end;

{ TLazTabCollection }

constructor TLazTabCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TLazTabItem);
end;

function TLazTabCollection.GetItem(Index: Integer): TLazTabItem;
begin
  Result := TLazTabItem(inherited GetItem(Index));
end;

procedure TLazTabCollection.SetItem(Index: Integer; const AValue: TLazTabItem);
begin
  inherited SetItem(Index, AValue);
end;

procedure TLazTabCollection.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if GetOwner is TControl then
    TControl(GetOwner).Invalidate;
end;

function TLazTabCollection.AddTab(const ACaption: string; AImgIdx: Integer; ACanClose: Boolean): TLazTabItem;
begin
  Result := TLazTabItem(Add);
  Result.Caption := ACaption;
  Result.ImageIndex := AImgIdx;
  Result.Closable := ACanClose;
end;

{ TLazCustomTabBar }

constructor TLazCustomTabBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents, csDoubleClicks];
  Width := 450;
  FTabHeight := 34;
  Height := FTabHeight;
  FTabIndex := 0;
  FImages := nil;
  FCloseHoverIndex := -1;

  Color := $00141414;
  FActiveTabColor := $002A2A2A;
  FInactiveTabColor := $001A1A1A;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := $00E0E0E0;

  FTabs := TLazTabCollection.Create(Self);
  FTabs.AddTab('Principal', -1, False);
  FTabs.AddTab('Relatórios', -1, True);
  FTabs.AddTab('Configurações', -1, True);
end;

destructor TLazCustomTabBar.Destroy;
begin
  FreeAndNil(FTabs);
  inherited Destroy;
end;

procedure TLazCustomTabBar.SetTabs(const AValue: TLazTabCollection);
begin
  FTabs.Assign(AValue);
end;

procedure TLazCustomTabBar.SetTabIndex(const AValue: Integer);
begin
  if (AValue >= -1) and (AValue < FTabs.Count) and (FTabIndex <> AValue) then
  begin
    FTabIndex := AValue;
    Invalidate;
    if Assigned(FOnTabChange) then
      FOnTabChange(Self, FTabIndex);
  end;
end;

procedure TLazCustomTabBar.SetImages(const AValue: TCustomImageList);
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

procedure TLazCustomTabBar.SetTabHeight(const AValue: Integer);
begin
  if (FTabHeight <> AValue) and (AValue >= 24) then
  begin
    FTabHeight := AValue;
    Height := FTabHeight;
    Invalidate;
  end;
end;

procedure TLazCustomTabBar.SetActiveTabColor(const AValue: TColor);
begin
  if FActiveTabColor <> AValue then
  begin
    FActiveTabColor := AValue;
    Invalidate;
  end;
end;

procedure TLazCustomTabBar.SetInactiveTabColor(const AValue: TColor);
begin
  if FInactiveTabColor <> AValue then
  begin
    FInactiveTabColor := AValue;
    Invalidate;
  end;
end;

procedure TLazCustomTabBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FImages) then
  begin
    FImages := nil;
    Invalidate;
  end;
end;

procedure TLazCustomTabBar.Resize;
begin
  inherited Resize;
  Height := FTabHeight;
  Invalidate;
end;

function TLazCustomTabBar.GetTabRect(Index: Integer): TRect;
var
  I, CurX, TabWidth: Integer;
  Item: TLazTabItem;
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

function TLazCustomTabBar.GetCloseButtonRect(const ATabRect: TRect): TRect;
begin
  Result := Rect(ATabRect.Right - 22, ATabRect.Top + (ATabRect.Height - 16) div 2,
                 ATabRect.Right - 6, ATabRect.Top + (ATabRect.Height + 16) div 2);
end;

function TLazCustomTabBar.TabIndexFromPoint(X, Y: Integer): Integer;
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

procedure TLazCustomTabBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TLazCustomTabBar.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TLazCustomTabBar.MouseLeave;
begin
  inherited MouseLeave;
  if FCloseHoverIndex <> -1 then
  begin
    FCloseHoverIndex := -1;
    Invalidate;
  end;
end;

procedure TLazCustomTabBar.CloseTab(Index: Integer);
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

function TLazCustomTabBar.ActiveTab: TLazTabItem;
begin
  if (FTabIndex >= 0) and (FTabIndex < FTabs.Count) then
    Result := FTabs[FTabIndex]
  else
    Result := nil;
end;

procedure TLazCustomTabBar.Paint;
var
  I: Integer;
  Item: TLazTabItem;
  TabR, CloseR, BadgeR: TRect;
  TextX, TextY: Integer;
begin
  { 1. Fundo da Barra de Abas }
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  { 2. Linha inferior de base }
  Canvas.Pen.Color := $003A3A3A;
  Canvas.MoveTo(0, Height - 1);
  Canvas.LineTo(Width, Height - 1);

  { 3. Renderização de Cada Aba }
  for I := 0 to FTabs.Count - 1 do
  begin
    Item := FTabs[I];
    if not Item.Visible then Continue;

    TabR := GetTabRect(I);

    { Cor da Aba (Ativa vs Inativa) }
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

    { Faixa de destaque superior para a aba ativa }
    if I = FTabIndex then
    begin
      Canvas.Brush.Color := $0000C853; // Verde accent
      Canvas.FillRect(Rect(TabR.Left + 2, TabR.Top, TabR.Right - 2, TabR.Top + 3));
    end;

    { Texto do Caption }
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

    { Badge Opcional }
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

    { Botão de Fechar [x] }
    if Item.Closable then
    begin
      CloseR := GetCloseButtonRect(TabR);
      if I = FCloseHoverIndex then
      begin
        Canvas.Brush.Color := $002A2AD5; // Vermelho hover
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
      Canvas.TextOut(CloseR.Left + 4, CloseR.Top + 1, '×');
    end;
  end;
end;

end.
