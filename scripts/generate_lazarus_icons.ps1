# ==============================================================================
# Script: generate_lazarus_icons.ps1
# Objetivo: Gerar 47 ícones profissionais 24x24 PNG para os componentes do livro,
#           compilá-los em laz_components_icons.lrs via lazres.exe e instalar na IDE.
# ==============================================================================

param(
    [string]$IconDir = "d:\Projetos AntiGravity\Livros componentes\Livro1_Lazarus_LCL\code\icons",
    [string]$UnitDir = "d:\Projetos AntiGravity\Livros componentes\Livro1_Lazarus_LCL\code\units",
    [string]$LazresPath = "C:\lazarus\tools\lazres.exe",
    [string]$LazbuildPath = "C:\lazarus\lazbuild.exe"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $IconDir)) {
    New-Item -ItemType Directory -Force -Path $IconDir | Out-Null
}

function Create-RoundedRectanglePath {
    param([float]$x, [float]$y, [float]$width, [float]$height, [float]$radius)
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $radius * 2
    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Generate-BaseIcon {
    param(
        [string]$ClassName,
        [string]$ColorHexTop,
        [string]$ColorHexBottom,
        [scriptblock]$DrawGlyph
    )

    $bmp = [System.Drawing.Bitmap]::new(24, 24, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $g.Clear([System.Drawing.Color]::Transparent)

    # 1. Sombra suave externa
    $shadowRect = Create-RoundedRectanglePath 1.5 2.0 21 21 4.5
    $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(40, 0, 0, 0))
    $g.FillPath($shadowBrush, $shadowRect)
    $shadowBrush.Dispose()
    $shadowRect.Dispose()

    # 2. Fundo com gradiente elegante (Squircle 21x21)
    $bgPath = Create-RoundedRectanglePath 1.5 1.5 21 21 4.5
    $cTop = [System.Drawing.ColorTranslator]::FromHtml($ColorHexTop)
    $cBot = [System.Drawing.ColorTranslator]::FromHtml($ColorHexBottom)
    $gradBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.PointF]::new(1.5, 1.5),
        [System.Drawing.PointF]::new(22.5, 22.5),
        $cTop,
        $cBot
    )
    $g.FillPath($gradBrush, $bgPath)
    $gradBrush.Dispose()

    # 3. Borda sutil de 1px
    $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.0)
    $g.DrawPath($borderPen, $bgPath)
    $borderPen.Dispose()
    $bgPath.Dispose()

    # 4. Executa o desenho do glifo especializado
    & $DrawGlyph $g

    $g.Dispose()

    $destFile = Join-Path $IconDir "$ClassName.png"
    $bmp.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host " [OK] Ícone gerado: $ClassName.png" -ForegroundColor Cyan
}

# ==============================================================================
# DEFINIÇÃO DOS 47 COMPONENTES E SEUS GLIFOS
# ==============================================================================

# 1. TLazAccordionContainer
Generate-BaseIcon "TLAZACCORDIONCONTAINER" "#1D4ED8" "#1E3A8A" {
    param($g)
    $bWhite = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $bCyan = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 125, 211, 252))
    # 3 barras de accordion
    $g.FillRectangle($bCyan, 4, 4, 16, 4)
    $g.FillRectangle($bWhite, 4, 10, 16, 4)
    $g.FillRectangle($bCyan, 4, 16, 16, 4)
    $bWhite.Dispose(); $bCyan.Dispose()
}

# 2. TLazAiPromptDispatcher
Generate-BaseIcon "TLAZAIPROMPTDISPATCHER" "#9333EA" "#581C87" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.5)
    $bSpark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    # Chip central com raio
    $g.DrawRectangle($p, 6, 6, 12, 12)
    $g.FillPolygon($bSpark, @(
        [System.Drawing.PointF]::new(12, 3), [System.Drawing.PointF]::new(15, 9),
        [System.Drawing.PointF]::new(12, 11), [System.Drawing.PointF]::new(14, 16),
        [System.Drawing.PointF]::new(9, 10), [System.Drawing.PointF]::new(12, 9)
    ))
    $p.Dispose(); $bSpark.Dispose()
}

