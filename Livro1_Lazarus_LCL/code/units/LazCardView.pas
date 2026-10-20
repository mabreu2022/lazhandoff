{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 07: Component Editors e Ações de Design-Time (Verbos)
  Componente: TLazCardView
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+
  Descrição: Controle visual moderno de cartões em mosaico (Card View) com
             suporte a múltiplos cards, badges informativos, temas visuais e
             extensão profunda via Component Editor e verbos de menu de contexto.
==============================================================================}
unit LazCardView;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  Graphics,
  Forms;

type
  { Item individual de cartão }
  TLazCardItem = class(TCollectionItem)
  private
    FTitle: string;
    FDescription: string;
    FValueText: string;
    FBadgeColor: TColor;
    procedure SetTitle(const AValue: string);
    procedure SetDescription(const AValue: string);
    procedure SetValueText(const AValue: string);
    procedure SetBadgeColor(const AValue: TColor);
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Title: string read FTitle write SetTitle;
    property Description: string read FDescription write SetDescription;
    property ValueText: string read FValueText write SetValueText;
    property BadgeColor: TColor read FBadgeColor write SetBadgeColor default $0055AA00;
  end;

  { Coleção tipada de cartões }
  TLazCardCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TLazCardItem;
    procedure SetItem(Index: Integer; const AValue: TLazCardItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function AddCard(const ATitle, ADesc, AVal: string; ABadge: TColor = $0055AA00): TLazCardItem;
    property Items[Index: Integer]: TLazCardItem read GetItem write SetItem; default;
  end;

  {============================================================================
    Classe: TLazCardView
    Controle visual contêiner de múltiplos cartões
  ============================================================================}
  TLazCardView = class(TCustomControl)
  private
    FCards: TLazCardCollection;
    FDarkMode: Boolean;
    FCardHeight: Integer;
    FCardSpacing: Integer;

    procedure SetCards(const AValue: TLazCardCollection);
    procedure SetDarkMode(const AValue: Boolean);
    procedure SetCardHeight(const AValue: Integer);
    procedure SetCardSpacing(const AValue: Integer);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Métodos utilitários consumidos pelo Component Editor }
    procedure AddDefaultCard;
    procedure ClearAllCards;
    procedure ToggleTheme;
  published
    property Cards: TLazCardCollection read FCards write SetCards;
    property DarkMode: Boolean read FDarkMode write SetDarkMode default True;
    property CardHeight: Integer read FCardHeight write SetCardHeight default 70;
    property CardSpacing: Integer read FCardSpacing write SetCardSpacing default 8;

    { Propriedades herdadas publicadas }
    property Align;
    property Anchors;
    property Color default $00181818;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property PopupMenu;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Eventos }
    property OnClick;
    property OnDblClick;
    property OnResize;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Lazarus', [TLazCardView]);
end;

{ TLazCardItem }

constructor TLazCardItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FTitle := 'Novo Cartão';
  FDescription := 'Descrição da métrica';
  FValueText := '100%';
  FBadgeColor := $0055AA00;
end;

procedure TLazCardItem.Assign(Source: TPersistent);
var
  Src: TLazCardItem;
begin
  if Source is TLazCardItem then
  begin
    Src := TLazCardItem(Source);
    FTitle := Src.Title;
    FDescription := Src.Description;
    FValueText := Src.ValueText;
    FBadgeColor := Src.BadgeColor;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

procedure TLazCardItem.SetTitle(const AValue: string);
begin
  if FTitle <> AValue then
  begin
    FTitle := AValue;
    Changed(False);
  end;
end;

procedure TLazCardItem.SetDescription(const AValue: string);
begin
  if FDescription <> AValue then
  begin
    FDescription := AValue;
    Changed(False);
  end;
end;

procedure TLazCardItem.SetValueText(const AValue: string);
begin
  if FValueText <> AValue then
  begin
    FValueText := AValue;
    Changed(False);
  end;
end;

procedure TLazCardItem.SetBadgeColor(const AValue: TColor);
begin
  if FBadgeColor <> AValue then
  begin
    FBadgeColor := AValue;
    Changed(False);
  end;
end;

{ TLazCardCollection }

constructor TLazCardCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TLazCardItem);
end;

function TLazCardCollection.GetItem(Index: Integer): TLazCardItem;
begin
  Result := TLazCardItem(inherited GetItem(Index));
end;

procedure TLazCardCollection.SetItem(Index: Integer; const AValue: TLazCardItem);
begin
  inherited SetItem(Index, AValue);
end;

procedure TLazCardCollection.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if GetOwner is TControl then
    TControl(GetOwner).Invalidate;
end;

