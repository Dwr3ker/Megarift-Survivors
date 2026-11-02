<#
 Refreshes docs/move_visuals.png, a labelled contact sheet with one snapshot of every move: runs the game in a
 window for a few minutes on a throw-away profile (your save is never touched).
 Usage: powershell -File tools\capture_moves.ps1 [-Godot path\to\godot.exe]
#>
param([string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "godot" }))
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..'
& $Godot --path $root --resolution 1280x720 --script res://tools/capture_moves.gd
