<#
.SYNOPSIS
    Puts back the Windows values recorded by Backup.ps1.

.PARAMETER Group
    Restore only these groups (feature-page option names such as
    'remove-xbox', or baseline groups such as 'privacy'). See manifest.json.

.PARAMETER All
    Restore every group.

.PARAMETER OnlyIfUnchanged
    Skip any value that no longer holds what the playbook set, so a change you
    made yourself afterwards is kept. The playbook uses this when it re-runs
    with an option turned off.

.PARAMETER Silent
    No prompts (used by the playbook).
#>
param(
    [string[]]$Group = @(),
    [switch]$All,
    [switch]$OnlyIfUnchanged,
    [switch]$Silent
)

. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$Silent) { Assert-Admin -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters }
Start-Log -Name 'Restore'

function Test-Selected($g) { return ($All -or ($Group -contains $g)) }

# Groups with at least one value put back in this run.
$script:TouchedGroups = @{}

# Compares a value read from the registry with what the playbook wrote.
function Test-StillOurs {
    param($Current, $Entry)
    if ($Entry.operation -eq 'delete') { return !$Current.existed }
    if (!$Current.existed) { return $false }
    switch ($Entry.type) {
        'REG_DWORD' { return ([int64]$Current.data -band 0xFFFFFFFFL) -eq ([int64]$Entry.data -band 0xFFFFFFFFL) }
        'REG_QWORD' { return [int64]$Current.data -eq [int64]$Entry.data }
        default { return ([string]$Current.data) -eq ([string]$Entry.data) }
    }
}

function Restore-RegistryEntry {
    param($Hive, $SubKeyPrefix, $Entry, $Saved)
    $split = Split-RegistryPath -Path $Entry.path
    $sub = $split[1]
    if ($SubKeyPrefix) { $sub = "$SubKeyPrefix\$sub" }
    $where = "$($Entry.path)\$($Entry.name) $($Saved.user)".Trim()

    if ($OnlyIfUnchanged) {
        $current = Get-RegistryValueState -Hive $Hive -SubKey $sub -Name $Entry.name
        if (!(Test-StillOurs -Current $current -Entry $Entry)) { return }
    }
    $script:TouchedGroups[$Entry.group] = $true
    if ($Saved.existed) {
        Set-RegistryValueState -Hive $Hive -SubKey $sub -Name $Entry.name -Kind $Saved.kind -Data $Saved.data
        Write-Log "Restored $where"
    }
    else {
        Remove-RegistryValueIfPresent -Hive $Hive -SubKey $sub -Name $Entry.name
        if (![string]::IsNullOrEmpty($Saved.createdRoot)) {
            $root = $Saved.createdRoot
            if ($SubKeyPrefix) { $root = "$SubKeyPrefix\$root" }
            Remove-CreatedKey -Hive $Hive -SubKey $root
        }
        Write-Log "Removed $where (it did not exist before)"
    }
}

# Special undo steps for changes that are not plain registry values.
function Invoke-GroupHandler {
    param([string]$Name, $State)
    switch ($Name) {
        'gaming-power-plan' {
            & (Join-Path $PSScriptRoot 'PowerPlan.ps1') -Action Off -Silent
        }
        'disable-hibernation' {
            # On a re-run with the option off, only act if Fast Startup still
            # held the playbook's value, so a choice made by hand is kept.
            if ($OnlyIfUnchanged -and !$script:TouchedGroups.ContainsKey($Name)) { return }
            $saved = @($State.registry | Where-Object { $_.name -eq 'HibernateEnabled' -and $_.path -like '*\Control\Power' })[0]
            $now = Get-RegistryValueState -Hive 'HKLM' -SubKey 'SYSTEM\CurrentControlSet\Control\Power' -Name 'HibernateEnabled'
            if ($saved -and $saved.existed -and [int]$saved.data -eq 1 -and !($now.existed -and [int]$now.data -eq 1)) {
                Write-Log 'Turning hibernation back on'
                Invoke-Native -FilePath 'powercfg.exe' -ArgumentList @('/hibernate', 'on') | Out-Null
            }
        }
        'dev-python-alias' {
            if (!$OnlyIfUnchanged) {
                Write-Log 'To get the python Store shortcuts back, turn them on in Settings > Apps > Advanced app settings > App execution aliases.'
            }
        }
        'dev-wsl' {
            & (Join-Path $PSScriptRoot 'Wsl.ps1') -Action Disable -Silent
        }
        { $_ -in 'remove-bloat-apps', 'remove-xbox', 'remove-copilot', 'remove-phonelink', 'remove-edge' } {
            # Lets Windows and the Store bring the removed apps back. The apps
            # themselves are reinstalled from the Apps folder in the toolbox.
            if (!$OnlyIfUnchanged) {
                & (Join-Path $PSScriptRoot 'Appx.ps1') -Action Restore -Group $Name -Silent
                if ($Name -eq 'remove-edge') { & (Join-Path $PSScriptRoot 'Edge.ps1') -Action Unblock -Silent }
            }
        }
    }
}

