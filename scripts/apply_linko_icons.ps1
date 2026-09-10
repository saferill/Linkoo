Add-Type -AssemblyName System.Drawing

$srcIconPath = (Resolve-Path "Logo\Logo Icon.png").Path
$srcBmp = [System.Drawing.Bitmap]::FromFile($srcIconPath)

function Resize-Image($source, $width, $height, $targetPath, [float]$scale = 1.0) {
    $dest = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    
    if ($scale -lt 1.0) {
        $drawW = [int]($width * $scale)
        $drawH = [int]($height * $scale)
        $drawX = [int](($width - $drawW) / 2)
        $drawY = [int](($height - $drawH) / 2)
        $g.DrawImage($source, $drawX, $drawY, $drawW, $drawH)
    } else {
        $g.DrawImage($source, 0, 0, $width, $height)
    }
    $g.Dispose()
    
    $dir = [System.IO.Path]::GetDirectoryName($targetPath)
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $dest.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dest.Dispose()
}

Write-Host "1. Updating app/assets/img/..."
Resize-Image $srcBmp 512 512 "app\assets\img\logo-512.png"
Resize-Image $srcBmp 512 512 "app\assets\img\logo-512-white.png"
Resize-Image $srcBmp 256 256 "app\assets\img\logo-256.png"
Resize-Image $srcBmp 128 128 "app\assets\img\logo-128.png"
Resize-Image $srcBmp 32 32 "app\assets\img\logo-32.png"
Resize-Image $srcBmp 32 32 "app\assets\img\logo-32-white.png"
Resize-Image $srcBmp 32 32 "app\assets\img\logo-32-black.png"

Write-Host "2. Updating Android launcher & notification icons..."
$densities = @(
    @{ Name = "mdpi"; Size = 48; ForeSize = 108 },
    @{ Name = "hdpi"; Size = 72; ForeSize = 162 },
    @{ Name = "xhdpi"; Size = 96; ForeSize = 216 },
    @{ Name = "xxhdpi"; Size = 144; ForeSize = 324 },
    @{ Name = "xxxhdpi"; Size = 192; ForeSize = 432 }
)

foreach ($d in $densities) {
    $resDir = "app\android\app\src\main\res\mipmap-$($d.Name)"
    Resize-Image $srcBmp $d.Size $d.Size "$resDir\ic_launcher.png"
    Resize-Image $srcBmp $d.Size $d.Size "$resDir\ic_launcher_round.png"
    Resize-Image $srcBmp $d.ForeSize $d.ForeSize "$resDir\ic_launcher_foreground.png" 0.68
    Resize-Image $srcBmp $d.ForeSize $d.ForeSize "$resDir\ic_launcher_monochrome.png" 0.68
    Resize-Image $srcBmp $d.ForeSize $d.ForeSize "$resDir\ic_launcher_quicktile_foreground.png" 0.68
}

Resize-Image $srcBmp 512 512 "app\android\app\src\main\ic_launcher-playstore.png"
Resize-Image $srcBmp 320 180 "app\android\app\src\main\res\drawable\banner.png" 0.70

Write-Host "3. Updating web icons & favicon..."
Resize-Image $srcBmp 192 192 "app\web\icons\Icon-192.png"
Resize-Image $srcBmp 512 512 "app\web\icons\Icon-512.png"
Resize-Image $srcBmp 192 192 "app\web\icons\Icon-maskable-192.png" 0.75
Resize-Image $srcBmp 512 512 "app\web\icons\Icon-maskable-512.png" 0.75
Resize-Image $srcBmp 32 32 "app\web\favicon.png"

Write-Host "4. Generating Windows .ico files..."
$icoSizes = @(16, 32, 48, 64, 128, 256)
$icoPngList = @()
foreach ($sz in $icoSizes) {
    $tmpFile = "$PSScriptRoot\temp_ico_$sz.png"
    Resize-Image $srcBmp $sz $sz $tmpFile
    $icoPngList += $tmpFile
}

# Multi-resolution ICO generator
$targetIcoPath = (Resolve-Path "app\assets\packaging\logo.ico").Path
$icoStream = [System.IO.File]::Create($targetIcoPath)
$icoWriter = New-Object System.IO.BinaryWriter $icoStream

$icoWriter.Write([uint16]0)
$icoWriter.Write([uint16]1)
$icoWriter.Write([uint16]$icoSizes.Count)

$offset = 6 + (16 * $icoSizes.Count)
$pngBytesList = @()

for ($i = 0; $i -lt $icoSizes.Count; $i++) {
    $bytes = [System.IO.File]::ReadAllBytes($icoPngList[$i])
    $pngBytesList += ,$bytes
    $sz = $icoSizes[$i]
    $wByte = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }
    $hByte = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }
    
    $icoWriter.Write($wByte) # Width
    $icoWriter.Write($hByte) # Height
    $icoWriter.Write([byte]0) # Color palette count
    $icoWriter.Write([byte]0) # Reserved
    $icoWriter.Write([uint16]1) # Color planes
    $icoWriter.Write([uint16]32) # Bits per pixel
    $icoWriter.Write([uint32]$bytes.Length) # Image data size
    $icoWriter.Write([uint32]$offset) # Offset
    $offset += $bytes.Length
}

foreach ($bytes in $pngBytesList) {
    $icoWriter.Write($bytes)
}

$icoWriter.Dispose()
$icoStream.Dispose()

foreach ($tmp in $icoPngList) {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}

Copy-Item "app\assets\packaging\logo.ico" "app\assets\img\logo.ico" -Force
Copy-Item "app\assets\packaging\logo.ico" "app\windows\runner\resources\app_icon.ico" -Force

Write-Host "5. Updating MSIX packaging image assets..."
$msixDir = "support\build\msix\content\Images"
if (Test-Path $msixDir) {
    Get-ChildItem $msixDir -Filter "*.png" | ForEach-Object {
        $name = $_.Name
        if ($name -match 'targetsize-(\d+)') {
            $sz = [int]$matches[1]
            Resize-Image $srcBmp $sz $sz $_.FullName
        } elseif ($name -match 'Square44x44Logo\.scale-(\d+)') {
            $scale = [int]$matches[1] / 100.0
            $sz = [int](44 * $scale)
            Resize-Image $srcBmp $sz $sz $_.FullName
        } elseif ($name -match 'StoreLogo\.scale-(\d+)') {
            $scale = [int]$matches[1] / 100.0
            $sz = [int](50 * $scale)
            Resize-Image $srcBmp $sz $sz $_.FullName
        } elseif ($name -match 'Wide310x150Logo\.scale-(\d+)') {
            $scale = [int]$matches[1] / 100.0
            $w = [int](310 * $scale)
            $h = [int](150 * $scale)
            Resize-Image $srcBmp $w $h $_.FullName 0.65
        } else {
            Resize-Image $srcBmp 150 150 $_.FullName
        }
    }
}

$srcBmp.Dispose()
Write-Host "All icons replaced with new Linko Logo successfully!"
