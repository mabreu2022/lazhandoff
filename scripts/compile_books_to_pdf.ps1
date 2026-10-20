# ==============================================================================
# Script de Redesign Editorial e Compilação Profissional de Livros para PDF
# Padrão: O'Reilly Media / Addison-Wesley / Pragmatic Bookshelf
# Motor: Pandoc + Design System Editorial (book_theme.css) + Chromium Headless
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$EdgeCandidates = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)

$EdgePath = $EdgeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $EdgePath) {
    Write-Error "Microsoft Edge não foi encontrado para renderização do PDF."
    exit 1
}

$RootDir = (Get-Location).Path
$CssPath = Join-Path $RootDir "scripts\book_theme.css"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "REDESIGN EDITORIAL: INICIANDO PROCESSAMENTO DOS LIVROS" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. LIVRO 1: LAZARUS IDE & LCL
# ------------------------------------------------------------------------------
Write-Host "[1/2] Processando Livro 1: Lazarus IDE & LCL..." -ForegroundColor Green

$LazSumario = Join-Path $RootDir "Livro1_Lazarus_LCL\00_Apresentacao_e_Sumario.md"
$LazModules = Get-ChildItem (Join-Path $RootDir "Livro1_Lazarus_LCL\Modulo_*.md") | Sort-Object Name | ForEach-Object { $_.FullName }
$LazAllFiles = @($LazSumario) + $LazModules

$LazHtml = Join-Path $RootDir "Livro1_Lazarus_LCL_Completo.html"
$LazPdf = Join-Path $RootDir "Livro1_Lazarus_LCL_Completo.pdf"

Write-Host "  -> Compilando Markdown para HTML5 com Pandoc..." -ForegroundColor Gray
& pandoc $LazAllFiles -s -N --toc --toc-depth=3 -c "scripts/book_theme.css" -o $LazHtml

Write-Host "  -> Injetando Capa Editorial e Metadados Paged Media..." -ForegroundColor Gray
$LazHtmlContent = [System.IO.File]::ReadAllText($LazHtml, [System.Text.Encoding]::UTF8)

# Adiciona a classe de tema lazarus-theme no body
$LazHtmlContent = $LazHtmlContent -replace '<body\b[^>]*>', '<body class="lazarus-theme">'

# Capa Editorial Profissional
$LazCover = @"
<div class="editorial-cover">
  <div>
    <div class="cover-badge">Engenharia de Software &bull; Manual T&eacute;cnico Definitivo</div>
    <h1 class="cover-title">Engenharia e Arquitetura Avan&ccedil;ada de Componentes para Lazarus IDE &amp; LCL</h1>
    <div class="cover-subtitle">O Guia Pr&aacute;tico, Avan&ccedil;ado e Moderno de Desenvolvimento de Componentes Profissionais em Free Pascal 3.2+ e Lazarus 3.x+</div>
    <div class="cover-divider"></div>
    <div class="cover-pillars">
      <span class="pillar-chip">Free Pascal 3.2+</span>
      <span class="pillar-chip">Lazarus 3.x+</span>
      <span class="pillar-chip">LCL Architecture</span>
      <span class="pillar-chip">Widgetsets (Win32 / GTK / Qt / Cocoa)</span>
      <span class="pillar-chip">IDEIntf &amp; Custom Editors</span>
      <span class="pillar-chip">SQLDB Architecture</span>
      <span class="pillar-chip">High-DPI &amp; Themes</span>
      <span class="pillar-chip">50 M&oacute;dulos Pr&aacute;ticos</span>
    </div>
  </div>
  <div class="cover-footer">
    <div>
      <div class="cover-author">Engenharia de Software Especializada &amp; Arquitetura RAD</div>
      <div class="cover-institution">Cole&ccedil;&atilde;o de Engenharia de Componentes Object Pascal</div>
    </div>
    <div class="cover-meta">
      <div><strong>Edi&ccedil;&atilde;o Oficial de Produ&ccedil;&atilde;o</strong></div>
      <div>Ano de Publica&ccedil;&atilde;o: 2026</div>
    </div>
  </div>
</div>
"@

# Injeta a capa logo após a tag body
$LazHtmlContent = $LazHtmlContent -replace '<body class="lazarus-theme">', "<body class=`"lazarus-theme`">`n$LazCover"
[System.IO.File]::WriteAllText($LazHtml, $LazHtmlContent, [System.Text.Encoding]::UTF8)

Write-Host "  -> Renderizando PDF Editorial via Chromium Headless (--no-pdf-header-footer)..." -ForegroundColor Gray
Start-Process -FilePath $EdgePath -ArgumentList "--headless", "--disable-gpu", "--run-all-compositor-stages-before-draw", "--no-pdf-header-footer", "--print-to-pdf=`"$LazPdf`"", "`"$LazHtml`"" -Wait