# 3. TLazAiStructuredExtractor
Generate-BaseIcon "TLAZAISTRUCTUREDEXTRACTOR" "#A855F7" "#6B21A8" {
    param($g)
    $f = [System.Drawing.Font]::new("Consolas", 9, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $bGold = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.DrawString("{ }", $f, $bGold, [System.Drawing.PointF]::new(3.5, 4))
    $g.FillRectangle($b, 7, 16, 10, 2)
    $f.Dispose(); $b.Dispose(); $bGold.Dispose()
}

# 4. TLazAnalogGauge
Generate-BaseIcon "TLAZANALOGGAUGE" "#D97706" "#78350F" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.5)
    $pNeedle = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 239, 68, 68), 2.0)
    $g.DrawArc($p, 4, 4, 16, 16, 150, 240)
    $g.DrawLine($pNeedle, 12, 12, 17, 7)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $g.FillEllipse($b, 10.5, 10.5, 3, 3)
    $p.Dispose(); $pNeedle.Dispose(); $b.Dispose()
}

# 5. TLazAsyncEventHook
Generate-BaseIcon "TLAZASYNCEVENTHOOK" "#0D9488" "#134E4A" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.8)
    $p.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
    $g.DrawArc($p, 5, 5, 14, 14, 45, 270)
    $p.Dispose()
}

# 6. TLazAsyncTaskRunner
Generate-BaseIcon "TLAZASYNCTASKRUNNER" "#059669" "#064E3B" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.8)
    $g.DrawEllipse($p, 6, 6, 12, 12)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.FillPolygon($b, @(
        [System.Drawing.PointF]::new(11, 4), [System.Drawing.PointF]::new(15, 11),
        [System.Drawing.PointF]::new(12, 11), [System.Drawing.PointF]::new(14, 19),
        [System.Drawing.PointF]::new(9, 12), [System.Drawing.PointF]::new(12, 12)
    ))
    $p.Dispose(); $b.Dispose()
}

# 7. TLazAutoFormBuilder
Generate-BaseIcon "TLAZAUTOFORMBUILDER" "#4F46E5" "#312E81" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $g.DrawRectangle($p, 4, 5, 16, 14)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 167, 139, 250))
    $g.FillRectangle($b, 4, 5, 16, 4)
    $bStar = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.FillEllipse($bStar, 13, 11, 5, 5)
    $p.Dispose(); $b.Dispose(); $bStar.Dispose()
}

# 8. TLazAutoUpdateManager
Generate-BaseIcon "TLAZAUTOUPDATEMANAGER" "#0284C7" "#0369A1" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.8)
    $p.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
    $g.DrawLine($p, 12, 5, 12, 17)
    $g.DrawArc([System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.5), 5, 12, 14, 8, 0, 180)
    $p.Dispose()
}

# 9. TLazBinaryBlobContainer
Generate-BaseIcon "TLAZBINARYBLOBCONTAINER" "#334155" "#1E293B" {
    param($g)
    $f = [System.Drawing.Font]::new("Consolas", 8, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 52, 211, 153))
    $g.DrawString("01", $f, $b, [System.Drawing.PointF]::new(5, 5))
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.2)
    $g.DrawRectangle($p, 4, 4, 16, 16)
    $f.Dispose(); $b.Dispose(); $p.Dispose()
}

# 10. TLazCardView
Generate-BaseIcon "TLAZCARDVIEW" "#2563EB" "#1D4ED8" {
    param($g)
    $bCard = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $bHeader = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 96, 165, 250))
    $bLine = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 148, 163, 184))
    $g.FillRectangle($bCard, 5, 4, 14, 16)
    $g.FillRectangle($bHeader, 5, 4, 14, 5)
    $g.FillRectangle($bLine, 7, 12, 10, 2)
    $g.FillRectangle($bLine, 7, 15, 6, 2)
    $bCard.Dispose(); $bHeader.Dispose(); $bLine.Dispose()
}

