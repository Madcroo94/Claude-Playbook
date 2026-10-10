# Shared helpers for the Claude Playbook toolbox. Dot-source this file.
# Written for Windows PowerShell 5.1: no ternaries, no ?? and no -AsHashtable.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script:Root = Split-Path -Parent $PSScriptRoot          # %windir%\ClaudePlaybook
$script:InternalDir = $PSScriptRoot
$script:BackupDir = Join-Path $script:Root 'Backup'
$script:LogDir = Join-Path $script:Root 'Logs'
$script:StatePath = Join-Path $script:BackupDir 'state.json'
$script:ManifestPath = Join-Path $script:InternalDir 'manifest.json'
$script:LogFile = $null

function Start-Log {
    param([Parameter(Mandatory)][string]$Name)
    New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null
    $script:LogFile = Join-Path $script:LogDir "$Name.log"
    Write-Log "---- $Name started as $([Security.Principal.WindowsIdentity]::GetCurrent().Name) ----"
}

function Write-Log {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Message, [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO')
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 's'), $Level, $Message
    Write-Host $line
    if ($script:LogFile) {
        try { Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 } catch { }
    }
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Relaunches the calling script elevated, passing the same parameters, then exits.
function Assert-Admin {
    param([Parameter(Mandatory)][string]$ScriptPath, [Parameter(Mandatory)][hashtable]$BoundParameters)
    if (Test-Admin) { return }
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$ScriptPath`"")
    foreach ($key in $BoundParameters.Keys) {
        $value = $BoundParameters[$key]
        if ($value -is [switch] -or $value -is [bool]) {
            if ($value) { $argList += "-$key" }
        }
        elseif ($value -is [array]) {
            $argList += "-$key"
            $argList += (($value | ForEach-Object { "'$_'" }) -join ',')
        }
        else {
            $argList += "-$key"
            $argList += "`"$value`""
        }
    }
    Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs | Out-Null
    exit 0
}

function Wait-ForUser {
    param([switch]$Silent)
    if (!$Silent) {
        Write-Host ''
        Read-Host 'Done. Press Enter to close this window' | Out-Null
    }
}

# ---------------------------------------------------------------- state file

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (!(Test-Path -LiteralPath $Path)) { return $null }
    $text = [IO.File]::ReadAllText($Path)
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return ($text | ConvertFrom-Json)
}