if (Test-Path $LazPdf) {
    $SizeMB = [Math]::Round(((Get-Item $LazPdf).Length / 1MB), 2)
    Write-Host "  [OK] Livro 1 gerado com sucesso: $LazPdf ($SizeMB MB)" -ForegroundColor Green
} else {
    Write-Error "Falha ao gerar PDF do Livro 1."
}

# ------------------------------------------------------------------------------
# 2. LIVRO 2: DELPHI 12 ATHENS+ VCL & FMX
# ------------------------------------------------------------------------------
Write-Host "[2/2] Processando Livro 2: Delphi 12 Athens+ VCL, FMX & ToolsAPI..." -ForegroundColor Green

$DlpSumario = Join-Path $RootDir "Livro2_Delphi_VCL_FMX\00_Apresentacao_e_Sumario.md"
$DlpModules = Get-ChildItem (Join-Path $RootDir "Livro2_Delphi_VCL_FMX\Modulo_*.md") | Sort-Object Name | ForEach-Object { $_.FullName }
$DlpAllFiles = @($DlpSumario) + $DlpModules

$DlpHtml = Join-Path $RootDir "Livro2_Delphi_Completo.html"
$DlpPdf = Join-Path $RootDir "Livro2_Delphi_Completo.pdf"

Write-Host "  -> Compilando Markdown para HTML5 com Pandoc..." -ForegroundColor Gray
& pandoc $DlpAllFiles -s -N --toc --toc-depth=3 -c "scripts/book_theme.css" -o $DlpHtml

Write-Host "  -> Injetando Capa Editorial e Metadados Paged Media..." -ForegroundColor Gray
$DlpHtmlContent = [System.IO.File]::ReadAllText($DlpHtml, [System.Text.Encoding]::UTF8)

# Capa Editorial Profissional Delphi
$DlpCover = @"
<div class="editorial-cover">
  <div>
    <div class="cover-badge">Engenharia de Software &bull; Manual T&eacute;cnico Definitivo</div>
    <h1 class="cover-title">Desenvolvimento Moderno de Componentes no Delphi: VCL, FireMonkey e ToolsAPI</h1>
    <div class="cover-subtitle">O Guia Pr&aacute;tico, Avan&ccedil;ado e Moderno de Constru&ccedil;&atilde;o de Componentes Profissionais para Delphi 12 Athens+</div>
    <div class="cover-divider"></div>
    <div class="cover-pillars">
      <span class="pillar-chip">Delphi 12 Athens+</span>
      <span class="pillar-chip">VCL Moderna &amp; VCL Styles</span>
      <span class="pillar-chip">FireMonkey (FMX) Cross-Platform</span>
      <span class="pillar-chip">Open Tools API (OTA)</span>
      <span class="pillar-chip">FireDAC &amp; Data-Aware</span>
      <span class="pillar-chip">Parallel Programming Library (PPL)</span>
      <span class="pillar-chip">Per-Monitor v2 &amp; High-DPI</span>
      <span class="pillar-chip">50 M&oacute;dulos Pr&aacute;ticos</span>
    </div>
  </div>
  <div class="cover-footer">
    <div>
      <div class="cover-author">Engenharia de Software Especializada &amp; Arquitetura RAD</div>
      <div class="cover-institution">Cole&ccedil;&atilde;o de Engenharia de Componentes Object Pascal</div>
    </div>
    <div class="cover-meta">
      <div><strong>Edi&ccedil;&atilde;o Oficial de Produ&ccedil;&atilde;o</strong></div>
      <div>Ano de Publica&ccedil;&atilde;o: 2026</div>
    </div>
  </div>
</div>
"@

$DlpHtmlContent = $DlpHtmlContent -replace '<body\b[^>]*>', "<body>`n$DlpCover"
[System.IO.File]::WriteAllText($DlpHtml, $DlpHtmlContent, [System.Text.Encoding]::UTF8)

Write-Host "  -> Renderizando PDF Editorial via Chromium Headless (--no-pdf-header-footer)..." -ForegroundColor Gray
Start-Process -FilePath $EdgePath -ArgumentList "--headless", "--disable-gpu", "--run-all-compositor-stages-before-draw", "--no-pdf-header-footer", "--print-to-pdf=`"$DlpPdf`"", "`"$DlpHtml`"" -Wait

if (Test-Path $DlpPdf) {
    $SizeMB = [Math]::Round(((Get-Item $DlpPdf).Length / 1MB), 2)
    Write-Host "  [OK] Livro 2 gerado com sucesso: $DlpPdf ($SizeMB MB)" -ForegroundColor Green
} else {
    Write-Error "Falha ao gerar PDF do Livro 2."
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "LIVROS COMPILADOS COM SUCESSO NO PADRÃO EDITORIAL PROFISSIONAL!" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