# 11. TLazCodeBenchmarkHarness
Generate-BaseIcon "TLAZCODEBENCHMARKHARNESS" "#D97706" "#78350F" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.5)
    $g.DrawEllipse($p, 5, 6, 14, 14)
    $g.DrawLine($p, 12, 3, 12, 6)
    $pNeedle = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 239, 68, 68), 1.8)
    $g.DrawLine($pNeedle, 12, 13, 16, 9)
    $p.Dispose(); $pNeedle.Dispose()
}

# 12. TLazCRUDOperationsBar
Generate-BaseIcon "TLAZCRUDOPERATIONSBAR" "#0D9488" "#065F46" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.8)
    # Sinal de +
    $g.DrawLine($p, 8, 6, 8, 12)
    $g.DrawLine($p, 5, 9, 11, 9)
    # Sinal de check / ação
    $g.DrawLine($p, 13, 14, 15, 17)
    $g.DrawLine($p, 15, 17, 19, 9)
    $p.Dispose()
}

# 13. TLazCryptoVaultStorage
Generate-BaseIcon "TLAZCRYPTOVAULTSTORAGE" "#CA8A04" "#713F12" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.6)
    $g.DrawRectangle($p, 4, 4, 16, 16)
    $g.DrawEllipse($p, 8, 8, 8, 8)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $g.FillEllipse($b, 10.5, 10.5, 3, 3)
    $p.Dispose(); $b.Dispose()
}

# 14. TLazCustomDBConnector
Generate-BaseIcon "TLAZCUSTOMDBCONNECTOR" "#1D4ED8" "#172554" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $g.DrawEllipse($p, 5, 4, 14, 4)
    $g.DrawLine($p, 5, 6, 5, 14)
    $g.DrawLine($p, 19, 6, 19, 14)
    $g.DrawArc($p, 5, 12, 14, 4, 0, 180)
    # Plug
    $bPlug = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 250, 204, 21))
    $g.FillRectangle($bPlug, 10, 16, 4, 4)
    $p.Dispose(); $bPlug.Dispose()
}

# 15. TLazCustomTabBar
Generate-BaseIcon "TLAZCUSTOMTABBAR" "#2563EB" "#1E293B" {
    param($g)
    $bActive = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $bInactive = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180, 147, 197, 253))
    $g.FillRectangle($bActive, 4, 5, 7, 7)
    $g.FillRectangle($bInactive, 12, 7, 8, 5)
    $g.FillRectangle($bActive, 3, 12, 18, 7)
    $bActive.Dispose(); $bInactive.Dispose()
}

# 16. TLazDatabaseConnectionPool
Generate-BaseIcon "TLAZDATABASECONNECTIONPOOL" "#0284C7" "#1E3A8A" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.2)
    # 2 cilindros conectados
    $g.DrawEllipse($p, 4, 4, 10, 3)
    $g.DrawLine($p, 4, 5, 4, 11); $g.DrawLine($p, 14, 5, 14, 11)
    $g.DrawArc($p, 4, 9, 10, 3, 0, 180)

    $g.DrawEllipse($p, 10, 11, 10, 3)
    $g.DrawLine($p, 10, 12, 10, 18); $g.DrawLine($p, 20, 12, 20, 18)
    $g.DrawArc($p, 10, 16, 10, 3, 0, 180)
    $p.Dispose()
}

# 17. TLazDataConnectionMonitor
Generate-BaseIcon "TLAZDATACONNECTIONMONITOR" "#06B6D4" "#0E7490" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.5)
    # Pulso cardíaco ECG
    $g.DrawLines($p, @(
        [System.Drawing.PointF]::new(3, 12), [System.Drawing.PointF]::new(8, 12),
        [System.Drawing.PointF]::new(10, 5), [System.Drawing.PointF]::new(13, 19),
        [System.Drawing.PointF]::new(15, 9), [System.Drawing.PointF]::new(17, 12),
        [System.Drawing.PointF]::new(21, 12)
    ))
    $p.Dispose()
}

