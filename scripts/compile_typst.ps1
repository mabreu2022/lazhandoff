# ==============================================================================
# Script PowerShell para Compilação Automatizada de Livros via Typst
# ==============================================================================
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Verificando compilador Typst..." -ForegroundColor Green

if (Get-Command typst -ErrorAction SilentlyContinue) {
    Write-Host "Typst detectado. Convertendo e compilando..." -ForegroundColor Green

    $LazarusFiles = @("Livro1_Lazarus_LCL\00_Apresentacao_e_Sumario.md") + (Get-ChildItem "Livro1_Lazarus_LCL\Modulo_*.md" | Sort-Object Name | ForEach-Object { $_.FullName })
    pandoc $LazarusFiles -o Livro1_Lazarus_LCL.typ
    typst compile Livro1_Lazarus_LCL.typ Livro1_Lazarus_Typst.pdf

    $DelphiFiles = @("Livro2_Delphi_VCL_FMX\00_Apresentacao_e_Sumario.md") + (Get-ChildItem "Livro2_Delphi_VCL_FMX\Modulo_*.md" | Sort-Object Name | ForEach-Object { $_.FullName })
    pandoc $DelphiFiles -o Livro2_Delphi.typ
    typst compile Livro2_Delphi.typ Livro2_Delphi_Typst.pdf

    Write-Host "PDFs Typst gerados com êxito!" -ForegroundColor Yellow
} else {
    Write-Host "Typst não encontrado no PATH. Utilize 'compile_pandoc_pdf.ps1' com Pandoc + XeLaTeX." -ForegroundColor DarkYellow
}
