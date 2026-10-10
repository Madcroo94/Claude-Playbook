<#
.SYNOPSIS
    Adds "Claude Playbook" shortcuts to the toolbox folder on the Start menu
    and on the signed-in user's desktop.
#>
param([switch]$Silent)

. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Log -Name 'Shortcut'

try {
    $shell = New-Object -ComObject WScript.Shell
    $targets = @(
        (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Claude Playbook.lnk'),
        (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Claude Playbook.lnk')
    )
    foreach ($t in $targets) {
        $lnk = $shell.CreateShortcut($t)
        $lnk.TargetPath = $script:Root
        $lnk.Description = 'Undo changes, reinstall apps and read logs'
        $lnk.IconLocation = (Join-Path $env:SystemRoot 'System32\imageres.dll') + ',109'
        $lnk.Save()
        Write-Log "Created $t"
    }
    exit 0
}
catch {
    Write-Log "Could not create the shortcuts: $($_.Exception.Message)" 'WARN'
    exit 0
}