# 18. TLazDataExportPipeline
Generate-BaseIcon "TLAZDATAEXPORTPIPELINE" "#16A34A" "#14532D" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.6)
    # Funil com seta
    $g.DrawPolygon($p, @(
        [System.Drawing.PointF]::new(4, 5), [System.Drawing.PointF]::new(20, 5),
        [System.Drawing.PointF]::new(14, 12), [System.Drawing.PointF]::new(14, 18),
        [System.Drawing.PointF]::new(10, 18), [System.Drawing.PointF]::new(10, 12)
    ))
    $p.Dispose()
}

# 19. TLazDBBadgeLabel
Generate-BaseIcon "TLAZDBBADGELABEL" "#6366F1" "#4338CA" {
    param($g)
    $f = [System.Drawing.Font]::new("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $badge = Create-RoundedRectanglePath 4 6 16 11 4
    $g.DrawPath($p, $badge)
    $g.DrawString("DB", $f, $b, [System.Drawing.PointF]::new(5.5, 6.5))
    $badge.Dispose(); $p.Dispose(); $f.Dispose(); $b.Dispose()
}

# 20. TLazDBLookupTagBox
Generate-BaseIcon "TLAZDBLOOKUPTAGBOX" "#3B82F6" "#1E40AF" {
    param($g)
    $bTag1 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $bTag2 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 147, 197, 253))
    $tag1 = Create-RoundedRectanglePath 4 5 15 5 2
    $tag2 = Create-RoundedRectanglePath 4 13 11 5 2
    $g.FillPath($bTag1, $tag1)
    $g.FillPath($bTag2, $tag2)
    $tag1.Dispose(); $tag2.Dispose(); $bTag1.Dispose(); $bTag2.Dispose()
}

# 21. TLazDBNumberEdit
Generate-BaseIcon "TLAZDBNUMBEREDIT" "#0284C7" "#075985" {
    param($g)
    $f = [System.Drawing.Font]::new("Consolas", 9, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.2)
    $g.DrawRectangle($p, 4, 6, 16, 12)
    $g.DrawString("#9", $f, $b, [System.Drawing.PointF]::new(5, 6))
    $f.Dispose(); $b.Dispose(); $p.Dispose()
}

# 22. TLazEmbeddedWebhookServer
Generate-BaseIcon "TLAZEMBEDDEDWEBHOOKSERVER" "#9333EA" "#581C87" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    # Servidor com ondas
    $g.DrawRectangle($p, 5, 12, 14, 7)
    $g.DrawArc($p, 8, 6, 8, 8, 180, 180)
    $g.DrawArc($p, 5, 3, 14, 14, 180, 180)
    $p.Dispose()
}

# 23. TLazEncryptedZipArchive
Generate-BaseIcon "TLAZENCRYPTEDZIPARCHIVE" "#EA580C" "#9A3412" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $g.DrawRectangle($p, 5, 4, 14, 16)
    # Cadeado central
    $bLock = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.FillRectangle($bLock, 9, 12, 6, 5)
    $g.DrawArc($p, 10, 8, 4, 5, 180, 180)
    $p.Dispose(); $bLock.Dispose()
}

# 24. TLazFastPdfReportBuilder
Generate-BaseIcon "TLAZFASTPDFREPORTBUILDER" "#DC2626" "#7F1D1D" {
    param($g)
    $bPage = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $f = [System.Drawing.Font]::new("Segoe UI", 6, [System.Drawing.FontStyle]::Bold)
    $bRed = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 220, 38, 38))
    $g.FillRectangle($bPage, 5, 4, 14, 16)
    $g.DrawString("PDF", $f, $bRed, [System.Drawing.PointF]::new(5, 9))
    $bPage.Dispose(); $f.Dispose(); $bRed.Dispose()
}

# 25. TLazFieldSchemaInspector
Generate-BaseIcon "TLAZFIELDSCHEMAINSPECTOR" "#64748B" "#334155" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.3)
    $g.DrawRectangle($p, 4, 4, 11, 11)
    $g.DrawLine($p, 4, 8, 15, 8)
    $g.DrawLine($p, 9, 4, 9, 15)
    # Lupa
    $g.DrawEllipse($p, 12, 12, 6, 6)
    $g.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::White, 2.0), 17, 17, 20, 20)
    $p.Dispose()
}

