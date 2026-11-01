<#
 Refreshes the region picker snapshots (assets/regions/region_<0-9>.jpg): runs the game in a window for about
 half a minute on a throw-away profile, then turns the PNGs into small JPEGs.
 Usage: powershell -File tools\capture_regions.ps1 [-Godot path\to\godot.exe]
#>
param([string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "godot" }))
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..'
& $Godot --path $root --resolution 1280x720 --script res://tools/capture_regions.gd
python -c "import glob,os;from PIL import Image;[ (Image.open(p).convert('RGB').save(p[:-4]+'.jpg',quality=82,optimize=True), os.remove(p)) for p in glob.glob(os.path.join(r'$root','assets','regions','*.png'))]"
& $Godot --headless --path $root --import
