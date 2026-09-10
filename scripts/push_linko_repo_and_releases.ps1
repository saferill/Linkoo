$ErrorActionPreference = "Continue"

$token = $env:GITHUB_TOKEN
$owner = "saferill"
$repo = "Linko"
$remoteUrl = "https://x-access-token:${token}@github.com/${owner}/${repo}.git"
$tag = "v1.0.0"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  PUSHING LINKO UPDATES & NEW RELEASES    " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Ensure Git is available
$minGitDir = "$env:TEMP\mingit_bin"
$gitCmd = "$minGitDir\cmd\git.exe"
if (-not (Test-Path $gitCmd)) {
    $hasGit = Get-Command git -ErrorAction SilentlyContinue
    if ($hasGit) { $gitCmd = "git" }
}

Write-Host "`n1. Git CLI located at: $gitCmd" -ForegroundColor Green

Write-Host "`n2. Staging and committing Linko codebase..." -ForegroundColor Cyan
& $gitCmd add .
& $gitCmd commit -m "feat: enable webrtc cloud signaling"

Write-Host "`n3. Pushing code to GitHub main branch..." -ForegroundColor Cyan
& $gitCmd push -u origin main

Write-Host "   Code successfully pushed to https://github.com/$owner/$repo!" -ForegroundColor Green

# 4. Fetch Release & Replace Assets via GitHub API
Write-Host "`n4. Checking GitHub Release $tag..." -ForegroundColor Cyan
$headers = @{
    "Authorization" = "token $token"
    "User-Agent" = "Linko-Release-Uploader"
    "Accept" = "application/vnd.github.v3+json"
}

$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/tags/$tag" -Headers $headers -Method Get
Write-Host "   Release found: $($release.html_url) (ID: $($release.id))" -ForegroundColor Green
$releaseId = $release.id

$artifacts = @(
    "$PSScriptRoot\..\build_output\windows\Linko-v1.0.0-Windows-x64-Setup.exe",
    "$PSScriptRoot\..\build_output\windows\Linko-v1.0.0-Windows-x64-Portable.zip",
    "$PSScriptRoot\..\build_output\android\Linko-v1.0.0-arm64-v8a-Release.apk",
    "$PSScriptRoot\..\build_output\android\Linko-v1.0.0-armeabi-v7a-Release.apk",
    "$PSScriptRoot\..\build_output\android\Linko-v1.0.0-x86_64-Release.apk",
    "$PSScriptRoot\..\build_output\android\Linko-v1.0.0-Universal-Release.apk",
    "$PSScriptRoot\..\build_output\android\Linko-v1.0.0-FOSS-arm64-Release.apk",
    "$PSScriptRoot\..\build_output\android\Linko-v1.0.0-FOSS-universal-Release.apk"
)

Write-Host "`n5. Updating all 8 release binaries on GitHub Releases..." -ForegroundColor Cyan

$existingAssets = @{}
if ($release.assets) {
    foreach ($a in $release.assets) {
        $existingAssets[$a.name] = $a.id
    }
}

foreach ($filePath in $artifacts) {
    if (-not (Test-Path $filePath)) {
        Write-Warning "Artifact not found: $filePath"
        continue
    }
    
    $fileName = [System.IO.Path]::GetFileName($filePath)
    
    # If old asset exists, delete it first to upload fresh build
    if ($existingAssets.ContainsKey($fileName)) {
        $oldId = $existingAssets[$fileName]
        Write-Host "   Deleting old asset $fileName (ID: $oldId)..." -ForegroundColor Gray
        try {
            Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/assets/$oldId" -Headers $headers -Method Delete | Out-Null
        } catch {}
    }
    
    Write-Host "   Uploading new $fileName ($([math]::Round((Get-Item $filePath).Length / 1MB, 2)) MB)..." -ForegroundColor Yellow
    
    $uploadUri = "https://uploads.github.com/repos/$owner/$repo/releases/$releaseId/assets?name=$fileName"
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    
    $uploadHeaders = @{
        "Authorization" = "token $token"
        "User-Agent" = "Linko-Release-Uploader"
        "Content-Type" = "application/octet-stream"
    }
    
    $uploaded = Invoke-RestMethod -Uri $uploadUri -Headers $uploadHeaders -Method Post -Body $fileBytes
    Write-Host "   -> Successfully Uploaded: $fileName" -ForegroundColor Green
}

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host "  ALL CODE AND RELEASES UPDATED!                       " -ForegroundColor Green
Write-Host "  Repository: https://github.com/$owner/$repo          " -ForegroundColor Green
Write-Host "  Releases:   $($release.html_url)                     " -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