# 26. TLazFiscalXmlValidator
Generate-BaseIcon "TLAZFISCALXMLVALIDATOR" "#16A34A" "#064E3B" {
    param($g)
    $f = [System.Drawing.Font]::new("Segoe UI", 6, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 74, 222, 128), 1.8)
    $g.DrawString("NFe", $f, $b, [System.Drawing.PointF]::new(4, 5))
    # Checkmark
    $g.DrawLine($p, 6, 15, 10, 18)
    $g.DrawLine($p, 10, 18, 17, 11)
    $f.Dispose(); $b.Dispose(); $p.Dispose()
}

# 27. TLazHighDpiThemedPanel
Generate-BaseIcon "TLAZHIGHDPITHEMEDPANEL" "#7C3AED" "#3B0764" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $f = [System.Drawing.Font]::new("Segoe UI", 6.5, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 244, 114, 182))
    $g.DrawRectangle($p, 4, 4, 16, 16)
    $g.DrawString("DPI", $f, $b, [System.Drawing.PointF]::new(5, 7))
    $p.Dispose(); $f.Dispose(); $b.Dispose()
}

# 28. TLazIndustrialTankGauge
Generate-BaseIcon "TLAZINDUSTRIALTANKGAUGE" "#0891B2" "#164E63" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.3)
    $bLiquid = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 56, 189, 248))
    # Tanque
    $tank = Create-RoundedRectanglePath 6 4 12 16 3
    $g.DrawPath($p, $tank)
    $g.FillRectangle($bLiquid, 7, 11, 10, 8)
    $tank.Dispose(); $p.Dispose(); $bLiquid.Dispose()
}

# 29. TLazIntegrityWatchdog
Generate-BaseIcon "TLAZINTEGRITYWATCHDOG" "#E11D48" "#881337" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.6)
    # Escudo
    $g.DrawPolygon($p, @(
        [System.Drawing.PointF]::new(12, 4), [System.Drawing.PointF]::new(19, 7),
        [System.Drawing.PointF]::new(19, 14), [System.Drawing.PointF]::new(12, 19),
        [System.Drawing.PointF]::new(5, 14), [System.Drawing.PointF]::new(5, 7)
    ))
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.FillEllipse($b, 10, 10, 4, 4)
    $p.Dispose(); $b.Dispose()
}

