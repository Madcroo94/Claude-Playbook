<#
.SYNOPSIS
    Turns on the Windows features WSL 2 needs, or turns off the ones this
    playbook turned on.

.DESCRIPTION
    Enable   Turns on "Windows Subsystem for Linux" and "Virtual Machine
             Platform" and remembers which of them were off before. After a
             restart, run 'wsl --install' to add a Linux distribution
             (for example for CUDA work on Linux).
    Disable  Turns off only the features that Enable turned on.
#>
param(
    [Parameter(Mandatory)][ValidateSet('Enable', 'Disable')][string]$Action,
    [switch]$Silent
)

. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$Silent) { Assert-Admin -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters }
Start-Log -Name 'Wsl'

$features = @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')

try {
    if ($Action -eq 'Enable') {
        $enabledByUs = @(Get-StateExtra -Key 'wslEnabledByUs')
        foreach ($f in $features) {
            $info = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction Stop
            if ($info.State -eq 'Enabled' -or $info.State -eq 'EnablePending') { Write-Log "$f is already on"; continue }
            Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart -ErrorAction Stop | Out-Null
            if ($enabledByUs -notcontains $f) { $enabledByUs += $f }
            Write-Log "Turned on $f"
        }
        Set-StateExtra -Key 'wslEnabledByUs' -Value @($enabledByUs | Where-Object { $_ }) -Overwrite
        Write-Log "Restart Windows, then run 'wsl --install' to add a Linux distribution."
    }
    else {
        $enabledByUs = @(Get-StateExtra -Key 'wslEnabledByUs' | Where-Object { $_ })
        if ($enabledByUs.Count -eq 0) { Write-Log 'The playbook did not turn on any WSL feature; nothing to undo' }
        foreach ($f in $enabledByUs) {
            Disable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -ErrorAction Stop | Out-Null
            Write-Log "Turned off $f"
        }
        Set-StateExtra -Key 'wslEnabledByUs' -Value @() -Overwrite
    }
    Wait-ForUser -Silent:$Silent
    exit 0
}
catch {
    Write-Log "WSL $Action failed: $($_.Exception.Message)" 'ERROR'
    Wait-ForUser -Silent:$Silent
    exit 1
}
