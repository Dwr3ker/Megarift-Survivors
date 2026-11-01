<#
 Builds the Windows desktop game as a single .exe (the data is embedded) and zips it for a release.
 Usage:  powershell -File tools\build_windows.ps1 [-Godot path\to\godot_console.exe] [-Version 0.1.0-alpha.5]
 The Godot executable defaults to $env:GODOT, then to "godot" on the PATH (Godot 4.4.x with the Windows export template).
 Output: build\megarift-survivors-<Version>-windows.zip
#>
param(
    [string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "godot" }),
    [string]$Version = $(([regex]::Match((Get-Content (Join-Path (Split-Path -Parent $PSScriptRoot) "project.godot") -Raw), 'config/version="([^"]+)"')).Groups[1].Value)
)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $project "build\megarift-survivors-$Version-windows.exe"   # named after the version, so an old build is never mistaken for a new one
Remove-Item $exe -ErrorAction SilentlyContinue
& $Godot --headless --path $project --export-release "Windows Desktop" $exe
if (-not (Test-Path $exe)) { throw "Export failed: $exe was not created" }
$stage = Join-Path $project "build\windows_stage"
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item $exe (Join-Path $stage "Megarift Survivors.exe")
@"
Megarift Survivors $Version
Double-click "Megarift Survivors.exe". No install needed; progress is saved in
%APPDATA%\Godot\app_userdata\Megarift Survivors
Windows may show a SmartScreen warning because the file is not signed: choose "More info" then "Run anyway".
"@ | Set-Content (Join-Path $stage "README.txt")
$zip = Join-Path $project "build\megarift-survivors-$Version-windows.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip
Remove-Item $stage -Recurse -Force
Write-Host "Built $zip"