# 30. TLazJsonConfig
Generate-BaseIcon "TLAZJSONCONFIG" "#D97706" "#7C2D12" {
    param($g)
    $f = [System.Drawing.Font]::new("Consolas", 8.5, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $g.DrawString("{;}", $f, $b, [System.Drawing.PointF]::new(4.5, 6))
    $f.Dispose(); $b.Dispose()
}

# 31. TLazJwtSecurityManager
Generate-BaseIcon "TLAZJWTSECURITYMANAGER" "#E11D48" "#831843" {
    param($g)
    $f = [System.Drawing.Font]::new("Segoe UI", 6.5, [System.Drawing.FontStyle]::Bold)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.DrawString("JWT", $f, $b, [System.Drawing.PointF]::new(4.5, 5))
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $g.DrawEllipse($p, 6, 12, 5, 5)
    $g.DrawLine($p, 11, 14, 18, 14)
    $g.DrawLine($p, 15, 14, 15, 17)
    $f.Dispose(); $b.Dispose(); $p.Dispose()
}

# 32. TLazMatrixHeatmap
Generate-BaseIcon "TLAZMATRIXHEATMAP" "#1E293B" "#0F172A" {
    param($g)
    $colors = @(
        [System.Drawing.Color]::FromArgb(255, 253, 224, 71),
        [System.Drawing.Color]::FromArgb(255, 251, 146, 60),
        [System.Drawing.Color]::FromArgb(255, 239, 68, 68),
        [System.Drawing.Color]::FromArgb(255, 244, 63, 94),
        [System.Drawing.Color]::FromArgb(255, 168, 85, 247),
        [System.Drawing.Color]::FromArgb(255, 59, 130, 246),
        [System.Drawing.Color]::FromArgb(255, 34, 197, 94),
        [System.Drawing.Color]::FromArgb(255, 234, 179, 8),
        [System.Drawing.Color]::FromArgb(255, 249, 115, 22)
    )
    $idx = 0
    for ($r = 0; $r -lt 3; $r++) {
        for ($c = 0; $c -lt 3; $c++) {
            $b = [System.Drawing.SolidBrush]::new($colors[$idx])
            $g.FillRectangle($b, 4 + ($c * 5.5), 4 + ($r * 5.5), 4.5, 4.5)
            $b.Dispose()
            $idx++
        }
    }
}

# 33. TLazMqttClientBridge
Generate-BaseIcon "TLAZMQTTCLIENTBRIDGE" "#0D9488" "#042F2E" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.2)
    $b = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 45, 212, 191))
    $g.DrawLine($p, 12, 12, 6, 6)
    $g.DrawLine($p, 12, 12, 18, 6)
    $g.DrawLine($p, 12, 12, 6, 18)
    $g.DrawLine($p, 12, 12, 18, 18)
    $g.FillEllipse($b, 10, 10, 4, 4)
    $g.FillEllipse([System.Drawing.Brushes]::White, 4.5, 4.5, 3.5, 3.5)
    $g.FillEllipse([System.Drawing.Brushes]::White, 16, 4.5, 3.5, 3.5)
    $g.FillEllipse([System.Drawing.Brushes]::White, 4.5, 16, 3.5, 3.5)
    $g.FillEllipse([System.Drawing.Brushes]::White, 16, 16, 3.5, 3.5)
    $p.Dispose(); $b.Dispose()
}

# 34. TLazProductStockIndicator
Generate-BaseIcon "TLAZPRODUCTSTOCKINDICATOR" "#65A30D" "#365314" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.3)
    $g.DrawRectangle($p, 4, 4, 16, 16)
    $b1 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 74, 222, 128))
    $b2 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 250, 204, 21))
    $g.FillRectangle($b1, 6, 14, 12, 4)
    $g.FillRectangle($b2, 6, 9, 8, 3.5)
    $p.Dispose(); $b1.Dispose(); $b2.Dispose()
}

# 35. TLazPushNotificationHub
Generate-BaseIcon "TLAZPUSHNOTIFICATIONHUB" "#6366F1" "#3730A3" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $bBell = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    # Sino
    $g.FillPolygon($bBell, @(
        [System.Drawing.PointF]::new(12, 5), [System.Drawing.PointF]::new(16, 13),
        [System.Drawing.PointF]::new(8, 13)
    ))
    $g.DrawLine($p, 7, 14, 17, 14)
    $g.FillEllipse([System.Drawing.Brushes]::White, 11, 15, 2, 2)
    $p.Dispose(); $bBell.Dispose()
}

# 36. TLazRealtimeChartEngine
Generate-BaseIcon "TLAZREALTIMECHARTENGINE" "#1E293B" "#030712" {
    param($g)
    $pGrid = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(60, 255, 255, 255), 1.0)
    $g.DrawLine($pGrid, 4, 12, 20, 12)
    $g.DrawLine($pGrid, 12, 4, 12, 20)
    $pLine = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 34, 197, 94), 1.8)
    $g.DrawLines($pLine, @(
        [System.Drawing.PointF]::new(4, 14), [System.Drawing.PointF]::new(8, 14),
        [System.Drawing.PointF]::new(10, 6), [System.Drawing.PointF]::new(13, 17),
        [System.Drawing.PointF]::new(16, 9), [System.Drawing.PointF]::new(20, 11)
    ))
    $pGrid.Dispose(); $pLine.Dispose()
}