function Write-JsonFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Object)
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    $json = $Object | ConvertTo-Json -Depth 8
    $tmp = "$Path.tmp"
    [IO.File]::WriteAllText($tmp, $json, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Get-State {
    $state = Read-JsonFile -Path $script:StatePath
    if ($null -eq $state) {
        $state = [pscustomobject]@{ version = 1; created = (Get-Date -Format 's'); registry = @(); services = @(); tasks = @(); extra = [pscustomobject]@{} }
    }
    foreach ($name in 'registry', 'services', 'tasks') {
        if ($null -eq $state.$name) { $state | Add-Member -NotePropertyName $name -NotePropertyValue @() -Force }
        $state.$name = @($state.$name)
    }
    if ($null -eq $state.extra) { $state | Add-Member -NotePropertyName extra -NotePropertyValue ([pscustomobject]@{}) -Force }
    return $state
}

function Save-State {
    param([Parameter(Mandatory)]$State)
    Write-JsonFile -Path $script:StatePath -Object $State
}

# Extra values scripts keep for their own undo (previous power plan, apps
# deprovisioned, features enabled). The first value written for a key wins
# unless -Overwrite is given, so a re-run never loses the original.
function Get-StateExtra {
    param([Parameter(Mandatory)][string]$Key)
    $state = Get-State
    $prop = $state.extra.PSObject.Properties[$Key]
    if ($prop) { return $prop.Value }
    return $null
}

function Set-StateExtra {
    param([Parameter(Mandatory)][string]$Key, [AllowNull()]$Value, [switch]$Overwrite)
    $state = Get-State
    $prop = $state.extra.PSObject.Properties[$Key]
    if ($prop -and !$Overwrite) { return }
    $state.extra | Add-Member -NotePropertyName $Key -NotePropertyValue $Value -Force
    Save-State -State $state
}

function Get-Manifest {
    $m = Read-JsonFile -Path $script:ManifestPath
    if ($null -eq $m) { throw "Manifest not found at $script:ManifestPath" }
    foreach ($name in 'registry', 'services', 'tasks') { $m.$name = @($m.$name) }
    return $m
}

# ---------------------------------------------------------------- registry

function Get-BaseKey {
    param([Parameter(Mandatory)][ValidateSet('HKLM', 'HKU')][string]$Hive)
    if ($Hive -eq 'HKLM') { return [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64') }
    return [Microsoft.Win32.RegistryKey]::OpenBaseKey('Users', 'Registry64')
}

# Splits 'HKLM\SOFTWARE\X' into hive and sub-path. HKCR maps to
# HKLM\SOFTWARE\Classes; HKCU is resolved per user by the caller.
function Split-RegistryPath {
    param([Parameter(Mandatory)][string]$Path)
    $p = $Path.Trim().TrimEnd('\')
    $map = [ordered]@{
        'HKEY_LOCAL_MACHINE\' = 'HKLM'; 'HKLM\' = 'HKLM'
        'HKEY_CURRENT_USER\' = 'HKCU'; 'HKCU\' = 'HKCU'
        'HKEY_USERS\' = 'HKU'; 'HKU\' = 'HKU'
        'HKEY_CLASSES_ROOT\' = 'HKCR'; 'HKCR\' = 'HKCR'
    }
    foreach ($prefix in $map.Keys) {
        if ($p.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            $hive = $map[$prefix]
            $sub = $p.Substring($prefix.Length)
            if ($hive -eq 'HKCR') { return @('HKLM', "SOFTWARE\Classes\$sub") }
            return @($hive, $sub)
        }
    }
    throw "Unsupported registry path: $Path"
}

function Test-RegistryKey {
    param([Parameter(Mandatory)][string]$Hive, [Parameter(Mandatory)][string]$SubKey)
    $base = Get-BaseKey -Hive $Hive
    try {
        $k = $base.OpenSubKey($SubKey)
        if ($k) { $k.Close(); return $true }
        return $false
    }
    finally { $base.Close() }
}

# Returns the shallowest ancestor of SubKey (or SubKey itself) that does not
# exist yet, or $null when SubKey exists. Deleting it later removes only keys
# that were created after this check.
function Get-MissingRoot {
    param([Parameter(Mandatory)][string]$Hive, [Parameter(Mandatory)][string]$SubKey)
    $parts = $SubKey.Split('\')
    for ($i = 1; $i -le $parts.Length; $i++) {
        $candidate = ($parts[0..($i - 1)] -join '\')
        if (!(Test-RegistryKey -Hive $Hive -SubKey $candidate)) { return $candidate }
    }
    return $null
}

function ConvertTo-StoredData {
    param($Value, [Microsoft.Win32.RegistryValueKind]$Kind)
    switch ($Kind) {
        'Binary' { return [Convert]::ToBase64String([byte[]]$Value) }
        'None' { if ($Value -is [byte[]]) { return [Convert]::ToBase64String($Value) } return '' }
        'MultiString' { return @($Value) }
        default { return $Value }
    }
}

function ConvertFrom-StoredData {
    param($Data, [string]$Kind)
    switch ($Kind) {
        'Binary' { return [Convert]::FromBase64String([string]$Data) }
        'None' { return [Convert]::FromBase64String([string]$Data) }
        'MultiString' { return [string[]]@($Data) }
        'DWord' { return [int]$Data }
        'QWord' { return [long]$Data }
        default { return [string]$Data }
    }
}

# Reads one value without expanding %variables%.
function Get-RegistryValueState {
    param([Parameter(Mandatory)][string]$Hive, [Parameter(Mandatory)][string]$SubKey, [AllowEmptyString()][string]$Name)
    $base = Get-BaseKey -Hive $Hive
    try {
        $k = $base.OpenSubKey($SubKey)
        if (!$k) { return [pscustomobject]@{ keyExists = $false; existed = $false; kind = $null; data = $null } }
        try {
            if ($k.GetValueNames() -notcontains $Name) {
                return [pscustomobject]@{ keyExists = $true; existed = $false; kind = $null; data = $null }
            }
            $kind = $k.GetValueKind($Name)
            $raw = $k.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            return [pscustomobject]@{ keyExists = $true; existed = $true; kind = $kind.ToString(); data = (ConvertTo-StoredData -Value $raw -Kind $kind) }
        }
        finally { $k.Close() }
    }
    finally { $base.Close() }
}

function Set-RegistryValueState {
    param([Parameter(Mandatory)][string]$Hive, [Parameter(Mandatory)][string]$SubKey, [AllowEmptyString()][string]$Name, [Parameter(Mandatory)][string]$Kind, $Data)
    $base = Get-BaseKey -Hive $Hive
    try {
        $k = $base.CreateSubKey($SubKey)
        try { $k.SetValue($Name, (ConvertFrom-StoredData -Data $Data -Kind $Kind), [Microsoft.Win32.RegistryValueKind]$Kind) }
        finally { $k.Close() }
    }
    finally { $base.Close() }
}

function Remove-RegistryValueIfPresent {
    param([Parameter(Mandatory)][string]$Hive, [Parameter(Mandatory)][string]$SubKey, [AllowEmptyString()][string]$Name)
    $base = Get-BaseKey -Hive $Hive
    try {
        $k = $base.OpenSubKey($SubKey, $true)
        if (!$k) { return }
        try { if ($k.GetValueNames() -contains $Name) { $k.DeleteValue($Name) } }
        finally { $k.Close() }
    }
    finally { $base.Close() }
}

function Test-KeyTreeEmpty {
    param([Parameter(Mandatory)][Microsoft.Win32.RegistryKey]$Key)
    if ($Key.ValueCount -gt 0) { return $false }
    foreach ($name in $Key.GetSubKeyNames()) {
        $child = $Key.OpenSubKey($name)
        if ($child) {
            try { if (!(Test-KeyTreeEmpty -Key $child)) { return $false } }
            finally { $child.Close() }
        }
    }
    return $true
}

# Deletes a key we created, but only when nothing else has put values in it.
function Remove-CreatedKey {
    param([Parameter(Mandatory)][string]$Hive, [Parameter(Mandatory)][string]$SubKey)
    $base = Get-BaseKey -Hive $Hive
    try {
        $k = $base.OpenSubKey($SubKey)
        if (!$k) { return }
        $empty = $false
        try { $empty = Test-KeyTreeEmpty -Key $k } finally { $k.Close() }
        if ($empty) { $base.DeleteSubKeyTree($SubKey, $false) }
        else { Write-Log "Kept ${Hive}\${SubKey}: it now holds values that were not ours" 'WARN' }
    }
    finally { $base.Close() }
}

# ---------------------------------------------------------------- user hives

# Every real user profile plus the Default profile (template for new users).
function Get-UserProfiles {
    $list = @()
    $base = Get-BaseKey -Hive 'HKLM'
    try {
        $pl = $base.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
        try {
            foreach ($sid in $pl.GetSubKeyNames()) {
                if ($sid -notmatch '^S-1-5-21-[\d-]+$') { continue }
                $sk = $pl.OpenSubKey($sid)
                try { $path = $sk.GetValue('ProfileImagePath') } finally { $sk.Close() }
                if (!$path) { continue }
                $path = [Environment]::ExpandEnvironmentVariables($path)
                $hive = Join-Path $path 'NTUSER.DAT'
                if (Test-Path -LiteralPath $hive) {
                    $list += [pscustomobject]@{ Id = $sid; ProfilePath = $path; HivePath = $hive; IsDefault = $false }
                }
            }
            $default = [Environment]::ExpandEnvironmentVariables([string]$pl.GetValue('Default'))
            if ($default) {
                $hive = Join-Path $default 'NTUSER.DAT'
                if (Test-Path -LiteralPath $hive) {
                    $list += [pscustomobject]@{ Id = 'Default'; ProfilePath = $default; HivePath = $hive; IsDefault = $true }
                }
            }
        }
        finally { $pl.Close() }
    }
    finally { $base.Close() }
    return $list
}

# Finds where a profile's NTUSER.DAT is loaded under HKU (by SID, or under
# another name such as AME's own mount), or loads it. Returns the HKU subkey
# name and whether we loaded it, or $null if it cannot be reached.
function Mount-UserHive {
    param([Parameter(Mandatory)]$UserProfile)
    if (!$UserProfile.IsDefault -and (Test-RegistryKey -Hive 'HKU' -SubKey $UserProfile.Id)) {
        return [pscustomobject]@{ Root = $UserProfile.Id; Mounted = $false }
    }
    $suffix = $UserProfile.HivePath -replace '^[A-Za-z]:', ''
    $base = Get-BaseKey -Hive 'HKLM'
    try {
        $hl = $base.OpenSubKey('SYSTEM\CurrentControlSet\Control\hivelist')
        try {
            foreach ($n in $hl.GetValueNames()) {
                $v = [string]$hl.GetValue($n)
                if ($n -like '\REGISTRY\USER\*' -and $v -and $v.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) {
                    return [pscustomobject]@{ Root = $n.Substring(15); Mounted = $false }
                }
            }
        }
        finally { $hl.Close() }
    }
    finally { $base.Close() }

    $name = 'CPB_' + ($UserProfile.Id -replace '[^A-Za-z0-9]', '_')
    $code = Invoke-Native -FilePath 'reg.exe' -ArgumentList @('load', "HKU\$name", $UserProfile.HivePath)
    if ($code -ne 0) {
        Write-Log "Could not load the registry of $($UserProfile.ProfilePath)" 'WARN'
        return $null
    }
    return [pscustomobject]@{ Root = $name; Mounted = $true }
}

function Dismount-UserHive {
    param($Mount)
    if ($Mount -and $Mount.Mounted) {
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        $code = Invoke-Native -FilePath 'reg.exe' -ArgumentList @('unload', "HKU\$($Mount.Root)")
        if ($code -ne 0) { Write-Log "Could not unload HKU\$($Mount.Root)" 'WARN' }
    }
}

# Which profiles an HKCU action reaches, following AME's scope names.
function Select-ProfilesForScope {
    param([Parameter(Mandatory)]$Profiles, [string]$Scope)
    switch ($Scope) {
        'defaultUsers' { return @($Profiles | Where-Object { $_.IsDefault }) }
        'currentUser' { return @($Profiles | Where-Object { !$_.IsDefault -and (Test-RegistryKey -Hive 'HKU' -SubKey "$($_.Id)\Volatile Environment") }) }
        'activeUsers' { return @($Profiles | Where-Object { !$_.IsDefault -and (Test-RegistryKey -Hive 'HKU' -SubKey $_.Id) }) }
        default { return @($Profiles) }
    }
}

# ---------------------------------------------------------------- services and tasks

function Get-ServiceStart {
    param([Parameter(Mandatory)][string]$Name)
    $s = Get-RegistryValueState -Hive 'HKLM' -SubKey "SYSTEM\CurrentControlSet\Services\$Name" -Name 'Start'
    if (!$s.keyExists -or !$s.existed) { return $null }
    return [int]$s.data
}

function Split-TaskPath {
    param([Parameter(Mandatory)][string]$Path)
    $i = $Path.LastIndexOf('\')
    return @($Path.Substring(0, $i + 1), $Path.Substring($i + 1))
}

# Returns 'Enabled', 'Disabled' or $null when the task does not exist.
function Get-TaskEnabledState {
    param([Parameter(Mandatory)][string]$Path)
    $parts = Split-TaskPath -Path $Path
    $t = Get-ScheduledTask -TaskPath $parts[0] -TaskName $parts[1] -ErrorAction SilentlyContinue
    if (!$t) { return $null }
    if ($t.State -eq 'Disabled') { return 'Disabled' }
    return 'Enabled'
}

function Set-TaskEnabledState {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][ValidateSet('Enabled', 'Disabled')][string]$State)
    $parts = Split-TaskPath -Path $Path
    if ($State -eq 'Enabled') { Enable-ScheduledTask -TaskPath $parts[0] -TaskName $parts[1] -ErrorAction Stop | Out-Null }
    else { Disable-ScheduledTask -TaskPath $parts[0] -TaskName $parts[1] -ErrorAction Stop | Out-Null }
}

# ---------------------------------------------------------------- misc

# Runs a console program, sending its output to the log, and returns its exit
# code. Windows PowerShell 5.1 turns redirected stderr into a terminating
# error when ErrorActionPreference is Stop, so that is relaxed here.
function Invoke-Native {
    param([Parameter(Mandatory)][string]$FilePath, [string[]]$ArgumentList = @())
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & $FilePath @ArgumentList 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    if ($out -and $script:LogFile) { foreach ($line in $out) { if ($line.Trim()) { Write-Log "  $line" } } }
    return $code
}

# Runs a program and returns its exit code without throwing.
function Invoke-Program {
    param([Parameter(Mandatory)][string]$FilePath, [string[]]$ArgumentList = @(), [switch]$Hidden)
    $p = @{ FilePath = $FilePath; Wait = $true; PassThru = $true }
    if ($ArgumentList.Count -gt 0) { $p.ArgumentList = $ArgumentList }
    if ($Hidden) { $p.WindowStyle = 'Hidden' } else { $p.NoNewWindow = $true }
    $proc = Start-Process @p
    return $proc.ExitCode
}

# Returns winget.exe for the current user, registering App Installer once if
# the alias is missing (common right after first sign-in).
function Get-Winget {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' -ErrorAction Stop
    }
    catch { Write-Log "Could not register App Installer: $($_.Exception.Message)" 'WARN' }
    $alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path -LiteralPath $alias) { return $alias }
    return $null
}

function Invoke-Winget {
    param([Parameter(Mandatory)][string]$Id, [string]$Source = 'winget')
    $winget = Get-Winget
    if (!$winget) { Write-Log 'winget is not available' 'WARN'; return $false }
    $wingetArgs = @('install', '--id', $Id, '--exact', '--source', $Source, '--silent',
        '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    Write-Log "winget install $Id ($Source)"
    $code = Invoke-Program -FilePath $winget -ArgumentList $wingetArgs
    # 0 = installed, 0x8A15002B = already installed and up to date
    if ($code -eq 0 -or $code -eq -1978335189) { return $true }
    Write-Log "winget exited with $code for $Id" 'WARN'
    return $false
}

# Downloads a vendor installer and refuses it unless it carries a valid
# Authenticode signature from the expected publisher.
function Get-SignedDownload {
    param([Parameter(Mandatory)][string]$Uri, [Parameter(Mandatory)][string]$FileName, [Parameter(Mandatory)][string]$Publisher)
    $dir = Join-Path ([IO.Path]::GetTempPath()) ('cpb-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $out = Join-Path $dir $FileName
    Write-Log "Downloading $Uri"
    & curl.exe -fLsS --retry 3 -o $out $Uri
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $out)) { Write-Log "Download failed: $Uri" 'WARN'; return $null }
    $sig = Get-AuthenticodeSignature -LiteralPath $out
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike "*$Publisher*") {
        Write-Log "Rejected ${FileName}: signature $($sig.Status), signer '$($sig.SignerCertificate.Subject)'" 'ERROR'
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        return $null
    }
    return $out
}

# Browsers other than Edge that are registered with Windows or installed in
# their usual places.
function Get-OtherBrowsers {
    $found = @()
    foreach ($root in 'HKLM:\SOFTWARE\Clients\StartMenuInternet', 'HKLM:\SOFTWARE\WOW6432Node\Clients\StartMenuInternet', 'HKCU:\SOFTWARE\Clients\StartMenuInternet') {
        if (Test-Path $root) {
            Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.PSChildName -notmatch 'Edge|IEXPLORE') { $found += $_.PSChildName }
            }
        }
    }
    $candidates = @(
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
        "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
        "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles\LibreWolf\librewolf.exe",
        "$env:LOCALAPPDATA\Vivaldi\Application\vivaldi.exe",
        "$env:LOCALAPPDATA\Programs\Opera\opera.exe",
        "$env:LOCALAPPDATA\Programs\Opera GX\opera.exe"
    )
    foreach ($c in $candidates) { if ($c -and (Test-Path -LiteralPath $c)) { $found += $c } }
    return @($found | Select-Object -Unique)
}
