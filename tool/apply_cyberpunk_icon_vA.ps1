param(
    [string]$MasterIconPath = "$PSScriptRoot\..\assets\branding\app_icon_cyberpunk_vA.png",
    [switch]$ForceRegenerateMaster = $false
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$WorkspaceRoot = (Resolve-Path "$ProjectRoot\..").Path
$BrandingDir = Join-Path $ProjectRoot "assets\branding"

if (-not (Test-Path $BrandingDir)) {
    New-Item -ItemType Directory -Path $BrandingDir -Force | Out-Null
}

$ResolvedMasterPath = Join-Path $BrandingDir "app_icon_cyberpunk_vA.png"

function New-HexPoints([float]$cx, [float]$cy, [float]$radius) {
    $pts = New-Object 'System.Drawing.PointF[]' 6
    for ($i = 0; $i -lt 6; $i++) {
        # Pointy-top hexagon (-90 deg start)
        $angleDeg = -90.0 + ($i * 60.0)
        $rad = $angleDeg * [Math]::PI / 180.0
        $pts[$i] = New-Object System.Drawing.PointF(
            [float]($cx + $radius * [Math]::Cos($rad)),
            [float]($cy + $radius * [Math]::Sin($rad))
        )
    }
    return $pts
}

function Draw-CyberpunkShieldAndCore([System.Drawing.Graphics]$g, [int]$size, [bool]$transparentBg) {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $cx = [float]($size / 2.0)
    $cy = [float]($size / 2.0)

    if (-not $transparentBg) {
        # Dark Navy -> Deep Purple background (#0B1020 -> #161032)
        $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $rect,
            [System.Drawing.Color]::FromArgb(255, 11, 16, 32),   # #0B1020
            [System.Drawing.Color]::FromArgb(255, 22, 16, 52),   # Deep Navy-Purple
            45.0
        )
        $g.FillRectangle($bgBrush, $rect)
        $bgBrush.Dispose()

        # Subtle cyberpunk HUD grid lines
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(16, 0, 229, 255), [float]([Math]::Max(1.0, $size * 0.002)))
        $step = [int]($size / 8)
        for ($p = $step; $p -lt $size; $p += $step) {
            $g.DrawLine($gridPen, $p, 0, $p, $size)
            $g.DrawLine($gridPen, 0, $p, $size, $p)
        }
        $gridPen.Dispose()

        # Deep Electric Violet (#7C3AED) ambient radial aura
        $auraRadius = [float]($size * 0.44)
        $auraPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $auraPath.AddEllipse($cx - $auraRadius, $cy - $auraRadius, $auraRadius * 2, $auraRadius * 2)
        $auraBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($auraPath)
        $auraBrush.CenterColor = [System.Drawing.Color]::FromArgb(95, 124, 58, 237) # #7C3AED
        $auraBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 11, 16, 32))
        $g.FillPath($auraBrush, $auraPath)
        $auraBrush.Dispose()
        $auraPath.Dispose()
    }

    $scale = if ($transparentBg) { 0.64 } else { 1.0 }
    $hexOuterR = [float]($size * 0.34 * $scale)
    $hexInnerR = [float]($size * 0.295 * $scale)

    # Multi-layer Neon Cyan (#00E5FF) outer glow
    for ($glowIdx = 6; $glowIdx -ge 1; $glowIdx--) {
        $glowR = $hexOuterR + ($glowIdx * $size * 0.008 * $scale)
        $alpha = [int](28 / $glowIdx)
        $glowPen = New-Object System.Drawing.Pen(
            [System.Drawing.Color]::FromArgb($alpha, 0, 229, 255),
            [float]($size * 0.018 * $scale * $glowIdx * 0.45)
        )
        $glowPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $ptsGlow = New-HexPoints $cx $cy $glowR
        $g.DrawPolygon($glowPen, $ptsGlow)
        $glowPen.Dispose()
    }

    # Main Hexagon Shield Body (#121826 -> #1A1438)
    $ptsOuter = New-HexPoints $cx $cy $hexOuterR
    $hexPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $hexPath.AddPolygon($ptsOuter)

    $shieldRect = New-Object System.Drawing.RectangleF(
        [float]($cx - $hexOuterR),
        [float]($cy - $hexOuterR),
        [float]($hexOuterR * 2),
        [float]($hexOuterR * 2)
    )
    $shieldBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $shieldRect,
        [System.Drawing.Color]::FromArgb(250, 18, 24, 38),   # #121826
        [System.Drawing.Color]::FromArgb(250, 28, 20, 62),   # Deep cyber purple surface
        65.0
    )
    $g.FillPath($shieldBrush, $hexPath)
    $shieldBrush.Dispose()

    # Inner Hexagon Electric Violet (#7C3AED) border
    $ptsInner = New-HexPoints $cx $cy $hexInnerR
    $innerPen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(190, 124, 58, 237),
        [float]([Math]::Max(1.5, $size * 0.010 * $scale))
    )
    $innerPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPolygon($innerPen, $ptsInner)
    $innerPen.Dispose()

    # Outer Hexagon Neon Cyan (#00E5FF) crisp frame
    $outerPen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(255, 0, 229, 255),
        [float]([Math]::Max(2.0, $size * 0.018 * $scale))
    )
    $outerPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPolygon($outerPen, $ptsOuter)
    $outerPen.Dispose()

    # AI Neural Core inside the Hex Shield
    $coreOrbitR = [float]($size * 0.165 * $scale)
    $nodePts = New-HexPoints $cx $cy $coreOrbitR

    # Neural connections: outer ring + spokes to center + cross-synapses
    $synapseVioletPen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(185, 124, 58, 237),
        [float]([Math]::Max(1.2, $size * 0.008 * $scale))
    )
    $synapseCyanPen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(230, 0, 229, 255),
        [float]([Math]::Max(1.5, $size * 0.010 * $scale))
    )

    # Cross synapses & outer neural ring
    $g.DrawPolygon($synapseVioletPen, $nodePts)
    $g.DrawLine($synapseVioletPen, $nodePts[0], $nodePts[2])
    $g.DrawLine($synapseVioletPen, $nodePts[2], $nodePts[4])
    $g.DrawLine($synapseVioletPen, $nodePts[4], $nodePts[0])
    $g.DrawLine($synapseVioletPen, $nodePts[1], $nodePts[3])
    $g.DrawLine($synapseVioletPen, $nodePts[3], $nodePts[5])
    $g.DrawLine($synapseVioletPen, $nodePts[5], $nodePts[1])

    # Primary radial axons from center AI core to each node
    foreach ($np in $nodePts) {
        $g.DrawLine($synapseCyanPen, $cx, $cy, $np.X, $np.Y)
    }

    $synapseVioletPen.Dispose()
    $synapseCyanPen.Dispose()

    # Draw outer neural nodes
    $nodeR = [float]([Math]::Max(2.5, $size * 0.022 * $scale))
    $nodeGlowR = [float]($nodeR * 1.9)
    $nodeGlowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 229, 255))
    $nodeFillBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 229, 255))
    $nodeCenterBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 234, 242, 255))

    foreach ($np in $nodePts) {
        $g.FillEllipse($nodeGlowBrush, $np.X - $nodeGlowR, $np.Y - $nodeGlowR, $nodeGlowR * 2, $nodeGlowR * 2)
        $g.FillEllipse($nodeFillBrush, $np.X - $nodeR, $np.Y - $nodeR, $nodeR * 2, $nodeR * 2)
        $innerDot = $nodeR * 0.48
        $g.FillEllipse($nodeCenterBrush, $np.X - $innerDot, $np.Y - $innerDot, $innerDot * 2, $innerDot * 2)
    }

    # Central AI Neural Core Node (Glowing Cyan + Electric Violet Ring + White-Cyan Nucleus)
    $centerGlowR = [float]($size * 0.095 * $scale)
    $centerGlowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(95, 0, 229, 255))
    $g.FillEllipse($centerGlowBrush, $cx - $centerGlowR, $cy - $centerGlowR, $centerGlowR * 2, $centerGlowR * 2)
    $centerGlowBrush.Dispose()

    $centerVioletR = [float]($size * 0.058 * $scale)
    $centerVioletBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 124, 58, 237))
    $g.FillEllipse($centerVioletBrush, $cx - $centerVioletR, $cy - $centerVioletR, $centerVioletR * 2, $centerVioletR * 2)
    $centerVioletBrush.Dispose()

    $centerCoreR = [float]($size * 0.040 * $scale)
    $g.FillEllipse($nodeFillBrush, $cx - $centerCoreR, $cy - $centerCoreR, $centerCoreR * 2, $centerCoreR * 2)

    $nucleusR = [float]($size * 0.020 * $scale)
    $g.FillEllipse($nodeCenterBrush, $cx - $nucleusR, $cy - $nucleusR, $nucleusR * 2, $nucleusR * 2)

    $nodeGlowBrush.Dispose()
    $nodeFillBrush.Dispose()
    $nodeCenterBrush.Dispose()
    $hexPath.Dispose()
}

