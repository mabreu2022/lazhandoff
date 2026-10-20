{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 07: Component Editors e Ações de Design-Time (Verbos)
  Unidade: DlpDashboardCardEditor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (DesignIntf / DesignEditors)
  Descrição: Component Editor profissional para o TDlpDashboardCard que injeta
             verbos no menu de contexto do Form Designer do Delphi e manipula
             o duplo-clique para rápida alternância de métricas.
==============================================================================}
unit DlpDashboardCardEditor;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Dialogs,
  DesignIntf,
  DesignEditors,
  DlpDashboardCard;

type
  {============================================================================
    Classe: TDlpDashboardCardEditor
    Especializa TComponentEditor para a ToolsAPI do Delphi 12
  ============================================================================}
  TDlpDashboardCardEditor = class(TComponentEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    procedure Edit; override;
  end;

procedure Register;

implementation

{ TDlpDashboardCardEditor }

function TDlpDashboardCardEditor.GetVerbCount: Integer;
begin
  Result := 5;
end;

function TDlpDashboardCardEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Alternar Tendência (Up / Down / Neutral)';
    1: Result := 'Inverter Tema (Dark / Light)';
    2: Result := 'Carregar Dados de Exemplo';
    3: Result := '-'; // Linha divisória
    4: Result := 'Sobre o TDlpDashboardCard...';
  else
    Result := '';
  end;
end;

procedure TDlpDashboardCardEditor.ExecuteVerb(Index: Integer);
var
  Card: TDlpDashboardCard;
begin
  if Component is TDlpDashboardCard then
  begin
    Card := TDlpDashboardCard(Component);

    case Index of
      0:
        begin
          Card.CycleTrend;
          Designer.Modified;
        end;

      1:
        begin
          Card.InvertPalette;
          Designer.Modified;
        end;

      2:
        begin
          Card.ResetToSampleMetrics;
          Designer.Modified;
        end;

      4:
        begin
          ShowMessage(Format(
            'TDlpDashboardCard v1.0'#13#10 +
            'Desenvolvimento Moderno de Componentes no Delphi 12 Athens+'#13#10 +
            'Componente: %s'#13#10 +
            'Métrica Atual: %s (%s)',
            [Card.Name, Card.MetricTitle, Card.MetricValue]));
        end;
    end;
  end;
end;

procedure TDlpDashboardCardEditor.Edit;
begin
  { Duplo-clique alterna a tendência e atualiza o designer }
  ExecuteVerb(0);
end;

procedure Register;
begin
  RegisterComponentEditor(TDlpDashboardCard, TDlpDashboardCardEditor);
end;

end.
