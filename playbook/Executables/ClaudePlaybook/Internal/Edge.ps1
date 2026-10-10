<#
.SYNOPSIS
    Removes the Microsoft Edge browser, or installs it again.

.DESCRIPTION
    Remove   Uninstalls Edge with its own setup.exe. The Edge WebView2 Runtime
             is kept, because Windows features, Battle.net and many apps need
             it. Edge profiles (bookmarks, passwords) are left on disk.
             Nothing is removed when no other browser is installed, unless
             -Force is given, so the PC is never left without a browser.
             After a successful removal, an Edge Update policy stops Edge from
             being installed again (WebView2 still updates).
    Unblock  Undoes the settings Remove changed, so Edge can be installed again
             (used by "Restore Windows settings").
    Install  Unblock, then install Edge with winget.

    How Edge is made to uninstall (the EdgeUpdate uninstall string, the
    AllowUninstall value, the placeholder MicrosoftEdge.exe and launching
    setup.exe from an allowed parent process name) follows the method
    ReviOS documents in src/Executables/EDGE.ps1. This file is a rewrite.
#>
param(
    [Parameter(Mandatory)][ValidateSet('Remove', 'Unblock', 'Install')][string]$Action,
    [switch]$Force,
    [switch]$Silent
)

. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$Silent) { Assert-Admin -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters }
Start-Log -Name 'Edge'

$edgeAppId = '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
$edgeUpdateKey = 'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
$clientStateKey = "$edgeUpdateKey\ClientState\$edgeAppId"
$uninstallKey = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
$devKey = 'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev'
$policyKey = 'SOFTWARE\Policies\Microsoft\EdgeUpdate'
$policyName = "Install$edgeAppId"
$deprovisionedKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
$placeholderDir = Join-Path $env:SystemRoot 'SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
$placeholder = Join-Path $placeholderDir 'MicrosoftEdge.exe'
$edgeExe = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
)

function Test-EdgeInstalled {
    foreach ($p in $edgeExe) { if (Test-Path -LiteralPath $p) { return $true } }
    return $false
}

# Saves the original value the first time Remove touches it.
function Save-Original {
    param([string]$Key, [string]$SubKey, [string]$Name)
    $originals = Get-StateExtra -Key 'edgeOriginals'
    if ($null -eq $originals) { $originals = [pscustomobject]@{} }
    if ($originals.PSObject.Properties[$Key]) { return }
    $s = Get-RegistryValueState -Hive 'HKLM' -SubKey $SubKey -Name $Name
    $originals | Add-Member -NotePropertyName $Key -NotePropertyValue ([pscustomobject]@{
            subKey = $SubKey; name = $Name; existed = $s.existed; kind = $s.kind; data = $s.data
            createdRoot = Get-MissingRoot -Hive 'HKLM' -SubKey $SubKey
        }) -Force
    Set-StateExtra -Key 'edgeOriginals' -Value $originals -Overwrite
}

function Restore-Originals {
    $originals = Get-StateExtra -Key 'edgeOriginals'
    if ($null -eq $originals) { return }
    foreach ($prop in $originals.PSObject.Properties) {
        $o = $prop.Value
        try {
            if ($o.existed) {
                # Keys the Edge uninstaller deleted come back with Edge itself.
                if (!(Test-RegistryKey -Hive 'HKLM' -SubKey $o.subKey)) { continue }
                Set-RegistryValueState -Hive 'HKLM' -SubKey $o.subKey -Name $o.name -Kind $o.kind -Data $o.data
            }
            else {
                Remove-RegistryValueIfPresent -Hive 'HKLM' -SubKey $o.subKey -Name $o.name
                if (![string]::IsNullOrEmpty($o.createdRoot)) { Remove-CreatedKey -Hive 'HKLM' -SubKey $o.createdRoot }
            }
            Write-Log "Put back HKLM\$($o.subKey)\$($o.name)"
        }
        catch { Write-Log "Could not put back HKLM\$($o.subKey)\$($o.name): $($_.Exception.Message)" 'WARN' }
    }
    Set-StateExtra -Key 'edgeOriginals' -Value $null -Overwrite
}