# 1. Generate or load master 1024x1024 PNG in assets/branding/app_icon_cyberpunk_vA.png
if ($ForceRegenerateMaster -or -not (Test-Path $ResolvedMasterPath)) {
    $bmp1024 = New-Object System.Drawing.Bitmap(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g1024 = [System.Drawing.Graphics]::FromImage($bmp1024)
    Draw-CyberpunkShieldAndCore -g $g1024 -size 1024 -transparentBg $false
    $g1024.Dispose()
    $bmp1024.Save($ResolvedMasterPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp1024.Dispose()
    Write-Output "Generated master icon: $ResolvedMasterPath"
} else {
    Write-Output "Using existing master icon: $ResolvedMasterPath"
}

# Copy master icon to workspace vero_icon.png as well
Copy-Item -Path $ResolvedMasterPath -Destination (Join-Path $WorkspaceRoot "vero_icon.png") -Force

$masterImage = [System.Drawing.Image]::FromFile($ResolvedMasterPath)

function Save-ResizedPng([System.Drawing.Image]$src, [string]$destPath, [int]$w, [int]$h, [bool]$roundMask = $false) {
    $dir = Split-Path -Parent $destPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $outBmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($outBmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    if ($roundMask) {
        $clipPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $clipPath.AddEllipse(0, 0, $w, $h)
        $g.SetClip($clipPath)
        $g.DrawImage($src, 0, 0, $w, $h)
        $g.ResetClip()
        $rimPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 0, 229, 255), [float]([Math]::Max(1.0, $w * 0.03)))
        $g.DrawEllipse($rimPen, [float]($w * 0.015), [float]($h * 0.015), [float]($w * 0.97), [float]($h * 0.97))
        $rimPen.Dispose()
        $clipPath.Dispose()
    } else {
        $g.DrawImage($src, 0, 0, $w, $h)
    }

    $g.Dispose()
    $outBmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $outBmp.Dispose()
}

# 2. Android Mipmap Icons (Standard, Round, and Adaptive Foreground)
$androidRes = Join-Path $ProjectRoot "android\app\src\main\res"
$densities = @(
    @{ Folder = "mipmap-mdpi";    Size = 48;  FgSize = 108 },
    @{ Folder = "mipmap-hdpi";    Size = 72;  FgSize = 162 },
    @{ Folder = "mipmap-xhdpi";   Size = 96;  FgSize = 216 },
    @{ Folder = "mipmap-xxhdpi";  Size = 144; FgSize = 324 },
    @{ Folder = "mipmap-xxxhdpi"; Size = 192; FgSize = 432 }
)

foreach ($d in $densities) {
    $folderPath = Join-Path $androidRes $d.Folder
    Save-ResizedPng -src $masterImage -destPath (Join-Path $folderPath "ic_launcher.png") -w $d.Size -h $d.Size -roundMask $false
    Save-ResizedPng -src $masterImage -destPath (Join-Path $folderPath "ic_launcher_round.png") -w $d.Size -h $d.Size -roundMask $true

    # Adaptive foreground (transparent background with safe-zone centered shield)
    $fgBmp = New-Object System.Drawing.Bitmap($d.FgSize, $d.FgSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $fgG = [System.Drawing.Graphics]::FromImage($fgBmp)
    Draw-CyberpunkShieldAndCore -g $fgG -size $d.FgSize -transparentBg $true
    $fgG.Dispose()
    $fgBmp.Save((Join-Path $folderPath "ic_launcher_foreground.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $fgBmp.Dispose()
}

# Android Adaptive Icon XMLs
$anyDpiDir = Join-Path $androidRes "mipmap-anydpi-v26"
if (-not (Test-Path $anyDpiDir)) {
    New-Item -ItemType Directory -Path $anyDpiDir -Force | Out-Null
}
$adaptiveXml = @"
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"@
Set-Content -Path (Join-Path $anyDpiDir "ic_launcher.xml") -Value $adaptiveXml -Encoding UTF8
Set-Content -Path (Join-Path $anyDpiDir "ic_launcher_round.xml") -Value $adaptiveXml -Encoding UTF8

$valuesDir = Join-Path $androidRes "values"
$bgXml = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0B1020</color>
</resources>
"@
Set-Content -Path (Join-Path $valuesDir "ic_launcher_background.xml") -Value $bgXml -Encoding UTF8

# 3. iOS AppIcon.appiconset
$iosIconSetDir = Join-Path $ProjectRoot "ios\Runner\Assets.xcassets\AppIcon.appiconset"
if (-not (Test-Path $iosIconSetDir)) {
    New-Item -ItemType Directory -Path $iosIconSetDir -Force | Out-Null
}

$iosSizes = @(
    @{ Name = "Icon-App-20x20@1x.png";   Px = 20 },
    @{ Name = "Icon-App-20x20@2x.png";   Px = 40 },
    @{ Name = "Icon-App-20x20@3x.png";   Px = 60 },
    @{ Name = "Icon-App-29x29@1x.png";   Px = 29 },
    @{ Name = "Icon-App-29x29@2x.png";   Px = 58 },
    @{ Name = "Icon-App-29x29@3x.png";   Px = 87 },
    @{ Name = "Icon-App-40x40@1x.png";   Px = 40 },
    @{ Name = "Icon-App-40x40@2x.png";   Px = 80 },
    @{ Name = "Icon-App-40x40@3x.png";   Px = 120 },
    @{ Name = "Icon-App-60x60@2x.png";   Px = 120 },
    @{ Name = "Icon-App-60x60@3x.png";   Px = 180 },
    @{ Name = "Icon-App-76x76@1x.png";   Px = 76 },
    @{ Name = "Icon-App-76x76@2x.png";   Px = 152 },
    @{ Name = "Icon-App-83.5x83.5@2x.png"; Px = 167 },
    @{ Name = "Icon-App-1024x1024@1x.png"; Px = 1024 }
)

foreach ($item in $iosSizes) {
    Save-ResizedPng -src $masterImage -destPath (Join-Path $iosIconSetDir $item.Name) -w $item.Px -h $item.Px -roundMask $false
}

$contentsJson = @"
{
  "images" : [
    { "idiom" : "iphone", "scale" : "2x", "size" : "20x20", "filename" : "Icon-App-20x20@2x.png" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "20x20", "filename" : "Icon-App-20x20@3x.png" },
    { "idiom" : "iphone", "scale" : "1x", "size" : "29x29", "filename" : "Icon-App-29x29@1x.png" },
    { "idiom" : "iphone", "scale" : "2x", "size" : "29x29", "filename" : "Icon-App-29x29@2x.png" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "29x29", "filename" : "Icon-App-29x29@3x.png" },
    { "idiom" : "iphone", "scale" : "2x", "size" : "40x40", "filename" : "Icon-App-40x40@2x.png" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "40x40", "filename" : "Icon-App-40x40@3x.png" },
    { "idiom" : "iphone", "scale" : "2x", "size" : "60x60", "filename" : "Icon-App-60x60@2x.png" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "60x60", "filename" : "Icon-App-60x60@3x.png" },
    { "idiom" : "ipad", "scale" : "1x", "size" : "20x20", "filename" : "Icon-App-20x20@1x.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "20x20", "filename" : "Icon-App-20x20@2x.png" },
    { "idiom" : "ipad", "scale" : "1x", "size" : "29x29", "filename" : "Icon-App-29x29@1x.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "29x29", "filename" : "Icon-App-29x29@2x.png" },
    { "idiom" : "ipad", "scale" : "1x", "size" : "40x40", "filename" : "Icon-App-40x40@1x.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "40x40", "filename" : "Icon-App-40x40@2x.png" },
    { "idiom" : "ipad", "scale" : "1x", "size" : "76x76", "filename" : "Icon-App-76x76@1x.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "76x76", "filename" : "Icon-App-76x76@2x.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "83.5x83.5", "filename" : "Icon-App-83.5x83.5@2x.png" },
    { "idiom" : "ios-marketing", "scale" : "1x", "size" : "1024x1024", "filename" : "Icon-App-1024x1024@1x.png" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
"@
Set-Content -Path (Join-Path $iosIconSetDir "Contents.json") -Value $contentsJson -Encoding UTF8

# 4. Windows Multi-Size ICO (256, 64, 48, 32, 16)
function Write-MultiSizeIco([System.Drawing.Image]$src, [string]$icoPath) {
    $sizes = @(256, 64, 48, 32, 16)
    $pngBytesList = New-Object System.Collections.Generic.List[byte[]]

    foreach ($sz in $sizes) {
        $bmp = New-Object System.Drawing.Bitmap($sz, $sz, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($src, 0, 0, $sz, $sz)
        $g.Dispose()

        $ms = New-Object System.IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytesList.Add($ms.ToArray())
        $ms.Dispose()
        $bmp.Dispose()
    }

    $fs = [System.IO.File]::Create($icoPath)
    $bw = New-Object System.IO.BinaryWriter($fs)

    # ICONDIR header
    $bw.Write([uint16]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]$sizes.Count)

    $offset = 6 + (16 * $sizes.Count)
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $sz = $sizes[$i]
        $bytes = $pngBytesList[$i]
        $wByte = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }
        $bw.Write($wByte)
        $bw.Write($wByte)
        $bw.Write([byte]0)
        $bw.Write([byte]0)
        $bw.Write([uint16]1)
        $bw.Write([uint16]32)
        $bw.Write([uint32]$bytes.Length)
        $bw.Write([uint32]$offset)
        $offset += $bytes.Length
    }

    foreach ($bytes in $pngBytesList) {
        $bw.Write($bytes)
    }

    $bw.Flush()
    $bw.Close()
    $fs.Close()
}

$winIcoPath = Join-Path $ProjectRoot "windows\runner\resources\app_icon.ico"
$workspaceIcoPath = Join-Path $WorkspaceRoot "vero_icon.ico"
Write-MultiSizeIco -src $masterImage -icoPath $winIcoPath
Write-MultiSizeIco -src $masterImage -icoPath $workspaceIcoPath

$masterImage.Dispose()
Write-Output "ICON_PIPELINE_COMPLETE: Android (mipmap+adaptive), iOS (AppIcon.appiconset), Windows (app_icon.ico + vero_icon.ico) updated."
