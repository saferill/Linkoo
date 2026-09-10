$ErrorActionPreference = "Stop"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  LINKO FULL MULTI-PLATFORM BUILD SYSTEM  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Apply latest Linko icons
Write-Host "`n[STEP 1/4] Applying Latest Linko Brand Icons..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\apply_linko_icons.ps1"

# 2. Build Windows Release
Write-Host "`n[STEP 2/4] Building Windows x64 Release..." -ForegroundColor Yellow
Remove-Item "$PSScriptRoot\app\build\windows\x64\runner\Release" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$PSScriptRoot\app\build\windows\x64\runner\linko_app.dir" -Recurse -Force -ErrorAction SilentlyContinue
Push-Location "$PSScriptRoot\app"
flutter build windows --release
Pop-Location

# Package Windows Portable
$winReleaseDir = "$PSScriptRoot\app\build\windows\x64\runner\Release"
$winOutDir = "$PSScriptRoot\build_output\windows"
$webWinDir = "C:\Users\mochs\Downloads\Compressed\Web Linko\downloads\windows"

New-Item -ItemType Directory -Force -Path $winOutDir | Out-Null
New-Item -ItemType Directory -Force -Path $webWinDir | Out-Null

$portableZip = "$winOutDir\Linko-v1.0.0-Windows-x64-Portable.zip"
Remove-Item $portableZip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "$winReleaseDir\*" -DestinationPath $portableZip -Force
Copy-Item $portableZip "$webWinDir\" -Force
Write-Host "  -> Created Portable Zip: $portableZip" -ForegroundColor Green

# Package Windows Inno Setup
& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\build_windows_installer.ps1"

# 3. Build Android APKs
Write-Host "`n[STEP 3/4] Building Android APKs..." -ForegroundColor Yellow
$jdkPath = 'C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot'
$env:JAVA_HOME = $jdkPath
$env:ANDROID_HOME = 'C:\Users\mochs\AppData\Local\Android\Sdk'

Push-Location "$PSScriptRoot\app"
Write-Host "  -> Compiling Split ABI APKs..." -ForegroundColor DarkYellow
flutter build apk --release --split-per-abi

Write-Host "  -> Compiling Universal APK..." -ForegroundColor DarkYellow
flutter build apk --release
Pop-Location

# Copy and Organize Android APKs
$apkSourceDir = "$PSScriptRoot\app\build\app\outputs\flutter-apk"
$apkOutDir = "$PSScriptRoot\build_output\android"
$webApkDir = "C:\Users\mochs\Downloads\Compressed\Web Linko\downloads\android"

New-Item -ItemType Directory -Force -Path $apkOutDir | Out-Null
New-Item -ItemType Directory -Force -Path $webApkDir | Out-Null

$apkMappings = @(
    @{ Src = "app-arm64-v8a-release.apk"; Dst = "Linko-v1.0.0-arm64-v8a-Release.apk" },
    @{ Src = "app-armeabi-v7a-release.apk"; Dst = "Linko-v1.0.0-armeabi-v7a-Release.apk" },
    @{ Src = "app-x86_64-release.apk"; Dst = "Linko-v1.0.0-x86_64-Release.apk" },
    @{ Src = "app-release.apk"; Dst = "Linko-v1.0.0-Universal-Release.apk" },
    @{ Src = "app-arm64-v8a-release.apk"; Dst = "Linko-v1.0.0-FOSS-arm64-Release.apk" },
    @{ Src = "app-release.apk"; Dst = "Linko-v1.0.0-FOSS-universal-Release.apk" }
)

foreach ($item in $apkMappings) {
    $srcPath = "$apkSourceDir\$($item.Src)"
    $dstPath = "$apkOutDir\$($item.Dst)"
    if (Test-Path $srcPath) {
        Copy-Item $srcPath $dstPath -Force
        Copy-Item $dstPath "$webApkDir\" -Force
        Write-Host "  -> Created APK: $($item.Dst)" -ForegroundColor Green
    } else {
        Write-Warning "Source APK missing: $srcPath"
    }
}

$sw.Stop()
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  ALL BUILDS COMPLETED IN $($sw.Elapsed.ToString('mm\:ss'))" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Get-ChildItem -Path "$PSScriptRoot\build_output" -Recurse -File | Select-Object Name, @{Name="Size (MB)";Expression={[math]::Round($_.Length/1MB, 2)}}, LastWriteTime | Format-Table -AutoSize
