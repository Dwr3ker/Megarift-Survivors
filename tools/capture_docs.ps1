<#
 Refreshes the screenshots for docs/Megarift-Survivors-features.pdf and rebuilds the PDF.
 It runs the game in a window for about a minute (it uses a throw-away profile, never your save).
 Usage: powershell -File tools\capture_docs.ps1 [-Godot path\to\godot.exe]
#>
param([string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "godot" }))
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..'
& $Godot --path $root --resolution 1280x720 --script res://tools/capture_docs.gd
python (Join-Path $PSScriptRoot 'optimize_screens.py')
python (Join-Path $PSScriptRoot 'make_features_pdf.py')
