<#
.SYNOPSIS
    Helps remove AppX apps so they stay gone, and brings them back.

.DESCRIPTION
    Snapshot     Records which app families are installed (before removal).
    Deprovision  Marks every family that disappeared since the snapshot as
                 deprovisioned, so feature updates do not reinstall it, and
                 remembers which option removed it.
                 https://learn.microsoft.com/windows/application-management/remove-provisioned-apps-during-update
    Remove       Removes apps by name pattern for all users (used for apps
                 that AME's !appx handles badly, such as Phone Link).
    Restore      Deletes the deprovisioned markers this playbook added, for one
                 group or all of them, so Windows may install the apps again.
    Reinstall    Restore, then reinstall a group's apps from the Microsoft Store.
#>
param(
    [Parameter(Mandatory)][ValidateSet('Snapshot', 'Deprovision', 'Remove', 'Restore', 'Reinstall')][string]$Action,
    [string]$Group = '',
    [string[]]$Pattern = @(),
    [switch]$Silent
)

. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$Silent) { Assert-Admin -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters }
Start-Log -Name 'Appx'

$deprovisionedKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned'
$snapshotPath = Join-Path $script:BackupDir 'appx-snapshot.txt'

# Microsoft Store product IDs for apps people ask to get back. Anything not
# listed here can be found by name in the Microsoft Store.
$storeIds = @{
    'remove-xbox'      = @('9MV0B5HZVK9Z', '9NZKPSTSNW4P', '9WZDNCRD1HKW')  # Xbox, Game Bar, Xbox Identity Provider
    'remove-copilot'   = @('9NHT9RB2F4HD')                                  # Microsoft Copilot
    'remove-phonelink' = @('9NMPJ99VJBWV')                                  # Phone Link
}

function Get-InstalledFamilies {
    $names = @()
    $names += (Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue).PackageFamilyName
    $names += (Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | ForEach-Object {
            # PackageName is Name_Version_Arch_ResourceId_PublisherId
            $parts = $_.PackageName.Split('_')
            if ($parts.Length -ge 5) { "$($parts[0])_$($parts[-1])" }
        })
    return @($names | Where-Object { $_ } | Sort-Object -Unique)
}

function Get-DeprovisionLog {
    $log = Get-StateExtra -Key 'deprovisioned'
    if ($null -eq $log) { return @() }
    return @($log)
}

try {
    switch ($Action) {
        'Snapshot' {
            New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
            $families = Get-InstalledFamilies
            Set-Content -LiteralPath $snapshotPath -Value $families -Encoding UTF8
            Write-Log "Recorded $($families.Count) installed app families"
        }
        'Deprovision' {
            if (!$Group) { throw '-Group is required' }
            if (!(Test-Path -LiteralPath $snapshotPath)) { throw 'No snapshot; run -Action Snapshot first' }
            $before = @(Get-Content -LiteralPath $snapshotPath)
            $now = Get-InstalledFamilies
            $log = Get-DeprovisionLog
            $already = @($log | ForEach-Object { $_.family })
            $base = Get-BaseKey -Hive 'HKLM'
            try {
                foreach ($family in ($before | Where-Object { $now -notcontains $_ -and $already -notcontains $_ })) {
                    $existed = Test-RegistryKey -Hive 'HKLM' -SubKey "$deprovisionedKey\$family"
                    if (!$existed) { $base.CreateSubKey("$deprovisionedKey\$family").Close() }
                    $log += [pscustomobject]@{ family = $family; group = $Group; createdKey = !$existed }
                    Write-Log "Removed and deprovisioned $family ($Group)"
                }
            }
            finally { $base.Close() }
            Set-StateExtra -Key 'deprovisioned' -Value $log -Overwrite
        }
        'Remove' {
            foreach ($p in $Pattern) {
                foreach ($pkg in @(Get-AppxPackage -AllUsers -Name $p -ErrorAction SilentlyContinue)) {
                    Write-Log "Removing $($pkg.PackageFullName)"
                    try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop }
                    catch { Write-Log "Could not remove $($pkg.PackageFullName): $($_.Exception.Message)" 'WARN' }
                }
                foreach ($prov in @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $p })) {
                    Write-Log "Removing provisioned $($prov.PackageName)"
                    try { Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null }
                    catch { Write-Log "Could not remove provisioned $($prov.PackageName): $($_.Exception.Message)" 'WARN' }
                }
            }
        }
        { $_ -in 'Restore', 'Reinstall' } {
            $log = Get-DeprovisionLog
            $keep = @()
            $base = Get-BaseKey -Hive 'HKLM'
            try {
                foreach ($item in $log) {
                    if ($Group -and $item.group -ne $Group) { $keep += $item; continue }
                    if ($item.createdKey -and (Test-RegistryKey -Hive 'HKLM' -SubKey "$deprovisionedKey\$($item.family)")) {
                        $base.DeleteSubKeyTree("$deprovisionedKey\$($item.family)", $false)
                        Write-Log "Windows may install $($item.family) again"
                    }
                }
            }
            finally { $base.Close() }
            Set-StateExtra -Key 'deprovisioned' -Value $keep -Overwrite

            if ($Action -eq 'Reinstall') {
                $ids = $storeIds[$Group]
                if (!$ids) {
                    Write-Log 'Open the Microsoft Store and search for the app by name to install it again.'
                    Start-Process 'ms-windows-store://home' -ErrorAction SilentlyContinue
                }
                foreach ($id in $ids) {
                    if (!(Invoke-Winget -Id $id -Source 'msstore')) {
                        Write-Log "Opening the Store page for $id instead"
                        Start-Process "ms-windows-store://pdp/?productid=$id" -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
    Wait-ForUser -Silent:$Silent
    exit 0
}
catch {
    Write-Log "Appx $Action failed: $($_.Exception.Message)" 'ERROR'
    Wait-ForUser -Silent:$Silent
    exit 1
}
