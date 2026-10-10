<#
.SYNOPSIS
    Records the current value of every registry value, service start type and
    scheduled task the playbook is about to change (listed in manifest.json).

.DESCRIPTION
    Runs at the start of the playbook, before anything is changed. Values that
    are already in Backup\state.json are kept, so a second run of the playbook
    never overwrites the original Windows values. Restore.ps1 puts them back.
    Exit code 1 means the backup failed and the playbook must stop.
#>
param([switch]$Silent)

. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Log -Name 'Backup'

try {
    $manifest = Get-Manifest
    $state = Get-State
    $known = @{}
    foreach ($r in $state.registry) { $known[$r.id] = $true }
    $added = 0

    $profiles = @(Get-UserProfiles)
    $mounts = @{}
    try {
        foreach ($entry in $manifest.registry) {
            $split = Split-RegistryPath -Path $entry.path
            if ($split[0] -eq 'HKCU') {
                foreach ($userProfile in (Select-ProfilesForScope -Profiles $profiles -Scope $entry.scope)) {
                    $id = "$($entry.path)|$($entry.name)|$($userProfile.Id)"
                    if ($known.ContainsKey($id)) { continue }
                    if (!$mounts.ContainsKey($userProfile.Id)) { $mounts[$userProfile.Id] = Mount-UserHive -UserProfile $userProfile }
                    $mount = $mounts[$userProfile.Id]
                    if (!$mount) { continue }
                    $sub = "$($mount.Root)\$($split[1])"
                    $s = Get-RegistryValueState -Hive 'HKU' -SubKey $sub -Name $entry.name
                    $state.registry += [pscustomobject]@{
                        id = $id; path = $entry.path; name = $entry.name; user = $userProfile.Id
                        existed = $s.existed; kind = $s.kind; data = $s.data
                        createdRoot = (Get-MissingRoot -Hive 'HKU' -SubKey $sub) -replace ('^' + [regex]::Escape($mount.Root) + '\\?'), ''
                    }
                    $known[$id] = $true
                    $added++
                }
            }
            else {
                $id = "$($entry.path)|$($entry.name)|"
                if ($known.ContainsKey($id)) { continue }
                $s = Get-RegistryValueState -Hive $split[0] -SubKey $split[1] -Name $entry.name
                $state.registry += [pscustomobject]@{
                    id = $id; path = $entry.path; name = $entry.name; user = ''
                    existed = $s.existed; kind = $s.kind; data = $s.data
                    createdRoot = Get-MissingRoot -Hive $split[0] -SubKey $split[1]
                }
                $known[$id] = $true
                $added++
            }
        }
    }
    finally {
        foreach ($m in $mounts.Values) { Dismount-UserHive -Mount $m }
    }

    $knownServices = @{}
    foreach ($s in $state.services) { $knownServices[$s.name] = $true }
    foreach ($svc in $manifest.services) {
        if ($knownServices.ContainsKey($svc.name)) { continue }
        $start = Get-ServiceStart -Name $svc.name
        $state.services += [pscustomobject]@{ name = $svc.name; existed = ($null -ne $start); start = $start }
        $knownServices[$svc.name] = $true
        $added++
    }

    $knownTasks = @{}
    foreach ($t in $state.tasks) { $knownTasks[$t.path] = $true }
    foreach ($task in $manifest.tasks) {
        if ($knownTasks.ContainsKey($task.path)) { continue }
        $state.tasks += [pscustomobject]@{ path = $task.path; state = (Get-TaskEnabledState -Path $task.path) }
        $knownTasks[$task.path] = $true
        $added++
    }

    Save-State -State $state
    Write-Log "Recorded $added new item(s); $($state.registry.Count) registry values, $($state.services.Count) services and $($state.tasks.Count) tasks are backed up in $script:StatePath"
    exit 0
}
catch {
    Write-Log "Backup failed: $($_.Exception.Message) at $($_.InvocationInfo.PositionMessage)" 'ERROR'
    exit 1
}