function TLazCardCollection.AddCard(const ATitle, ADesc, AVal: string; ABadge: TColor): TLazCardItem;
begin
  Result := TLazCardItem(Add);
  Result.Title := ATitle;
  Result.Description := ADesc;
  Result.ValueText := AVal;
  Result.BadgeColor := ABadge;
end;

{ TLazCardView }

constructor TLazCardView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 340;
  Height := 240;
  FDarkMode := True;
  Color := $00181818;
  FCardHeight := 70;
  FCardSpacing := 8;

  FCards := TLazCardCollection.Create(Self);
  { Adiciona cards iniciais de demonstração }
  FCards.AddCard('Métrica de CPU', 'Carga média nos núcleos', '42%', $0000AAFF);
  FCards.AddCard('Uso de Memória', 'Heap alocado no servidor', '1.2 GB', $0055AA00);
end;

destructor TLazCardView.Destroy;
begin
  FreeAndNil(FCards);
  inherited Destroy;
end;

procedure TLazCardView.SetCards(const AValue: TLazCardCollection);
begin
  FCards.Assign(AValue);
end;

procedure TLazCardView.SetDarkMode(const AValue: Boolean);
begin
  if FDarkMode <> AValue then
  begin
    FDarkMode := AValue;
    if FDarkMode then
      Color := $00181818
    else
      Color := $00F5F5F5;
    Invalidate;
  end;
end;

procedure TLazCardView.SetCardHeight(const AValue: Integer);
begin
  if (FCardHeight <> AValue) and (AValue >= 40) then
  begin
    FCardHeight := AValue;
    Invalidate;
  end;
end;

procedure TLazCardView.SetCardSpacing(const AValue: Integer);
begin
  if (FCardSpacing <> AValue) and (AValue >= 0) then
  begin
    FCardSpacing := AValue;
    Invalidate;
  end;
end;

procedure TLazCardView.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TLazCardView.Paint;
var
  I, CurY: Integer;
  CardRect, BadgeRect: TRect;
  Item: TLazCardItem;
  BgColor, BorderColor, TextColor, SubColor: TColor;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if FDarkMode then
  begin
    BgColor := $00242424;
    BorderColor := $003C3C3C;
    TextColor := $00F0F0F0;
    SubColor := $00A0A0A0;
  end
  else
  begin
    BgColor := clWhite;
    BorderColor := $00E0E0E0;
    TextColor := $00202020;
    SubColor := $00707070;
  end;

  CurY := FCardSpacing;
  for I := 0 to FCards.Count - 1 do
  begin
    if CurY + FCardHeight > Height then Break;

    Item := FCards[I];
    CardRect := Rect(FCardSpacing, CurY, Width - FCardSpacing, CurY + FCardHeight);

    { Fundo do Cartão com cantos arredondados }
    Canvas.Brush.Color := BgColor;
    Canvas.Pen.Color := BorderColor;
    Canvas.RoundRect(CardRect.Left, CardRect.Top, CardRect.Right, CardRect.Bottom, 8, 8);

    { Título }
    Canvas.Font.Name := 'Segoe UI';
    Canvas.Font.Size := 10;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := TextColor;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(CardRect.Left + 12, CardRect.Top + 10, Item.Title);

    { Descrição }
    Canvas.Font.Size := 8;
    Canvas.Font.Style := [];
    Canvas.Font.Color := SubColor;
    Canvas.TextOut(CardRect.Left + 12, CardRect.Top + 36, Item.Description);

    { Badge de Valor à Direita }
    BadgeRect := Rect(CardRect.Right - 80, CardRect.Top + 18, CardRect.Right - 12, CardRect.Top + 48);
    Canvas.Brush.Color := Item.BadgeColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := Item.BadgeColor;
    Canvas.RoundRect(BadgeRect.Left, BadgeRect.Top, BadgeRect.Right, BadgeRect.Bottom, 6, 6);

    Canvas.Font.Size := 9;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := clWhite;
    Canvas.Brush.Style := bsClear;
    Canvas.TextRect(BadgeRect, BadgeRect.Left + 8, BadgeRect.Top + 6, Item.ValueText);

    Inc(CurY, FCardHeight + FCardSpacing);
  end;
end;

procedure TLazCardView.AddDefaultCard;
var
  Idx: Integer;
begin
  Idx := FCards.Count + 1;
  FCards.AddCard(Format('Cartão #%d', [Idx]), 'Métrica configurada dinamicamente', 'Ativo', $0000A5FF);
  Invalidate;
end;

procedure TLazCardView.ClearAllCards;
begin
  FCards.Clear;
  Invalidate;
end;

procedure TLazCardView.ToggleTheme;
begin
  DarkMode := not DarkMode;
end;

end.
