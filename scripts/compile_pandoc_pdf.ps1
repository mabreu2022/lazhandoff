# ==============================================================================
# Script PowerShell para Compilação Automatizada de Livros via Pandoc e XeLaTeX
# ==============================================================================
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Compilando Livro 1: Lazarus IDE & LCL..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

$LazarusFiles = @("Livro1_Lazarus_LCL\00_Apresentacao_e_Sumario.md") + (Get-ChildItem "Livro1_Lazarus_LCL\Modulo_*.md" | Sort-Object Name | ForEach-Object { $_.FullName })

pandoc $LazarusFiles `
  -o Livro1_Lazarus_LCL_Completo.pdf `
  --pdf-engine=xelatex `
  --toc `
  --toc-depth=3 `
  --number-sections `
  -V geometry:margin=2cm `
  -V fontsize=11pt `
  -V lang=pt-BR

Write-Host "Livro 1 gerado: Livro1_Lazarus_LCL_Completo.pdf" -ForegroundColor Green

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Compilando Livro 2: Delphi 12 Athens+ VCL & FMX..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

$DelphiFiles = @("Livro2_Delphi_VCL_FMX\00_Apresentacao_e_Sumario.md") + (Get-ChildItem "Livro2_Delphi_VCL_FMX\Modulo_*.md" | Sort-Object Name | ForEach-Object { $_.FullName })

pandoc $DelphiFiles `
  -o Livro2_Delphi_Completo.pdf `
  --pdf-engine=xelatex `
  --toc `
  --toc-depth=3 `
  --number-sections `
  -V geometry:margin=2cm `
  -V fontsize=11pt `
  -V lang=pt-BR

Write-Host "Livro 2 gerado: Livro2_Delphi_Completo.pdf" -ForegroundColor Green
Write-Host "Todos os livros foram compilados com sucesso!" -ForegroundColor Yellow
