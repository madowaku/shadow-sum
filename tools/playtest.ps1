param(
    [string]$Pack = 'C:\Dev\Projects\noxsum-lab\exports\playtest_current.json',
    [string]$Stage = 'PT-001',
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$destination = Join-Path $projectRoot 'data\playtest\current.json'
$godot = 'C:\Users\hiro\Desktop\Godot_v4.7-stable_win64.exe'

if (-not (Test-Path -LiteralPath $Pack -PathType Leaf)) {
    throw "Playtest pack not found: $Pack`nGenerate it in noxsum-lab, or pass -Pack <json path>."
}
$source = (Resolve-Path -LiteralPath $Pack).Path
$parsed = Get-Content -LiteralPath $source -Raw -Encoding UTF8 | ConvertFrom-Json
$stages = if ($parsed -is [array]) { $parsed } elseif ($null -ne $parsed.stages) { @($parsed.stages) } else { @() }
if ($stages.Count -eq 0) { throw 'Playtest pack must contain a non-empty stage array.' }
$seen = [System.Collections.Generic.HashSet[string]]::new()
foreach ($entry in $stages) {
    $id = [string]$entry.id
    if ($id -notmatch '^PT-\d{3}$' -or -not $seen.Add($id)) { throw "Invalid or duplicate playtest ID: $id" }
    if ($null -eq $entry.solution -or $null -eq $entry.observations) { throw "Missing solution or observations in $id" }
}
if (-not $seen.Contains($Stage)) { throw "Stage $Stage is absent from this pack." }

New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
if ($source -ne $destination) {
    $temporary = "$destination.tmp"
    Copy-Item -LiteralPath $source -Destination $temporary -Force
    Move-Item -LiteralPath $temporary -Destination $destination -Force
}
Write-Host "Playtest pack: $($stages.Count) stages -> $destination"
if ($NoLaunch) { return }
if (-not (Test-Path -LiteralPath $godot -PathType Leaf)) { throw "Godot 4.7 executable not found: $godot" }
$game = Start-Process -FilePath $godot -ArgumentList @('--path', $projectRoot, '--', '--campaign=playtest', '--stage', $Stage) -PassThru
Write-Host "Godot playtest started: $Stage (PID $($game.Id))"
