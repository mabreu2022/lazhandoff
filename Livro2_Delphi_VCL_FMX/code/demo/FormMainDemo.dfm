object FrmMainDemo: TFrmMainDemo
  Left = 0
  Top = 0
  Caption = 'Demonstrador Oficial dos 50 Componentes de Engenharia Delphi: VCL & FMX'
  ClientHeight = 720
  ClientWidth = 1080
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object PnlTopHeader: TPanel
    Left = 0
    Top = 0
    Width = 1080
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 1973790
    ParentBackground = False
    TabOrder = 0
    object LblTitle: TLabel
      Left = 20
      Top = 10
      Width = 604
      Height = 25
      Caption = 'Coleção de Engenharia Avançada de Componentes Delphi (50 Módulos)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object LblSubtitle: TLabel
      Left = 20
      Top = 38
      Width = 673
      Height = 17
      Caption = 'Demonstração Interativa em Tempo de Execução dos Componentes Visuais, Industriais, de Segurança e IA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 12632256
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object PageControlMain: TPageControl
    Left = 0
    Top = 64
    Width = 1080
    Height = 476
    ActivePage = TabIndustrial
    Align = alClient
    TabOrder = 1
    object TabIndustrial: TTabSheet
      Caption = '1. Instrumentação & Dashboards'
      object PnlIndustrialControls: TPanel
        Left = 0
        Top = 0
        Width = 1072
        Height = 444
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
      end
    end
    object TabUI: TTabSheet
      Caption = '2. Contêineres & UI Moderna'
      ImageIndex = 1
      object PnlUIControls: TPanel
        Left = 0
        Top = 0
        Width = 1072
        Height = 444
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
      end
    end
    object TabSecurity: TTabSheet
      Caption = '3. Segurança, Criptografia & Tokens'
      ImageIndex = 2
      object PnlSecurityControls: TPanel
        Left = 0
        Top = 0
        Width = 1072
        Height = 444
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
      end
    end
    object TabDiagnostics: TTabSheet
      Caption = '4. Diagnóstico, RTTI & Benchmarks'
      ImageIndex = 3
      object PnlDiagControls: TPanel
        Left = 0
        Top = 0
        Width = 1072
        Height = 444
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
      end
    end
  end
  object PnlBottomLog: TPanel
    Left = 0
    Top = 540
    Width = 1080
    Height = 180
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object PnlLogHeader: TPanel
      Left = 0
      Top = 0
      Width = 1080
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      Color = 3355443
      ParentBackground = False
      TabOrder = 0
      DesignSize = (
        1080
        32)
      object LblLogTitle: TLabel
        Left = 12
        Top = 7
        Width = 246
        Height = 17
        Caption = 'Console de Eventos e Auditoria em Tempo Real'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object BtnClearLog: TButton
        Left = 980
        Top = 4
        Width = 88
        Height = 24
        Anchors = [akTop, akRight]
        Caption = 'Limpar Log'
        TabOrder = 0
        OnClick = BtnClearLogClick
      end
    end
    object MemoLog: TMemo
      Left = 0
      Top = 32
      Width = 1080
      Height = 148
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
      TabOrder = 1
    end
  end
  object TimerGaugeAnim: TTimer
    Interval = 50
    OnTimer = TimerGaugeAnimTimer
    Left = 976
    Top = 88
  end
end
