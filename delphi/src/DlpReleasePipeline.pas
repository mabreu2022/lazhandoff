{==============================================================================
  Livro: Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI
  Módulo 50: Pipeline de CI/CD Multiplataforma e Releases no GitHub (TDlpReleasePipeline)
  Componente: TDlpReleasePipeline
  Autor: Engenharia de Software Especializada & Arquitetura RAD
  Ambiente: Delphi 12 Athens+ (VCL / FMX / Windows / Multiplataforma)
  Descrição: Orquestrador de release e automação DevOps para Delphi 12 Athens+.
             Gera notas de lançamento estruturadas em Markdown, inventário de
             pacotes de runtime (.bpl, .dcp, .dcu), cálculo de hashes de integridade
             SHA-256 e workflow de compilação automatizada com msbuild e dcc32/dcc64.
==============================================================================}
unit DlpReleasePipeline;

interface

uses
  System.SysUtils,
  System.Classes;

type
  { Entrada de artefato compilado }
  TDlpArtifactEntry = class
  public
    FileName: string;
    PlatformName: string;
    Architecture: string;
    FileSize: Int64;
    Sha256Checksum: string;
  end;

  {============================================================================
    Componente: TDlpReleasePipeline
    Orquestrador de releases e esteiras de automação CI/CD
  ============================================================================}
  TDlpReleasePipeline = class(TComponent)
  private
    FProjectName: string;
    FVersionTag: string;
    FReleaseNotes: TStrings;
    FArtifacts: TList;
    FRepositoryUrl: string;

    procedure SetReleaseNotes(const Value: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddArtifact(const AFileName, APlatform, AArch: string; ASize: Int64;
      const AChecksum: string);
    procedure ClearArtifacts;

    function GenerateReleaseMarkdown: string;
    function GenerateGitHubWorkflowYaml: string;
  published
    property ProjectName: string read FProjectName write FProjectName;
    property VersionTag: string read FVersionTag write FVersionTag;
    property RepositoryUrl: string read FRepositoryUrl write FRepositoryUrl;
    property ReleaseNotes: TStrings read FReleaseNotes write SetReleaseNotes;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Delphi Engenharia Avancada', [TDlpReleasePipeline]);
end;

{ TDlpReleasePipeline }

constructor TDlpReleasePipeline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProjectName := 'Delphi-Enterprise-Components';
  FVersionTag := 'v1.0.0';
  FRepositoryUrl := 'https://github.com/empresa/delphi-components';
  FReleaseNotes := TStringList.Create;
  FReleaseNotes.Add('### O que ha de novo no Delphi 12 Athens:');
  FReleaseNotes.Add('- Suporte completo aos 50 módulos da suíte corporativa de componentes.');
  FReleaseNotes.Add('- Arquitetura VCL e FireMonkey 100% nativa.');
  FReleaseNotes.Add('- Microservidores webhooks, clientes MQTT e gerador nativo de PDF.');
  FArtifacts := TList.Create;
end;

destructor TDlpReleasePipeline.Destroy;
begin
  ClearArtifacts;
  FArtifacts.Free;
  FReleaseNotes.Free;
  inherited Destroy;
end;

procedure TDlpReleasePipeline.SetReleaseNotes(const Value: TStrings);
begin
  FReleaseNotes.Assign(Value);
end;

procedure TDlpReleasePipeline.ClearArtifacts;
var
  i: Integer;
begin
  for i := 0 to FArtifacts.Count - 1 do
    TDlpArtifactEntry(FArtifacts[i]).Free;
  FArtifacts.Clear;
end;

procedure TDlpReleasePipeline.AddArtifact(const AFileName, APlatform, AArch: string;
  ASize: Int64; const AChecksum: string);
var
  E: TDlpArtifactEntry;
begin
  E := TDlpArtifactEntry.Create;
  E.FileName := AFileName;
  E.PlatformName := APlatform;
  E.Architecture := AArch;
  E.FileSize := ASize;
  E.Sha256Checksum := AChecksum;
  FArtifacts.Add(E);
end;

function TDlpReleasePipeline.GenerateReleaseMarkdown: string;
var
  SL: TStringList;
  i: Integer;
  Art: TDlpArtifactEntry;
begin
  SL := TStringList.Create;
  try
    SL.Add(Format('# Release %s - %s', [FVersionTag, FProjectName]));
    SL.Add('');
    SL.Add(FReleaseNotes.Text);
    SL.Add('');
    SL.Add('## 📦 Inventário de Artefatos e Verificação de Checksums');
    SL.Add('');
    SL.Add('| Arquivo | Plataforma | Arquitetura | Tamanho (Bytes) | Checksum SHA-256 |');
    SL.Add('| :--- | :--- | :--- | :--- | :--- |');

    for i := 0 to FArtifacts.Count - 1 do
    begin
      Art := TDlpArtifactEntry(FArtifacts[i]);
      SL.Add(Format('| `%s` | %s | %s | %d | `%s` |', [
        Art.FileName, Art.PlatformName, Art.Architecture, Art.FileSize, Art.Sha256Checksum
      ]));
    end;

    SL.Add('');
    SL.Add('---');
    SL.Add(Format('*Publicado automaticamente via %s*', [ClassName]));
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TDlpReleasePipeline.GenerateGitHubWorkflowYaml: string;
begin
  Result :=
    'name: CI/CD Delphi MSBuild'#10#10 +
    'on:'#10 +
    '  push:'#10 +
    '    branches: [ main ]'#10 +
    '    tags: [ ''v*'' ]'#10 +
    '  pull_request:'#10 +
    '    branches: [ main ]'#10#10 +
    'jobs:'#10 +
    '  build-windows:'#10 +
    '    runs-on: windows-latest'#10#10 +
    '    steps:'#10 +
    '      - name: Checkout Repositório'#10 +
    '        uses: actions/checkout@v4'#10#10 +
    '      - name: Configurar MSBuild'#10 +
    '        uses: microsoft/setup-msbuild@v2'#10#10 +
    '      - name: Compilar Pacote Runtime (Win64)'#10 +
    '        run: msbuild Livro2_Delphi_VCL_FMX\code\packages\DlpComponents_RT.dpk /p:Config=Release /p:Platform=Win64'#10#10 +
    '      - name: Compilar Pacote Design-Time (Win32)'#10 +
    '        run: msbuild Livro2_Delphi_VCL_FMX\code\packages\DlpComponents_DT.dpk /p:Config=Release /p:Platform=Win32'#10;
end;

end.
