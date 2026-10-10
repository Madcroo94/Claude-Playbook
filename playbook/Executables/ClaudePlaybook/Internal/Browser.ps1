<#
.SYNOPSIS
    Installs a browser to replace Edge.

.DESCRIPTION
    Tries winget first, then the vendor's own installer, which is only run
    when it carries a valid signature from that vendor. Uninstall the browser
    from Settings > Apps like any other program.
#>
param(
    [Parameter(Mandatory)][ValidateSet('brave', 'firefox', 'chrome')][string]$Name,
    [switch]$Silent
)

. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$Silent) { Assert-Admin -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters }
Start-Log -Name 'Browser'

$browsers = @{
    'brave'   = @{
        Title = 'Brave'; WingetId = 'Brave.Brave'; Publisher = 'Brave Software'
        Uri = 'https://laptop-updates.brave.com/latest/winx64'; File = 'BraveBrowserSetup.exe'
        Args = @('/silent', '/install'); Wait = 'BraveBrowserSetup', 'BraveUpdate'
        Exe = @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe")
    }
    'firefox' = @{
        Title = 'Firefox'; WingetId = 'Mozilla.Firefox'; Publisher = 'Mozilla Corporation'
        Uri = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US'; File = 'FirefoxSetup.exe'
        Args = @('/S'); Wait = @()
        Exe = @("$env:ProgramFiles\Mozilla Firefox\firefox.exe")
    }
    'chrome'  = @{
        Title = 'Google Chrome'; WingetId = 'Google.Chrome'; Publisher = 'Google LLC'
        Uri = 'https://dl.google.com/chrome/install/latest/chrome_installer.exe'; File = 'chrome_installer.exe'
        Args = @('/silent', '/install'); Wait = @()
        Exe = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")
    }
}
$b = $browsers[$Name]
if ($Name -eq 'firefox' -and $env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $b.Uri = $b.Uri -replace 'os=win64', 'os=win64-aarch64' }

function Test-BrowserInstalled {
    foreach ($e in $b.Exe) { if (Test-Path -LiteralPath $e) { return $true } }
    return $false
}

try {
    if (Test-BrowserInstalled) {
        Write-Log "$($b.Title) is already installed"
    }
    else {
        if (!(Invoke-Winget -Id $b.WingetId) -or !(Test-BrowserInstalled)) {
            $setup = Get-SignedDownload -Uri $b.Uri -FileName $b.File -Publisher $b.Publisher
            if (!$setup) { throw "Could not download $($b.Title)" }
            Write-Log "Running the $($b.Title) installer"
            Invoke-Program -FilePath $setup -ArgumentList $b.Args -Hidden | Out-Null
            # Some installers hand off to an updater and return early.
            $deadline = (Get-Date).AddMinutes(5)
            while (!(Test-BrowserInstalled) -and (Get-Date) -lt $deadline) {
                $busy = @($b.Wait).Count -gt 0 -and (Get-Process -Name $b.Wait -ErrorAction SilentlyContinue)
                Start-Sleep -Seconds 3
                if (!$busy) { break }
            }
            Remove-Item -LiteralPath (Split-Path -Parent $setup) -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (!(Test-BrowserInstalled)) { throw "$($b.Title) did not install" }
        Write-Log "$($b.Title) is installed"
    }
    Wait-ForUser -Silent:$Silent
    exit 0
}
catch {
    # Not fatal for the playbook: Edge removal checks for a browser itself.
    Write-Log "Installing $($b.Title) failed: $($_.Exception.Message)" 'ERROR'
    Wait-ForUser -Silent:$Silent
    exit 1
}
