param(
    [switch]$Doctor,
    [switch]$Analyze,
    [switch]$AcceptAndroidLicenses
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Get-FirstExistingPath {
    param(
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    return $null
}

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    $flutterCandidates = @(
        'C:\src\flutter\bin\flutter.bat',
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat"
    )
    $resolvedFlutter = Get-FirstExistingPath -Candidates $flutterCandidates
    if (-not $resolvedFlutter) {
        throw "Flutter SDK not found. Install Flutter and add it to PATH, or set C:\src\flutter\bin\flutter.bat."
    }
    $flutterCmd = $resolvedFlutter
}

$flutterBin = if ($flutterCmd -is [System.Management.Automation.ApplicationInfo]) { $flutterCmd.Path } else { [string]$flutterCmd }
$flutterRoot = Split-Path -Parent $flutterBin
$env:PATH = "$flutterRoot;$env:PATH"

$androidSdk = $env:ANDROID_HOME
if (-not $androidSdk) { $androidSdk = $env:ANDROID_SDK_ROOT }
if (-not $androidSdk) {
    $androidCandidates = @(
        "$env:LOCALAPPDATA\Android\Sdk",
        "$env:ProgramFiles(x86)\Android\Sdk",
        "$env:ProgramFiles\Android\Sdk",
        'C:\Users\ismail\AppData\Local\Android\Sdk'
    )
    $androidSdk = Get-FirstExistingPath -Candidates $androidCandidates
}

if (-not $androidSdk) {
    Write-Warning "Android SDK not detected automatically. Set ANDROID_HOME / ANDROID_SDK_ROOT before you run Android builds."
} else {
    $env:ANDROID_HOME = $androidSdk
    $env:ANDROID_SDK_ROOT = $androidSdk
}

Write-Host "Flutter: $flutterRoot"
if ($androidSdk) { Write-Host "Android SDK: $androidSdk" }

& "$flutterRoot\flutter.bat" pub get

if ($AcceptAndroidLicenses) {
    Write-Host "Accepting Android licenses..."
    & "$flutterRoot\flutter.bat" doctor --android-licenses
} elseif ($Doctor) {
    & "$flutterRoot\flutter.bat" doctor
}

if ($Analyze) {
    & "$flutterRoot\flutter.bat" analyze
}

Write-Host "Project dependencies installed successfully."
Write-Host "If Android doctor times out, run: flutter doctor --android-licenses"
Write-Host "Then run: flutter analyze"
Write-Host "Then run: flutter build apk --debug --split-per-abi --flavor full"