try {
    if (!$All -and $Group.Count -eq 0) { throw 'Pass -Group <name> or -All.' }
    if (!(Test-Path -LiteralPath $script:StatePath)) {
        Write-Log 'No backup found, so there is nothing to restore.' 'WARN'
        Wait-ForUser -Silent:$Silent
        exit 0
    }
    $manifest = Get-Manifest
    $state = Get-State
    $failures = 0

    $saved = @{}
    foreach ($r in $state.registry) { $saved[$r.id] = $r }

    $profiles = @(Get-UserProfiles)
    $mounts = @{}
    try {
        foreach ($entry in $manifest.registry) {
            if (!(Test-Selected $entry.group) -or $entry.observeOnly) { continue }
            $split = Split-RegistryPath -Path $entry.path
            try {
                if ($split[0] -eq 'HKCU') {
                    foreach ($userProfile in $profiles) {
                        $rec = $saved["$($entry.path)|$($entry.name)|$($userProfile.Id)"]
                        if (!$rec) { continue }
                        if (!$mounts.ContainsKey($userProfile.Id)) { $mounts[$userProfile.Id] = Mount-UserHive -UserProfile $userProfile }
                        $mount = $mounts[$userProfile.Id]
                        if (!$mount) { $failures++; continue }
                        Restore-RegistryEntry -Hive 'HKU' -SubKeyPrefix $mount.Root -Entry $entry -Saved $rec
                    }
                }
                else {
                    $rec = $saved["$($entry.path)|$($entry.name)|"]
                    if ($rec) { Restore-RegistryEntry -Hive $split[0] -SubKeyPrefix '' -Entry $entry -Saved $rec }
                }
            }
            catch {
                $failures++
                Write-Log "Could not restore $($entry.path)\$($entry.name): $($_.Exception.Message)" 'WARN'
            }
        }
    }
    finally {
        foreach ($m in $mounts.Values) { Dismount-UserHive -Mount $m }
    }

    foreach ($svc in $manifest.services) {
        if (!(Test-Selected $svc.group)) { continue }
        $rec = @($state.services | Where-Object { $_.name -eq $svc.name })[0]
        if (!$rec -or !$rec.existed) { continue }
        $now = Get-ServiceStart -Name $svc.name
        if ($null -eq $now) { continue }
        if ($OnlyIfUnchanged -and $now -ne [int]$svc.startup) { continue }
        if ($now -eq [int]$rec.start) { continue }
        try {
            Set-RegistryValueState -Hive 'HKLM' -SubKey "SYSTEM\CurrentControlSet\Services\$($svc.name)" -Name 'Start' -Kind 'DWord' -Data ([int]$rec.start)
            Write-Log "Service $($svc.name) start type back to $($rec.start)"
        }
        catch {
            $failures++
            Write-Log "Could not restore service $($svc.name): $($_.Exception.Message)" 'WARN'
        }
    }

    foreach ($task in $manifest.tasks) {
        if (!(Test-Selected $task.group)) { continue }
        $rec = @($state.tasks | Where-Object { $_.path -eq $task.path })[0]
        if (!$rec -or !$rec.state) { continue }
        $now = Get-TaskEnabledState -Path $task.path
        if (!$now -or $now -eq $rec.state) { continue }
        if ($OnlyIfUnchanged -and $now -ne 'Disabled') { continue }
        try {
            Set-TaskEnabledState -Path $task.path -State $rec.state
            Write-Log "Task $($task.path) back to $($rec.state)"
        }
        catch {
            $failures++
            Write-Log "Could not restore task $($task.path): $($_.Exception.Message)" 'WARN'
        }
    }

    $groups = @($manifest.groups.PSObject.Properties.Name)
    foreach ($g in $groups) {
        if (Test-Selected $g) {
            try { Invoke-GroupHandler -Name $g -State $state }
            catch { $failures++; Write-Log "Undo step for $g failed: $($_.Exception.Message)" 'WARN' }
        }
    }

    if ($failures -gt 0) {
        Write-Log "$failures item(s) could not be restored. Protected settings such as Defender need the playbook itself: run it again in AME Wizard with the option turned off." 'WARN'
    }
    Write-Log 'Restore finished. Restart Windows for every change to take effect.'
    Wait-ForUser -Silent:$Silent
    exit 0
}
catch {
    Write-Log "Restore failed: $($_.Exception.Message)" 'ERROR'
    Wait-ForUser -Silent:$Silent
    exit 1
}
