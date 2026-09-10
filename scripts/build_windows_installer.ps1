$iscc = "C:\Program Files\Inno Setup 7\ISCC.exe"
$payloadDir = "c:\Users\mochs\Downloads\Compressed\Linko\inno_temp"
$resultDir = "c:\Users\mochs\Downloads\Compressed\Linko\build_output\windows"
$webWinDir = "C:\Users\mochs\Downloads\Compressed\Web Linko\downloads\windows"

# Close any open installer processes
Get-Process | Where-Object { $_.Name -like "*Linko*Setup*" -or $_.Name -like "*Setup*Linko*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300

Remove-Item $payloadDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $payloadDir | Out-Null
New-Item -ItemType Directory -Force -Path $resultDir | Out-Null
New-Item -ItemType Directory -Force -Path $webWinDir | Out-Null

Copy-Item "c:\Users\mochs\Downloads\Compressed\Linko\app\build\windows\x64\runner\Release\*" -Destination $payloadDir -Recurse
Copy-Item "c:\Users\mochs\Downloads\Compressed\Linko\app\assets\packaging\logo.ico" -Destination "$payloadDir\logo.ico" -Force -ErrorAction SilentlyContinue
Copy-Item "c:\Users\mochs\Downloads\Compressed\Linko\app\assets\packaging\wizard_small.bmp" -Destination "$payloadDir\wizard_small.bmp" -Force -ErrorAction SilentlyContinue
Copy-Item "c:\Users\mochs\Downloads\Compressed\Linko\app\assets\packaging\wizard_large.bmp" -Destination "$payloadDir\wizard_large.bmp" -Force -ErrorAction SilentlyContinue
Copy-Item "c:\Users\mochs\Downloads\Compressed\Linko\support\build\windows\x64\*" -Destination $payloadDir -Recurse -ErrorAction SilentlyContinue

& $iscc /DSkipSignTool /DSkipMsixHelper "/DPayloadDir=$payloadDir" "/DResultDir=$resultDir" "c:\Users\mochs\Downloads\Compressed\Linko\support\scripts\compile_windows_exe-inno.iss"

$setupExe = "$resultDir\Linko-v1.0.0-Windows-x64-Setup.exe"
if (Test-Path $setupExe) {
    Copy-Item $setupExe "$webWinDir\" -Force
}

Remove-Item $payloadDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Windows Installer build finished successfully!"
