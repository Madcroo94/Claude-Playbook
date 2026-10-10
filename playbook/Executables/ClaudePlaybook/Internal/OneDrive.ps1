<#
.SYNOPSIS
    Uninstalls OneDrive, or installs it again.

.DESCRIPTION
    Remove   Uninstalls OneDrive with its own setup program, for the signed-in
             user and for all users when it was installed per machine. It is
             left alone when any profile is signed in to OneDrive or has files
             in its OneDrive folder (unless -Force), because files kept only in
             the cloud stop opening once OneDrive is gone. Files on disk are
             never deleted.
    Install  Installs OneDrive with winget.

    The same "keep OneDrive when files exist" rule is used by AtlasOS
    (src/playbook/Executables/ONED.cmd). This file is a rewrite.
#>
param(
    [Parameter(Mandatory)][ValidateSet('Remove', 'Install')][string]$Action,
    [switch]$Force,
    [switch]$Silent
)

. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$Silent) { Assert-Admin -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters }
Start-Log -Name 'OneDrive'

function Get-OneDriveInUse {
    $reasons = @()
    foreach ($p in (Get-UserProfiles | Where-Object { !$_.IsDefault })) {
        $folder = Join-Path $p.ProfilePath 'OneDrive'
        if ((Test-Path -LiteralPath $folder) -and (Get-ChildItem -LiteralPath $folder -Force -ErrorAction SilentlyContinue | Select-Object -First 1)) {
            $reasons += "$folder has files"
        }
        if (Test-RegistryKey -Hive 'HKU' -SubKey "$($p.Id)\SOFTWARE\Microsoft\OneDrive\Accounts") {
            $base = Get-BaseKey -Hive 'HKU'
            try {
                $k = $base.OpenSubKey("$($p.Id)\SOFTWARE\Microsoft\OneDrive\Accounts")
                try {
                    foreach ($name in $k.GetSubKeyNames()) {
                        $a = $k.OpenSubKey($name)
                        try { if ($a.GetValue('UserFolder')) { $reasons += "$($p.ProfilePath) is signed in to OneDrive ($name)" } }
                        finally { $a.Close() }
                    }
                }
                finally { $k.Close() }
            }
            finally { $base.Close() }
        }
    }
    return $reasons
}

function Get-Setups {
    $list = @()
    $userUninstall = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe' -ErrorAction SilentlyContinue
    if ($userUninstall -and $userUninstall.UninstallString -match '^\s*"?([^"]+?\.exe)"?\s*(.*)$' -and (Test-Path -LiteralPath $Matches[1])) {
        $list += , @($Matches[1], @('/uninstall'))
    }
    foreach ($exe in @((Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'), (Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe'))) {
        if (Test-Path -LiteralPath $exe) { $list += , @($exe, @('/uninstall')); break }
    }
    $machine = Get-ChildItem -Path (Join-Path $env:ProgramFiles 'Microsoft OneDrive') -Filter 'OneDriveSetup.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($machine) { $list += , @($machine.FullName, @('/uninstall', '/allusers')) }
    return $list
}

try {
    if ($Action -eq 'Remove') {
        $inUse = @(Get-OneDriveInUse)
        if ($inUse.Count -gt 0 -and !$Force) {
            foreach ($r in $inUse) { Write-Log $r 'WARN' }
            Write-Log 'OneDrive is kept so no files are lost. Move your files out of OneDrive, sign out, then run "Remove OneDrive" from the ClaudePlaybook folder.' 'WARN'
            Wait-ForUser -Silent:$Silent
            exit 0
        }
        Get-Process -Name 'OneDrive' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        $setups = @(Get-Setups)
        if ($setups.Count -eq 0) { Write-Log 'OneDrive is not installed' }
        foreach ($s in $setups) {
            Write-Log "Running $($s[0]) $($s[1] -join ' ')"
            $code = Invoke-Program -FilePath $s[0] -ArgumentList $s[1] -Hidden
            Write-Log "Exit code $code"
        }
        foreach ($lnk in @((Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'))) {
            Remove-Item -LiteralPath $lnk -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        if (!(Invoke-Winget -Id 'Microsoft.OneDrive')) {
            Write-Log 'Download OneDrive from https://www.microsoft.com/microsoft-365/onedrive/download instead.' 'WARN'
        }
    }
    Wait-ForUser -Silent:$Silent
    exit 0
}
catch {
    Write-Log "OneDrive $Action failed: $($_.Exception.Message)" 'ERROR'
    Wait-ForUser -Silent:$Silent
    exit 1
}