function Invoke-EdgeUninstall {
    $setup = (Get-RegistryValueState -Hive 'HKLM' -SubKey $clientStateKey -Name 'UninstallString').data
    $setupArgs = (Get-RegistryValueState -Hive 'HKLM' -SubKey $clientStateKey -Name 'UninstallArguments').data
    if ([string]::IsNullOrEmpty($setup) -or [string]::IsNullOrEmpty($setupArgs) -or !(Test-Path -LiteralPath $setup)) {
        throw 'The Edge uninstaller was not found'
    }

    # Edge setup only agrees to uninstall when these hold.
    Save-Original -Key 'experiment' -SubKey $clientStateKey -Name 'experiment_control_labels'
    Remove-RegistryValueIfPresent -Hive 'HKLM' -SubKey $clientStateKey -Name 'experiment_control_labels'
    Save-Original -Key 'noRemove' -SubKey $uninstallKey -Name 'NoRemove'
    Remove-RegistryValueIfPresent -Hive 'HKLM' -SubKey $uninstallKey -Name 'NoRemove'
    Save-Original -Key 'allowUninstall' -SubKey $devKey -Name 'AllowUninstall'
    Set-RegistryValueState -Hive 'HKLM' -SubKey $devKey -Name 'AllowUninstall' -Kind 'DWord' -Data 1
    if (!(Test-Path -LiteralPath $placeholder)) {
        New-Item -ItemType Directory -Path $placeholderDir -Force | Out-Null
        New-Item -ItemType File -Path $placeholder -Force | Out-Null
        Set-StateExtra -Key 'edgePlaceholderCreated' -Value $true
    }

    # setup.exe accepts only a few parent process names; a copy of cmd.exe
    # named sihost.exe in a folder of its own is one of them.
    $parent = Join-Path $env:SystemRoot 'ImmersiveControlPanel\sihost.exe'
    $savedWindir = $env:windir
    try {
        Copy-Item -LiteralPath (Join-Path $env:SystemRoot 'System32\cmd.exe') -Destination $parent -Force
        $env:windir = ''
        $cmdLine = "/c `"`"$setup`" $setupArgs --force-uninstall`""
        Write-Log "Running the Edge uninstaller"
        $proc = Start-Process -FilePath $parent -ArgumentList $cmdLine -Wait -PassThru -WindowStyle Hidden
        Write-Log "Edge uninstaller exit code $($proc.ExitCode)"
    }
    finally {
        $env:windir = $savedWindir
        Remove-Item -LiteralPath $parent -Force -ErrorAction SilentlyContinue
    }
}

try {
    if ($Action -eq 'Remove') {
        if (!(Test-EdgeInstalled)) {
            Write-Log 'Edge is not installed'
        }
        else {
            $others = @(Get-OtherBrowsers)
            if ($others.Count -eq 0 -and !$Force) {
                Write-Log 'No other browser is installed, so Edge is kept. Install a browser and run "Remove Edge" from the ClaudePlaybook folder.' 'WARN'
                Wait-ForUser -Silent:$Silent
                exit 0
            }
            Write-Log "Other browsers found: $($others -join ', ')"
            Get-Process -Name 'msedge' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Invoke-EdgeUninstall
        }

        $flag = Get-RegistryValueState -Hive 'HKLM' -SubKey $edgeUpdateKey -Name 'IsEdgeStableUninstalled'
        if (!(Test-EdgeInstalled) -or ($flag.existed -and [int]$flag.data -eq 1)) {
            Save-Original -Key 'installPolicy' -SubKey $policyKey -Name $policyName
            Set-RegistryValueState -Hive 'HKLM' -SubKey $policyKey -Name $policyName -Kind 'DWord' -Data 0
            if (!(Test-RegistryKey -Hive 'HKLM' -SubKey $deprovisionedKey)) {
                $base = Get-BaseKey -Hive 'HKLM'
                try { $base.CreateSubKey($deprovisionedKey).Close() } finally { $base.Close() }
                Set-StateExtra -Key 'edgeDeprovisionedCreated' -Value $true
            }
            foreach ($dir in @((Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'), (Join-Path $env:PUBLIC 'Desktop'))) {
                Remove-Item -LiteralPath (Join-Path $dir 'Microsoft Edge.lnk') -Force -ErrorAction SilentlyContinue
            }
            Write-Log 'Edge is removed. The WebView2 Runtime is still installed.'
        }
        else {
            # Leave Windows as it was so nothing points at a half-removed Edge.
            Restore-Originals
            throw 'Edge is still installed after the uninstaller ran'
        }
    }
    else {
        Restore-Originals
        if (Get-StateExtra -Key 'edgeDeprovisionedCreated') {
            $base = Get-BaseKey -Hive 'HKLM'
            try { $base.DeleteSubKeyTree($deprovisionedKey, $false) } finally { $base.Close() }
            Set-StateExtra -Key 'edgeDeprovisionedCreated' -Value $null -Overwrite
        }
        if (Get-StateExtra -Key 'edgePlaceholderCreated') {
            Remove-Item -LiteralPath $placeholder -Force -ErrorAction SilentlyContinue
            Set-StateExtra -Key 'edgePlaceholderCreated' -Value $null -Overwrite
        }
        Write-Log 'Edge may be installed again'
        if ($Action -eq 'Unblock') { }
        elseif (Test-EdgeInstalled) { Write-Log 'Edge is already installed' }
        elseif (!(Invoke-Winget -Id 'Microsoft.Edge')) {
            Write-Log 'Download Edge from https://www.microsoft.com/edge instead.' 'WARN'
        }
    }
    Wait-ForUser -Silent:$Silent
    exit 0
}
catch {
    Write-Log "Edge $Action failed: $($_.Exception.Message)" 'ERROR'
    Wait-ForUser -Silent:$Silent
    exit 1
}
