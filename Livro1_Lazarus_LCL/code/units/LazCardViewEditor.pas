{==============================================================================
  Livro: Engenharia e Arquitetura Avançada de Componentes para Lazarus IDE & LCL
  Módulo 07: Component Editors e Ações de Design-Time (Verbos)
  Unidade: LazCardViewEditor
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Free Pascal 3.2.2+ / Lazarus 3.x+ (ComponentEditors / IDEIntf)
  Descrição: Component Editor profissional para TLazCardView que injeta verbos
             no menu de contexto do Form Designer (botão direito) e manipula
             a ação padrão de duplo-clique (Edit).
==============================================================================}
unit LazCardViewEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Dialogs,
  ComponentEditors,
  LazCardView;

type
  {============================================================================
    Classe: TLazCardViewEditor
    Especializa TComponentEditor para injetar comandos interativos de design
  ============================================================================}
  TLazCardViewEditor = class(TComponentEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    procedure Edit; override;
  end;

procedure Register;

implementation

{ TLazCardViewEditor }

function TLazCardViewEditor.GetVerbCount: Integer;
begin
  { Quantidade total de comandos no menu de contexto (incluindo separadores) }
  Result := 5;
end;

function TLazCardViewEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Adicionar Novo Card...';
    1: Result := 'Limpar Todos os Cards';
    2: Result := 'Alternar Tema Claro / Escuro';
    3: Result := '-'; // Linha divisória separadora
    4: Result := 'Sobre o TLazCardView...';
  else
    Result := '';
  end;
end;

procedure TLazCardViewEditor.ExecuteVerb(Index: Integer);
var
  CardView: TLazCardView;
begin
  if GetComponent is TLazCardView then
  begin
    CardView := TLazCardView(GetComponent);

    case Index of
      0:
        begin
          CardView.AddDefaultCard;
          Modified; // Notifica a IDE que o formulário foi alterado
        end;

      1:
        begin
          if MessageDlg('Confirmação', 'Deseja realmente limpar todos os cartões?',
            mtConfirmation, [mbYes, mbNo], 0) = mrYes then
          begin
            CardView.ClearAllCards;
            Modified;
          end;
        end;

      2:
        begin
          CardView.ToggleTheme;
          Modified;
        end;

      4:
        begin
          ShowMessage(Format(
            'TLazCardView v1.0'#13#10 +
            'Engenharia e Arquitetura Avançada de Componentes para Lazarus'#13#10 +
            'Componente ativo: %s'#13#10 +
            'Total de cartões configurados: %d',
            [CardView.Name, CardView.Cards.Count]));
        end;
    end;
  end;
end;

procedure TLazCardViewEditor.Edit;
begin
  { Ação padrão disparada ao dar duplo-clique sobre o componente no designer }
  ExecuteVerb(0); // Adiciona um novo card imediatamente ao dar duplo-clique
end;

procedure Register;
begin
  RegisterComponentEditor(TLazCardView, TLazCardViewEditor);
end;

end.
