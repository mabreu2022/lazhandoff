{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 06: Property Editors Customizados
  Componente: TDlpGradientHeader
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (Win32, Win64 e VCL)
  Descrição: Controle visual moderno com renderização de gradiente multicor,
             tipografia com suporte a estilos e integração profunda com
             Property Editors no Object Inspector (presets e modal editor).
==============================================================================}
unit DlpGradientHeader;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms;

type
  { Direção de preenchimento do gradiente }
  TDlpGradientDirection = (gdHorizontal, gdVertical);

  {============================================================================
    Classe: TDlpGradientHeader
    Controle de cabeçalho estilizado com gradiente visual
  ============================================================================}
  TDlpGradientHeader = class(TCustomControl)
  private
    FStartColor: TColor;
    FEndColor: TColor;
    FDirection: TDlpGradientDirection;
    FPresetName: string;
    FTitleText: string;
    FSubtitleText: string;

    procedure SetStartColor(const AValue: TColor);
    procedure SetEndColor(const AValue: TColor);
    procedure SetDirection(const AValue: TDlpGradientDirection);
    procedure SetPresetName(const AValue: string);
    procedure SetTitleText(const AValue: string);
    procedure SetSubtitleText(const AValue: string);

    procedure DrawGradient(ACanvas: TCanvas; const ARect: TRect);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;

    { Métodos públicos utilitários }
    procedure ApplyPreset(const APreset: string);
    function GetAvailablePresets: TArray<string>;
  published
    property StartColor: TColor read FStartColor write SetStartColor default $002A1E00;
    property EndColor: TColor read FEndColor write SetEndColor default $00804000;
    property Direction: TDlpGradientDirection read FDirection write SetDirection default gdHorizontal;
    property PresetName: string read FPresetName write SetPresetName;
    property TitleText: string read FTitleText write SetTitleText;
    property SubtitleText: string read FSubtitleText write SetSubtitleText;

    { Propriedades visuais VCL convencionais }
    property Align;
    property Anchors;
    property DoubleBuffered default True;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    { Eventos }
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Engenharia Delphi 12', [TDlpGradientHeader]);
end;

{ TDlpGradientHeader }

constructor TDlpGradientHeader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  Width := 400;
  Height := 64;
  FStartColor := $002A1E00;
  FEndColor := $00804000;
  FDirection := gdHorizontal;
  FPresetName := 'Ocean Blue';
  FTitleText := 'Modern Gradient Header';
  FSubtitleText := 'Enterprise Delphi 12 Component';

  Font.Name := 'Segoe UI';
  Font.Size := 12;
  Font.Color := clWhite;
end;

procedure TDlpGradientHeader.SetStartColor(const AValue: TColor);
begin
  if FStartColor <> AValue then
  begin
    FStartColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpGradientHeader.SetEndColor(const AValue: TColor);
begin
  if FEndColor <> AValue then
  begin
    FEndColor := AValue;
    Invalidate;
  end;
end;

procedure TDlpGradientHeader.SetDirection(const AValue: TDlpGradientDirection);
begin
  if FDirection <> AValue then
  begin
    FDirection := AValue;
    Invalidate;
  end;
end;

procedure TDlpGradientHeader.SetPresetName(const AValue: string);
begin
  if FPresetName <> AValue then
  begin
    FPresetName := AValue;
    ApplyPreset(FPresetName);
  end;
end;

procedure TDlpGradientHeader.SetTitleText(const AValue: string);
begin
  if FTitleText <> AValue then
  begin
    FTitleText := AValue;
    Invalidate;
  end;
end;

procedure TDlpGradientHeader.SetSubtitleText(const AValue: string);
begin
  if FSubtitleText <> AValue then
  begin
    FSubtitleText := AValue;
    Invalidate;
  end;
end;

procedure TDlpGradientHeader.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TDlpGradientHeader.DrawGradient(ACanvas: TCanvas; const ARect: TRect);
var
  Steps, I: Integer;
  R1, G1, B1, R2, G2, B2: Byte;
  CurR, CurG, CurB: Byte;
  LineR: TRect;
  C1, C2: TColor;
begin
  C1 := ColorToRGB(FStartColor);
  C2 := ColorToRGB(FEndColor);

  R1 := GetRValue(C1);
  G1 := GetGValue(C1);
  B1 := GetBValue(C1);

  R2 := GetRValue(C2);
  G2 := GetGValue(C2);
  B2 := GetBValue(C2);

  if FDirection = gdHorizontal then
  begin
    Steps := ARect.Width;
    if Steps <= 0 then Exit;

    for I := 0 to Steps - 1 do
    begin
      CurR := R1 + MulDiv(I, R2 - R1, Steps);
      CurG := G1 + MulDiv(I, G2 - G1, Steps);
      CurB := B1 + MulDiv(I, B2 - B1, Steps);

      ACanvas.Pen.Color := RGB(CurR, CurG, CurB);
      ACanvas.MoveTo(ARect.Left + I, ARect.Top);
      ACanvas.LineTo(ARect.Left + I, ARect.Bottom);
    end;
  end
  else
  begin
    Steps := ARect.Height;
    if Steps <= 0 then Exit;

    for I := 0 to Steps - 1 do
    begin
      CurR := R1 + MulDiv(I, R2 - R1, Steps);
      CurG := G1 + MulDiv(I, G2 - G1, Steps);
      CurB := B1 + MulDiv(I, B2 - B1, Steps);

      ACanvas.Pen.Color := RGB(CurR, CurG, CurB);
      ACanvas.MoveTo(ARect.Left, ARect.Top + I);
      ACanvas.LineTo(ARect.Right, ARect.Top + I);
    end;
  end;
end;

procedure TDlpGradientHeader.Paint;
var
  R, TextR, SubTextR: TRect;
begin
  R := ClientRect;
  DrawGradient(Canvas, R);

  { Renderiza Título Principal }
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Size := 12;

  TextR := Rect(16, 10, Width - 16, 32);
  Vcl.Graphics.DrawText(Canvas.Handle, PChar(FTitleText), Length(FTitleText),
    TextR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  { Renderiza Subtítulo }
  if FSubtitleText <> '' then
  begin
    Canvas.Font.Style := [];
    Canvas.Font.Size := 9;
    Canvas.Font.Color := $00D0D0D0;

    SubTextR := Rect(16, 34, Width - 16, Height - 6);
    Vcl.Graphics.DrawText(Canvas.Handle, PChar(FSubtitleText), Length(FSubtitleText),
      SubTextR, DT_LEFT or DT_TOP or DT_SINGLELINE);
  end;
end;

procedure TDlpGradientHeader.ApplyPreset(const APreset: string);
begin
  if APreset = 'Ocean Blue' then
  begin
    FStartColor := $004A2600; // Azul profundo
    FEndColor := $00B36B00;   // Ciano suave
  end
  else if APreset = 'Emerald Forest' then
  begin
    FStartColor := $001A3800; // Verde escuro
    FEndColor := $00397300;   // Esmeralda
  end
  else if APreset = 'Sunset Fire' then
  begin
    FStartColor := $00002A66; // Vermelho intenso
    FEndColor := $000080FF;   // Laranja dourado
  end
  else if APreset = 'Dark Obsidian' then
  begin
    FStartColor := $00151515;
    FEndColor := $00353535;
  end;
  Invalidate;
end;

function TDlpGradientHeader.GetAvailablePresets: TArray<string>;
begin
  Result := ['Ocean Blue', 'Emerald Forest', 'Sunset Fire', 'Dark Obsidian'];
end;

end.
