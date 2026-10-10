# Claude-Playbook
My first request ever with the Claude API was to scourge the AtlasOS and cie advance documentation I found out about linked on their Discord. Then I've made it build the best Playbook possible an AI can do.

## Status

Version 0.2.0: the first playbook that changes Windows. It has **not been run
in a VM yet**. Never apply it outside a virtual machine until it has.

Windows 11 24H2 (26100) and 25H2 (26200). Built for gaming (tested target:
Diablo 4 on Battle.net) and local AI work (Python, CUDA, WSL).

## What it does

Every item below is an option in AME Wizard unless marked *always*.

| Area | Default | What changes |
|------|---------|--------------|
| Bloat apps | on | Removes Bing apps, Clipchamp, Solitaire, Teams, new Outlook, Widgets, Cortana, Dev Home, Paint 3D, Quick Assist and similar, and stops feature updates from bringing them back. Store, Photos, Media Player, Calculator, Notepad, Paint, Terminal and App Installer stay. |
| Edge | on | Uninstalls the Edge browser after a replacement (Brave by default, Firefox, Chrome or your own) is installed. WebView2 stays. |
| Xbox | on | Removes the Xbox apps, Game Bar and Xbox Live services. Controllers keep working. Game Pass needs these, so leave it off if you use Game Pass. |
| Copilot | on | Removes the Copilot app; turns off Recall and Click to Do by policy. |
| OneDrive | on | Uninstalls OneDrive, but only if no profile is signed in or has files in its OneDrive folder. |
| Phone Link | on | Removes Phone Link and Cross Device. |
| Privacy | *always* | About 75 values: telemetry at the lowest level, ads, suggestions, web search in Start, activity history, error reporting. Telemetry services and tasks off. |
| Windows Update | *always on* | Updates stay on, peer-to-peer sharing off. Options: ask before installing, keep Windows Update away from GPU drivers. |
| Defender | kept | Turning it off is an option, off by default. |
| Gaming | on | Ultimate Performance-based power plan without USB/PCIe power saving, foreground priority (Win32PrioritySeparation 0x26), no mouse acceleration, no Sticky Keys popup, hibernation and Fast Startup off. Memory Integrity off is opt-in. |
| AI and dev | on | Long paths, no "python" Store shortcut, dotnet/PowerShell telemetry opt-out. WSL 2 is opt-in. |
| Interface | on | Classic right-click menu, file extensions and hidden files shown, slimmer taskbar. Left taskbar and dark mode are opt-in. |

### Left out on purpose

Timer resolution, HPET and dynamic tick changes, Nagle and NIC tweaks, MSI
mode, CPU mitigation switches, svchost splitting, SysMain and background app
changes, and device power hacks. None of them has a measured benefit on
current Windows 11 and hardware, and several hurt frame pacing, security or
battery life. NVIDIA drivers and CUDA are never touched.

## Undoing changes

The playbook copies a toolbox to `C:\Windows\ClaudePlaybook` (shortcut on the
desktop and in Start) and backs up every value it is about to change before
it changes anything. From there you can undo everything, undo one option, or
reinstall Edge, OneDrive, Xbox, Copilot and Phone Link. Running the playbook
again with an option turned off also undoes that option. See
`playbook/Executables/ClaudePlaybook/README.txt`.

## Build

```sh
pip install pyyaml py7zr
python3 tools/manifest.py     # regenerate undo data after editing Tasks/*.yml
python3 tools/validate.py     # static checks
python3 tools/package.py      # writes dist/Claude-Playbook-<Version>.apbx
```

On Windows with 7-Zip installed: `powershell -File tools\package.ps1`.

Load the `.apbx` into AME Wizard inside a VM snapshot. See `CLAUDE.md` for the
rules and phase plan, and `docs/` for the AME format reference.

## Credits

The approach follows the public [AtlasOS](https://github.com/Atlas-OS/Atlas)
and [ReviOS](https://github.com/meetrevision/playbook) playbooks. Code here is
written from scratch; files that follow a specific technique from them say so
at the top.
