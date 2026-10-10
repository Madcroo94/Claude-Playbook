<#
.SYNOPSIS
    Turns the Claude Playbook gaming power plan on or off.

.DESCRIPTION
    On   Copies Windows' hidden Ultimate Performance plan (High performance if
         Ultimate is unavailable) into a plan of our own, turns off USB
         selective suspend, USB 3 link power management and PCIe link state
         power management while plugged in, and makes it active. The plan
         that was active before is remembered.
    Off  Switches back to the plan that was active before (Balanced if
         unknown) and deletes our plan. Does nothing if our plan is absent.

    Based on the approach in AtlasOS (Executables/AtlasModules/Scripts/
    ScriptWrappers/DisablePowerSaving.ps1); device and NIC power tweaks from
    that script are left out because they are hard to undo.
#>
param(
    [Parameter(Mandatory)][ValidateSet('On', 'Off')][string]$Action,
    [switch]$Silent
)

. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$Silent) { Assert-Admin -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters }
Start-Log -Name 'PowerPlan'

$ourPlan = '5056a4d0-5050-45c6-837b-0cc878924173'
$ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$highPerformance = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
$balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'

function Get-ActivePlan {
    $out = (& powercfg.exe /getactivescheme) -join ' '
    if ($out -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { return $Matches[1].ToLower() }
    return $null
}

function Test-Plan([string]$Guid) {
    return [bool]((& powercfg.exe /list) -match [regex]::Escape($Guid))
}

try {
    if ($Action -eq 'On') {
        $active = Get-ActivePlan
        if ($active -and $active -ne $ourPlan) { Set-StateExtra -Key 'previousPowerPlan' -Value $active }

        if (!(Test-Plan $ourPlan)) {
            Invoke-Native -FilePath 'powercfg.exe' -ArgumentList @('/duplicatescheme', $ultimate, $ourPlan) | Out-Null
            if (!(Test-Plan $ourPlan)) {
                Write-Log 'Ultimate Performance is not available here; using High performance as the base' 'WARN'
                Invoke-Native -FilePath 'powercfg.exe' -ArgumentList @('/duplicatescheme', $highPerformance, $ourPlan) | Out-Null
            }
            if (!(Test-Plan $ourPlan)) { throw 'Could not create the power plan' }
        }
        & powercfg.exe /changename $ourPlan 'Claude Playbook (gaming)' 'High performance for games and AI work. Undo from the ClaudePlaybook folder.' | Out-Null

        # Plugged-in (AC) values only. Settings missing on a device are skipped.
        $settings = @(
            @('2a737441-1930-4402-8d77-b2bebba308a3', '48e6b7a6-50f5-4782-a5d4-53bb8f07e226', 0, 'USB selective suspend off'),
            @('2a737441-1930-4402-8d77-b2bebba308a3', 'd4e98f31-5ffe-4ce1-be31-1b38b384c009', 0, 'USB 3 link power management off'),
            @('501a4d13-42af-4429-9fd1-a8218c268e20', 'ee12f906-d277-404b-b6da-e5fa1a576df5', 0, 'PCIe link state power management off')
        )
        foreach ($s in $settings) {
            $code = Invoke-Native -FilePath 'powercfg.exe' -ArgumentList @('/setacvalueindex', $ourPlan, $s[0], $s[1], [string]$s[2])
            if ($code -eq 0) { Write-Log $s[3] } else { Write-Log "$($s[3]): not available on this device" }
        }
        Invoke-Native -FilePath 'powercfg.exe' -ArgumentList @('/setactive', $ourPlan) | Out-Null
        Write-Log "Active power plan: $(Get-ActivePlan)"
    }
    else {
        if (!(Test-Plan $ourPlan)) {
            Write-Log 'The gaming power plan is not installed; nothing to undo'
        }
        else {
            $previous = Get-StateExtra -Key 'previousPowerPlan'
            if (!$previous -or !(Test-Plan $previous)) { $previous = $balanced }
            Invoke-Native -FilePath 'powercfg.exe' -ArgumentList @('/setactive', $previous) | Out-Null
            Invoke-Native -FilePath 'powercfg.exe' -ArgumentList @('/delete', $ourPlan) | Out-Null
            Write-Log "Switched back to power plan $previous and removed the gaming plan"
        }
    }
    Wait-ForUser -Silent:$Silent
    exit 0
}
catch {
    Write-Log "Power plan $Action failed: $($_.Exception.Message)" 'ERROR'
    Wait-ForUser -Silent:$Silent
    exit 1
}