# 37. TLazReleasePipeline
Generate-BaseIcon "TLAZRELEASEPIPELINE" "#EA580C" "#7C2D12" {
    param($g)
    $bRocket = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $bFlame = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    # Foguete
    $g.FillPolygon($bRocket, @(
        [System.Drawing.PointF]::new(12, 3), [System.Drawing.PointF]::new(16, 11),
        [System.Drawing.PointF]::new(14, 15), [System.Drawing.PointF]::new(10, 15),
        [System.Drawing.PointF]::new(8, 11)
    ))
    $g.FillPolygon($bFlame, @(
        [System.Drawing.PointF]::new(12, 20), [System.Drawing.PointF]::new(14, 15),
        [System.Drawing.PointF]::new(10, 15)
    ))
    $bRocket.Dispose(); $bFlame.Dispose()
}

# 38. TLazRestClientBridge
Generate-BaseIcon "TLAZRESTCLIENTBRIDGE" "#0284C7" "#1E3A8A" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $g.DrawEllipse($p, 5, 5, 14, 14)
    $g.DrawLine($p, 5, 12, 19, 12)
    $g.DrawArc($p, 7, 5, 10, 14, 0, 360)
    $p.Dispose()
}

# 39. TLazSafeLinkedPanel
Generate-BaseIcon "TLAZSAFELINKEDPANEL" "#3B82F6" "#1D4ED8" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    $g.DrawRectangle($p, 4, 4, 7, 16)
    $g.DrawRectangle($p, 13, 4, 7, 16)
    $pLink = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71), 2.0)
    $g.DrawLine($pLink, 10, 12, 14, 12)
    $p.Dispose(); $pLink.Dispose()
}

# 40. TLazSecurityRoleManager
Generate-BaseIcon "TLAZSECURITYROLEMANAGER" "#C026D3" "#701A75" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    # Usuário
    $bUser = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $g.FillEllipse($bUser, 10, 5, 4, 4)
    $g.FillPie($bUser, 7, 10, 10, 9, 180, 180)
    # Distintivo / chave
    $bStar = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.FillEllipse($bStar, 14, 13, 5, 5)
    $p.Dispose(); $bUser.Dispose(); $bStar.Dispose()
}

# 41. TLazSerialDeviceConnector
Generate-BaseIcon "TLAZSERIALDEVICECONNECTOR" "#475569" "#1E293B" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    # Conector DB9
    $g.DrawPolygon($p, @(
        [System.Drawing.PointF]::new(5, 7), [System.Drawing.PointF]::new(19, 7),
        [System.Drawing.PointF]::new(16, 17), [System.Drawing.PointF]::new(8, 17)
    ))
    $bPin = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 250, 204, 21))
    $g.FillEllipse($bPin, 8, 10, 2, 2)
    $g.FillEllipse($bPin, 11, 10, 2, 2)
    $g.FillEllipse($bPin, 14, 10, 2, 2)
    $g.FillEllipse($bPin, 9.5, 13.5, 2, 2)
    $g.FillEllipse($bPin, 12.5, 13.5, 2, 2)
    $p.Dispose(); $bPin.Dispose()
}

# 42. TLazSystemDaemonController
Generate-BaseIcon "TLAZSYSTEMDAEMONCONTROLLER" "#334155" "#0F172A" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.8)
    $g.DrawEllipse($p, 6, 6, 12, 12)
    $pInner = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 56, 189, 248), 2.0)
    $g.DrawLine($pInner, 12, 8, 12, 13)
    $p.Dispose(); $pInner.Dispose()
}

# 43. TLazSystemMetricsProbe
Generate-BaseIcon "TLAZSYSTEMMETRICSPROBE" "#0F766E" "#064E3B" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.3)
    $g.DrawRectangle($p, 6, 6, 12, 12)
    # Barras de telemetria
    $bBar = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 52, 211, 153))
    $g.FillRectangle($bBar, 8, 13, 2, 3)
    $g.FillRectangle($bBar, 11, 10, 2, 6)
    $g.FillRectangle($bBar, 14, 8, 2, 8)
    $p.Dispose(); $bBar.Dispose()
}

