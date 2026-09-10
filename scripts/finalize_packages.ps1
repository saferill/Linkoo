$winReleaseDir = 'c:\Users\mochs\Downloads\Compressed\Linko\app\build\windows\x64\runner\Release'
$setupSrc = 'c:\Users\mochs\Downloads\Compressed\Linko\build_output\windows\linko.exe'
$setupDst = 'c:\Users\mochs\Downloads\Compressed\Linko\build_output\windows\Linko-v1.0.0-Windows-x64-Setup.exe'
$webWin = 'C:\Users\mochs\Downloads\Compressed\Web Linko\downloads\windows'
$portableZip = 'c:\Users\mochs\Downloads\Compressed\Linko\build_output\windows\Linko-v1.0.0-Windows-x64-Portable.zip'

if (Test-Path $setupSrc) {
    Remove-Item $setupDst -Force -ErrorAction SilentlyContinue
    Copy-Item $setupSrc $setupDst -Force
    Copy-Item $setupDst "$webWin\" -Force
    Remove-Item $setupSrc -Force -ErrorAction SilentlyContinue
    Write-Host "Setup installer updated with custom wizard branding!" -ForegroundColor Green
}

Remove-Item $portableZip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "$winReleaseDir\*" -DestinationPath $portableZip -Force
Copy-Item $portableZip "$webWin\" -Force
Write-Host "Portable zip packaged!" -ForegroundColor Green

Write-Host "`nAll files in build_output:" -ForegroundColor Cyan
Get-ChildItem -Path 'c:\Users\mochs\Downloads\Compressed\Linko\build_output' -Recurse -File | Select-Object Name, @{Name='Size (MB)';Expression={[math]::Round($_.Length/1MB, 2)}}, LastWriteTime | Format-Table -AutoSize
