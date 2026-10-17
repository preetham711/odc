# build_android_release.ps1
# Builds the Android release APK and copies it to releases/android/ODC_Tracker.apk
#
# Usage (from project root):
#   .\scripts\build_android_release.ps1
#
# Optional: set keystore password env vars before running:
#   $env:KEYSTORE_PASSWORD = "your_keystore_password"
#   $env:KEY_PASSWORD       = "your_key_password"

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReleasesDir = Join-Path $ProjectRoot "releases\android"
$DestApk     = Join-Path $ReleasesDir "ODC_Tracker.apk"
$SourceApk   = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ODC Tracker AI — Android Release Build" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure the releases folder exists
if (-not (Test-Path $ReleasesDir)) {
    New-Item -ItemType Directory -Path $ReleasesDir -Force | Out-Null
}

# Run flutter build
Write-Host "[1/3] Running: flutter build apk --release" -ForegroundColor Yellow
Set-Location $ProjectRoot
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: flutter build apk failed (exit code $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "Check the output above for details." -ForegroundColor Red
    exit 1
}

# Verify the APK was produced
if (-not (Test-Path $SourceApk)) {
    Write-Host ""
    Write-Host "ERROR: Expected APK not found at:" -ForegroundColor Red
    Write-Host "  $SourceApk" -ForegroundColor Red
    exit 1
}

# Copy to releases folder
Write-Host ""
Write-Host "[2/3] Copying APK to releases/android/ODC_Tracker.apk" -ForegroundColor Yellow
Copy-Item -Path $SourceApk -Destination $DestApk -Force

# Report file size
$SizeKB = [math]::Round((Get-Item $DestApk).Length / 1KB)
$SizeMB = [math]::Round((Get-Item $DestApk).Length / 1MB, 1)
Write-Host ""
Write-Host "[3/3] Done!" -ForegroundColor Green
Write-Host ""
Write-Host "  Output: releases\android\ODC_Tracker.apk" -ForegroundColor Green
Write-Host "  Size:   $SizeMB MB ($SizeKB KB)" -ForegroundColor Green
Write-Host ""
Write-Host "Transfer this file to an Android phone and tap it to install." -ForegroundColor Cyan
Write-Host "NOTE: This file CANNOT be installed on an iPhone." -ForegroundColor DarkYellow
Write-Host ""
