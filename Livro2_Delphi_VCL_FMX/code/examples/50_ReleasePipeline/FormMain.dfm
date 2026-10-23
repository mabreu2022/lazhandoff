object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'Módulo 50: Demonstração de DlpReleasePipeline'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 17
  object PnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 1973790
    ParentBackground = False
    TabOrder = 0
    object LblTitle: TLabel
      Left = 16
      Top = 8
      Width = 450
      Height = 22
      Caption = 'Módulo 50: DlpReleasePipeline (Pipeline de CI/CD e Releases no GitHub)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object LblSubtitle: TLabel
      Left = 16
      Top = 32
      Width = 550
      Height = 17
      Caption = 'Automação de compilação em lote via linha de comando, empacotamento e releases no GitHub.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 12632256
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object PnlWorkArea: TPanel
    Left = 0
    Top = 60
    Width = 800
    Height = 360
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object PnlContainer: TPanel
      Left = 16
      Top = 16
      Width = 768
      Height = 280
      Align = alClient
      BevelOuter = bvLowered
      TabOrder = 0
    end
    object PnlActions: TPanel
      Left = 0
      Top = 312
      Width = 800
      Height = 48
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object BtnRunAction: TButton
        Left = 16
        Top = 8
        Width = 240
        Height = 32
        Caption = 'Executar Ação do Componente'
        TabOrder = 0
        OnClick = BtnRunActionClick
      end
    end
  end
  object PnlLog: TPanel
    Left = 0
    Top = 420
    Width = 800
    Height = 180
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object MemoLog: TMemo
      Left = 0
      Top = 0
      Width = 800
      Height = 180
      Align = alClient
      Color = 1973790
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13948116
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
end
