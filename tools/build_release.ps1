<#
 Builds the signed RELEASE APK of Megarift Survivors (io.github.dwr3ker.megarift).

 The signing credentials are read from a private file OUTSIDE the project and passed to Godot through the
 environment variables Godot supports for headless exports, so the password is never written into the repository
 (export_presets.cfg holds no signing settings).

 Usage:  powershell -File tools\build_release.ps1 [-Out build\megarift-survivors-0.1.0.apk] [-Godot path\to\godot_console.exe]
 The Godot executable defaults to $env:GODOT, then to "godot" on the PATH (Godot 4.4.x with Android export templates).
#>
param(
    [string]$Credentials = "$env:USERPROFILE\Android\release\keystore-credentials.txt",
    [string]$Out = "$PSScriptRoot\..\build\megarift-survivors-0.1.0.apk",
    [string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "godot" })
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Credentials)) { throw "Credentials file not found: $Credentials" }
$c = @{}
Get-Content $Credentials | Where-Object { $_ -match '^\s*[a-z]+=' } | ForEach-Object { $k, $v = $_ -split '=', 2; $c[$k.Trim()] = $v.Trim() }
foreach ($k in 'keystore', 'alias', 'password') { if (-not $c[$k]) { throw "Missing '$k' in $Credentials" } }
if (-not (Test-Path $c['keystore'])) { throw "Keystore not found: $($c['keystore'])" }
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $c['keystore']
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $c['alias']
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $c['password']
$project = Join-Path $PSScriptRoot '..'
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& $Godot --headless --path $project --export-release "Android" $Out
if ($LASTEXITCODE -ne 0) { throw "Godot export failed ($LASTEXITCODE)" }
Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD, Env:GODOT_ANDROID_KEYSTORE_RELEASE_USER, Env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -ErrorAction SilentlyContinue
Write-Host "Built $Out"