# 44. TLazTypeInfoInspector
Generate-BaseIcon "TLAZTYPEINFOINSPECTOR" "#7C3AED" "#4C1D95" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.4)
    # Árvore RTTI
    $g.DrawLine($p, 6, 6, 6, 16)
    $g.DrawLine($p, 6, 9, 12, 9)
    $g.DrawLine($p, 6, 15, 12, 15)
    # Lupa
    $g.DrawEllipse($p, 12, 10, 6, 6)
    $g.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::White, 2.0), 16, 15, 19, 18)
    $p.Dispose()
}

# 45. TLazVectorDonutChart
Generate-BaseIcon "TLAZVECTORDONUTCHART" "#1E293B" "#0F172A" {
    param($g)
    $p1 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 56, 189, 248), 3.0)
    $p2 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 234, 179, 8), 3.0)
    $p3 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 244, 63, 94), 3.0)
    $p4 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 34, 197, 94), 3.0)
    $g.DrawArc($p1, 5, 5, 14, 14, 0, 90)
    $g.DrawArc($p2, 5, 5, 14, 14, 90, 90)
    $g.DrawArc($p3, 5, 5, 14, 14, 180, 90)
    $g.DrawArc($p4, 5, 5, 14, 14, 270, 90)
    $p1.Dispose(); $p2.Dispose(); $p3.Dispose(); $p4.Dispose()
}

# 46. TLazVectorEmbeddingStore
Generate-BaseIcon "TLAZVECTOREMBEDDINGSTORE" "#4F46E5" "#312E81" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.2)
    # Vetores e nós
    $g.DrawLine($p, 6, 17, 18, 17)
    $g.DrawLine($p, 6, 17, 6, 6)
    $g.DrawLine($p, 6, 17, 15, 8)
    $bNode = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 253, 224, 71))
    $g.FillEllipse($bNode, 14, 7, 3.5, 3.5)
    $g.FillEllipse($bNode, 11, 11, 3.5, 3.5)
    $g.FillEllipse($bNode, 16, 12, 3.5, 3.5)
    $p.Dispose(); $bNode.Dispose()
}

# 47. TLazWebSocketLiveClient
Generate-BaseIcon "TLAZWEBSOCKETLIVECLIENT" "#0284C7" "#0F172A" {
    param($g)
    $p = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1.6)
    # Setas bidirecionais
    $p.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
    $g.DrawLine($p, 6, 8, 18, 8)
    $pRev = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 56, 189, 248), 1.6)
    $pRev.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
    $g.DrawLine($pRev, 18, 15, 6, 15)
    $p.Dispose(); $pRev.Dispose()
}

Write-Host "--- Todos os 47 ícones PNG foram criados com sucesso! ---" -ForegroundColor Green

# ==============================================================================
# COMPILAÇÃO DOS ÍCONES COM LAZRES
# ==============================================================================
$outputLrs = Join-Path $UnitDir "laz_components_icons.lrs"
$pngFiles = Get-ChildItem -Path $IconDir -Filter "TLAZ*.png" | ForEach-Object { $_.FullName }

Write-Host "Compilando $($pngFiles.Count) ícones em $outputLrs com lazres.exe..." -ForegroundColor Yellow

# Executa o lazres
Push-Location $IconDir
& $LazresPath $outputLrs (Get-ChildItem -Filter "TLAZ*.png" | Select-Object -ExpandProperty Name)
Pop-Location

if (Test-Path $outputLrs) {
    Write-Host " [SUCESSO] Arquivo .lrs gerado com tamanho: $((Get-Item $outputLrs).Length) bytes!" -ForegroundColor Green
    # Copia para espelho em lazarus/src
    $mirrorLrs = "d:\Projetos AntiGravity\Livros componentes\lazarus\src\laz_components_icons.lrs"
    Copy-Item -Path $outputLrs -Destination $mirrorLrs -Force
    Write-Host " [OK] Espelho copiado para: $mirrorLrs" -ForegroundColor Cyan
} else {
    Write-Error "Falha ao gerar $outputLrs com lazres!"
}
