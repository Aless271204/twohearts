param([switch]$Library)
$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $PSScriptRoot
$blenderExe = Join-Path $env:LOCALAPPDATA 'NidoTools\blender-4.5.9-windows-x64\blender.exe'
$scenePath = Join-Path $projectDir $(if ($Library) { 'design\blender\NIDO-biblioteca.blend' } else { 'design\blender\fitting\NIDO-cabeza-encaje.blend' })
if (!(Test-Path -LiteralPath $blenderExe)) { throw 'No se encuentra Blender en NidoTools.' }
if (!(Test-Path -LiteralPath $scenePath)) { throw 'No se encuentra el taller solicitado del proyecto.' }
& $blenderExe $scenePath
