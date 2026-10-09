# Package playbook\ into dist\<Name>-<Version>.apbx with 7-Zip (Windows).
# The archive holds the *contents* of the playbook folder, 7z format,
# password 'malte'. Run tools\validate.py first if Python is installed.
param([string]$Playbook = "$PSScriptRoot\..\playbook")

$ErrorActionPreference = 'Stop'
$sevenZip = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $sevenZip) { throw '7-Zip not found. Install it from https://7-zip.org/download.html' }

$Playbook = (Resolve-Path $Playbook).Path
[xml]$conf = Get-Content (Join-Path $Playbook 'playbook.conf')
$name = $conf.Playbook.Name.Trim() -replace ' ', '-'
$version = $conf.Playbook.Version.Trim()

$dist = Join-Path $PSScriptRoot '..\dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$out = Join-Path (Resolve-Path $dist).Path "$name-$version.apbx"
Remove-Item $out -ErrorAction SilentlyContinue

Push-Location $Playbook
try {
    & $sevenZip a -t7z -pmalte -mhe=on $out '*' '-xr!.gitkeep' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip failed with exit code $LASTEXITCODE" }
} finally { Pop-Location }
Write-Host "wrote $out"
