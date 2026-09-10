$jdkPath = 'C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot'
$env:JAVA_HOME = $jdkPath
[Environment]::SetEnvironmentVariable('JAVA_HOME', $jdkPath, 'User')
[Environment]::SetEnvironmentVariable('JAVA_HOME', $jdkPath, 'Process')
$env:ANDROID_HOME = 'C:\Users\mochs\AppData\Local\Android\Sdk'

Write-Host "Using JAVA_HOME: $env:JAVA_HOME"
Write-Host "Using ANDROID_HOME: $env:ANDROID_HOME"

cd app

Write-Host "1. Building split APKs (arm64-v8a, armeabi-v7a, x86_64)..."
flutter build apk --release --split-per-abi

Write-Host "2. Building Universal APK..."
flutter build apk --release

cd ..
Write-Host "Build complete!"
