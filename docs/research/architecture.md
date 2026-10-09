# Reference playbook architecture: AtlasOS, ReviOS, Privacy+, AME 10

Researched 2026-10-09 by reading extracted sources only. No script or binary
from these playbooks was executed. All paths are relative to the scratchpad
`refs/` folder:

| Short name | Path under `refs/` | What it is | Snapshot |
|---|---|---|---|
| Atlas | `atlas/src/playbook`, `atlas/src`, `atlas/.github` | AtlasOS git checkout | commit `1ed9630`, 2026-05-04, Version 0.5.0 |
| Revi (src) | `revi/src`, `revi/.github` | ReviOS git checkout | commit `f907fde`, 2026-10-07, Version placeholder `1.0` |
| Revi (apbx) | `revi-apbx/` | Released ReviOS `.apbx`, extracted | Version `26.04` (older than src) |
| P+ | `privacyplus/` | AME Privacy+ `.apbx`, extracted | Version 0.8.2 |
| AME10 | `ame10/` | AME 10 `.apbx`, extracted | Version 0.8 |

We do not copy UniqueIds or ProductCodes anywhere in this repo. Where this
file mentions them, it records only whether the field is present.

Quick map of the sections:

1. playbook.conf side by side, with every feature page
2. main.yml orchestration order
3. Revert, uninstall and upgrade
4. Post-install toolbox (AtlasDesktop, Revision Tool, Privacy+ Settings)
5. Software installs and browser choice
6. Build gating, UCPD, ISO/OOBE
7. Repo, CI and release engineering
8. Licensing
9. Fields and parameters seen in refs but not in `docs/`
10. Recommendations for Claude Playbook

---

## 1. playbook.conf side by side

Sources: `atlas/src/playbook/playbook.conf`, `revi/src/playbook.conf`
(`revi-apbx/playbook.conf` differs only in Version `26.04`, two fewer builds and
a typo), `privacyplus/playbook.conf`, `ame10/playbook.conf`.

### 1.1 Identity, targeting, distribution

| Field | Atlas | Revi | Privacy+ | AME 10 |
|---|---|---|---|---|
| XML declaration | **missing** | yes | yes | yes |
| `Name` | AtlasOS | ReviOS | Privacy+ | AME 10 |
| `Username` | Atlas | Revision | Ameliorated | Ameliorated |
| `Title` | Atlas v0.5.0 | ReviOS Playbook | Windows 11 Privacy+ Playbook | Windows 10 Amelioration Playbook |
| `Version` | 0.5.0 (SemVer) | 1.0 in src; CI rewrites to `YY.MM` (apbx: 26.04) | 0.8.2 | 0.8 |
| `UpgradableFrom` | `0.4.1` | `any` | `0.6-0.7` | `0.6-0.7` |
| `AllowUnsupportedUpgrades` | false | — | — | — |
| `SupportedBuilds` | 26100, 26200 | 19044, 19045, 22631, 26100, 26200 (+ 28000, 26300 in src) | 22000, 22621, 22631, 22635, 26100, 26200 | 19044, 19045 |
| `UniqueId` | present | present | present | present |
| `ProductCode` (verification) | present | present | present | present (same as P+) |
| `Git` | github Atlas-OS/Atlas | github meetrevision/playbook | github Ameliorated-LLC/AME-11 | github Ameliorated-LLC/AME-10 |
| `Website` / `DonateLink` | yes / yes | yes / yes | yes / — | yes / — |
| `InstallGuide` | docs.atlasos.net | — | — | — |
| `ProgressText` | yes | — | yes | yes |
| `EstimatedMinutes` | 15 | — | — | — |
| `Overhaul` | true | — | true | true |
| `UseKernelDriver` | false | false | — | — |
| `SupportsISO` | true | true | true | — |
| `ISO` | DisableBitLocker, DisableHardwareRequirements | same | same | — |
| `OOBE` | 3 bullets, `<Internet>Force</Internet>` | 3 bullets, `<Internet>Request</Internet>` | 3 bullets, Internet commented out | — |
| `Software` packages | none | brave, firefox (both `DefaultWebBrowser="true"`) | 15 packages (browsers, mail, media, office, tools) | — |
| `playbook.png` | root | root | `Images/playbook.png` | `Images/playbook.png` |

### 1.2 Requirements

| Requirement | Atlas | Revi | Privacy+ | AME 10 | In our `docs/`? |
|---|---|---|---|---|---|
| `Internet` | ✓ | ✓ | ✓ | ✓ | yes |
| `NoPendingUpdates` | ✓ | ✓ | ✓ | ✓ | yes |
| `NoAntivirus` | ✓ | ✓ | ✓ | ✓ | yes |
| `PluggedIn` | ✓ | ✓ | ✓ | ✓ | yes |
| `DefenderToggled` | ✓ | ✓ | — | — | yes |
| `DefenderDisabled` | — | — | ✓ | ✓ | yes (also strips Defender at ISO injection) |
| `UCPDDisabled` | ✓ | — (disables UCPD in YAML instead) | ✓ | — | yes |
| `Activation` | — | — | ✓ | ✓ | yes |
| `AdministratorPasswordSet` | — | — | ✓ | ✓ | yes |
| `NoTweakware` | — | — | ✓ | ✓ | **no** |
| `LocalAccounts` | — | — | ✓ | ✓ | **no** |

Takeaway: the community playbooks (Atlas, Revi) ask for the light set
(`DefenderToggled`, not `DefenderDisabled`) so Defender can stay. The Ameliorated
playbooks demand `DefenderDisabled` because they delete Defender outright.

### 1.3 Feature pages: what users get to choose

Per `docs/reconnaissance.md` §8, a `CheckboxOption` without `IsChecked` defaults
to **checked**. Atlas never sets `IsChecked`, so by the docs every Atlas
checkbox starts ticked. Confirm this in a VM before relying on it.

#### Atlas (`atlas/src/playbook/playbook.conf`)

| # | Page | Options (`Name`) | Default | Notes |
|---|---|---|---|---|
| 1 | RadioPage, required | `defender-enable` "Enable Defender (recommended)", `defender-disable` | `defender-enable` | Togglable later in Atlas folder |
| 2 | RadioPage, required | `mitigations-default` (recommended), `mitigations-disable` | `mitigations-default` | Spectre/Meltdown etc. |
| 3 | RadioPage, required | `auto-updates-disable`, `auto-updates-default` | **`auto-updates-disable`** | Update *notifications* stay |
| 4 | CheckboxPage, required | `disable-hibernation`, `disable-power-saving`, `disable-core-isolation` | all checked (implicit) | "can be changed in the Atlas folder later" |
| 5 | CheckboxPage, required | `remove-snipping-tool`, `uninstall-edge`, `install-another-browser` | all checked (implicit) | |
| 6 | CheckboxPage, required | `install-toolbox` "Install Atlas Toolbox (BETA)" | checked (implicit) | |
| 7 | RadioImagePage, `DependsOn="install-another-browser"`, `CheckDefaultBrowser="true"` | `browser-brave`, `browser-librewolf`, `browser-firefox`, `browser-chrome` | `browser-brave` | "Browser settings are not modified" |

#### Revi (`revi/src/playbook.conf`)

| # | Page | Options (`Name`) | Default | Notes |
|---|---|---|---|---|
| 1 | RadioImagePage, required, `DependsOn="software"`, `CheckDefaultBrowser="true"` | `None`, `browser-brave`, `browser-firefox` | `browser-brave` | `software` is not defined on any Revi page; behaviour of a dangling `DependsOn` is unknown |
| 2 | RadioPage | `disable-defender` "(Default)", `enable-defender` | **`disable-defender`** | |
| 3 | RadioPage | `disable-hibernate` (Default, includes Fast Startup), `enable-hibernate` | `disable-hibernate` | Warns about laptop overheating in sleep |
| 4 | CheckboxPage, required | `remove-edge` ✓, `remove-onedrive` ✓, `remove-winsxs-ai` (Recall & Copilot) ✓, `remove-teams` ✓ | as marked | |
| 5 | CheckboxPage, required | `remove-appx-photos` ✓, `remove-appx-devhome` ✓, `remove-appx-xbox` ✗, `remove-appx-yourphone` ✓ | as marked | |
| 6 | CheckboxPage, required | `configure-wallpaper` ✓, `configure-darkmode` ✓, `configure-lcm` (legacy context menu) ✓, `configure-te` (disable transparency) ✓ | as marked | |
| 7 | CheckboxPage, required | `remove-pinned-items-startmenu` ✓, `disable-automatic-maintenance` ✗ | as marked | |

Revi YAML also gates on `configure-explorer-taskbar-animations`, which no page
defines (orphan). Our `validate.py` would reject that, which is correct.

#### Privacy+ (`privacyplus/playbook.conf`); AME 10 is identical

| # | Page | Options (`Name`) | Default | Notes |
|---|---|---|---|---|
| 1 | CheckboxPage | `software` (install OSS replacements), `ui` (modify Windows UI), `ame-tools` | all checked (implicit) | "We strongly recommend keeping all options!" |
| 2 | RadioPage | `security-enhanced` (recommended), `security-default` | `security-enhanced` | UAC/credential model, see `privacyplus/Configuration/tasks/config.yml` |
| 3 | RadioImagePage, `DependsOn="software"`, `CheckDefaultBrowser="true"` | `browser-firefox`, `browser-ugc`, `browser-librewolf`, `browser-brave` | `browser-firefox` | No None option |
| 4 | RadioImagePage, `DependsOn="software"` | None, `media-vlc`, `media-mpv` | `media-vlc` | |
| 5 | RadioImagePage, `DependsOn="software"` | None, `email-thunderbird`, `email-spark`, `email-mailspring` | `email-thunderbird` | |
| 6 | RadioImagePage, `DependsOn="software"` | None, `office-onlyoffice`, `office-freeoffice`, `office-libreoffice` | `office-onlyoffice` | |

Note that Privacy+ has **no** Defender/Update/Edge options: those removals are
unconditional.

---

## 2. main.yml orchestration order

### 2.1 Entry points

| | File | Notes |
|---|---|---|
| Atlas | `Configuration/custom.yml` (**no** `main.yml`) | `custom.yml` is deprecated per changelog 2024-06-12 (recon §6) but still accepted. Uses `!writeStatus` and backslash task paths. |
| Revi | `Configuration/main.yml` (title "Custom", `privilege: Admin`) | Backslash task paths, `!writeStatus` mostly. |
| Privacy+ / AME 10 | `Configuration/main.yml` (title "Custom", `privilege: Admin`) | Seven `!task` lines, nothing else. |

All three use backslash paths and `!writeStatus`, and all three ship working
releases. So AME Wizard accepts both forms. That does not change our rule:
`!status` and forward slashes are what the current docs show.

### 2.2 Order of phases

| Phase | Atlas (`custom.yml`) | Revi (`main.yml`) | Privacy+ (`main.yml`) |
|---|---|---|---|
| 0 Load default-user hive | `reg load HKU\AME_UserHive_Default …NTUSER.DAT` (`oobe: false`) | — | — |
| 1 Clean old install (upgrade) | Kill folder processes, delete `%windir%\AtlasDesktop`/`AtlasModules` (`onUpgrade: true`) | — | — |
| 2 Copy payload | Copy `AtlasModules`, `AtlasDesktop`, Themes to `%windir%`; `halt` on failure | `start.yml`: Licenses folder, `hosts` file, VC++ redist, **install Revision Tool**, ngen, power plan | — |
| 3 Silence the shell | `DISABLENOTIFS.cmd`, kill/restart explorer | toast registry value in `start.yml` | — |
| 4 Prep PowerShell | `script-ngen.yml`, `config-powershell.yml` | ngen in `start.yml` | — |
| 5 Cleanup | `CLEANUP.ps1` (Disk Cleanup) | — | — |
| 6 Start / software | `atlas/start.yml`: PATH, DirectPlay, DISM cleanup, `SOFTWARE.ps1` (7-Zip, VC++, DirectX), Toolbox, browser | `os-info` tasks, then `start.yml` | — |
| 7 Services | `atlas/services.yml` (backs up services first) | after packages | `services.yml` (3rd) |
| 8 Components | `atlas/components.yml` (Edge, OneDrive, Defender/telemetry CABs) | `packages/app-win32.yml` (Edge, OneDrive, Teams), `packages/win-sxs.yml` (CABs via Revision Tool) | `components.yml` (4th) |
| 9 AppX | `atlas/appx.yml` | `packages/appx.yml` | `appx.yml` (2nd) |
| 10 Kill shell processes | — | `!taskKill` explorer, SearchHost, etc. | inside tasks |
| 11 Software | (done in phase 6) | `software.yml` (browser) | `software.yml` (last) |
| 12 Defaults | `atlas/default.yml` (apply "(default)" toggles) | — | — |
| 13 Revert old versions | `atlas/revert.yml` (`onUpgrade: true`) | `revert.yml` (`onUpgrade: true`) | — |
| 14 Tweaks / registry | `tweaks.yml`: ~170 one-tweak files in networking → performance → privacy → QoL → security → debloat → scripts → misc → power (last) | `registry.yml`: ~45 files in os-info → explorer → privacy → security → system → updates → misc | `regedits.yml` (1st), `files.yml`, `config.yml` |
| 15 Finalize | `APPLYDUHIVE.ps1`, `SETPATHS.ps1`, unload hive, set ExecutionPolicy RemoteSigned | `final.yml`: NTFS, memory compression, CLEANER.ps1, FINALIZE.cmd, wallpaper/theme, clear AppX caches, `gpupdate`, `revitool tweaks patches`, restart explorer | — |
| 16 Reboot | none in YAML; AME Wizard reboots at the end | none | none |

Why this order (from comments in the files):

- **Payload first** (Atlas) because many later YAML steps call scripts inside
  `%windir%\AtlasModules`/`AtlasDesktop`. Revi installs Revision Tool first for
  the same reason: `win-sxs.yml`, `final.yml` and `revert.yml` call
  `revitool.exe`.
- **PowerShell ngen early** so later PowerShell steps run faster.
- **Back up service start types before changing services**
  (`atlas/services.yml` → `BACKUP.ps1` → `AtlasModules\Other\winServices.reg`),
  and again after all tweaks (`tweaks/scripts/script-backup2.yml` →
  `atlasServices.reg`).
- **Win32/SxS removal before AppX** in Revi: "Uninstalling WinSxS packages
  before app-win32 could leave leftovers" (`revi/src/Configuration/main.yml`).
- **Explorer is killed after Defender changes** in Revi because "Defender
  requires explorer to be running to disable certain protections".
- **Hidden Settings pages set before tweaks** (Atlas) because scripts later
  overwrite the value.
- **Power script last** (Atlas `tweaks.yml`: "Done last on purpose").
- **Revert after install, before final tweaks**, so the current version's tweaks
  win over rolled-back values.
- **Registry first** in Privacy+: Defender and Update registry state is set
  before services and files are deleted.

### 2.3 Task file granularity

| | Files | Style |
|---|---|---|
| Atlas | 191 YAML files | One tweak per file, grouped by category folder, each with `title`/`description`; ordered by `tweaks.yml` |
| Revi | ~50 | One area per file (`registry/explorer/taskbar.yml`, …) |
| Privacy+ | 7 | One domain per file, very long (`files.yml` 676 lines) |

Action counts (top tags, from `grep`):

| Tag | Atlas | Revi | Privacy+ |
|---|---|---|---|
| `!registryValue` | 386 | 737 | 506 |
| `!registryKey` | 35 | 103 | 347 |
| `!file` (delete) | 1 | 2 | **322** |
| `!appx` | 41 | 5 (uses Revision Tool) | 82 |
| `!service` | 13 | 21 | 53 |
| `!powerShell` / `!cmd` / `!run` | 53 / 22 / 29 | 24 / 7 / 37 | 0 / 0 / 31 |
| `!software` / `!download` | 0 / 0 | 1 / 4 | 15 / 2 |
| `!systemPackage` | 0 | 0 (comment says "deprecated… main cause of #49") | 1 |

---

## 3. Revert, uninstall and upgrade

### 3.1 What "revert.yml" means in Atlas and Revi

Neither file undoes the playbook. Both **roll back tweaks that older versions
applied and newer versions dropped**, so an upgraded machine matches a fresh one.

| | `atlas/src/playbook/Configuration/atlas/revert.yml` | `revi/src/Configuration/Tasks/revert.yml` |
|---|---|---|
| Task-level keys | `privilege: TrustedInstaller`, `onUpgrade: true` | `privilege: TrustedInstaller`, `onUpgrade: true` |
| Content | Deletes `ThisPCPolicy` values under 7 FolderDescriptions GUIDs (×2 for Wow6432Node); links issue #1283 | ~60 actions: IE policy deletes, netsh congestion provider default, `SvcHostSplitThresholdInKB` restore, service start types restored (`bam`, `Beep`, `GraphicsPerfSvc`, `Ndu`, `DPS`), Windows Update policy key deleted, `VulnerableDriverBlocklistEnable=1`, mitigation policies deleted, `revitool … superfetch enable`, `… background-apps enable`, etc. Each tied to an issue number |
| Option-aware | no | yes, e.g. `option: '!disable-automatic-maintenance'` |

### 3.2 onUpgrade usage

| | Where `onUpgrade` appears | Pattern |
|---|---|---|
| Atlas | `atlas/services.yml`, `components.yml`, `appx.yml`, `tweaks/qol/taskbar/config-pins.yml`, `tweaks/scripts/script-pfp.yml`: task-level `onUpgrade: false` | One-time destructive or user-visible steps do **not** re-run on upgrade (app removal, service changes, taskbar pins, profile picture) |
| | `custom.yml` folder delete/copy, `atlas/default.yml` `DEFAULT.ps1`, `atlas-theme.yml`: `onUpgrade: true` | Refresh payload and re-apply defaults on upgrade |
| | `start.yml` StepsRecorder removal: action-level `onUpgrade: false` | |
| Revi | Only `revert.yml` (`onUpgrade: true`) | `UpgradableFrom: any`; everything else re-runs |
| Privacy+ | none | `UpgradableFrom 0.6-0.7` without upgrade-specific YAML |

Nobody uses `onUpgradeVersions` or `previousOption`.

`onUpgrade` and `privilege` at **task** level (top of a task file, next to
`title`) are not in our `docs/` task table (recon §6 lists only `option`,
`options` and `builds`). The refs rely on both. Treat them as unproven until a VM
run shows they work.

### 3.3 How each playbook makes changes reversible

| Mechanism | Atlas | Revi | Privacy+ |
|---|---|---|---|
| Paired toggle scripts (Disable/Enable) | **Yes**: 159 `.cmd` files in `AtlasDesktop`, 58 of them marked `(default)`; see §4 | Delegated to Revision Tool GUI/CLI | Privacy+ Settings exe (Enable/Disable entries) |
| State recorded | `HKLM\SOFTWARE\AtlasOS\Services\<Setting>` with `state` (DWORD) and `path` (script). `DEFAULT.reg` seeds it. | Inside Revision Tool | Unknown (closed binary) |
| Services | `.reg` snapshots of every service `Start` value before (`winServices.reg`) and after (`atlasServices.reg`); "Set services to defaults.cmd" re-imports either | `revert.yml` resets specific services | Services **deleted** (`wuauserv`, `UsoSvc`, `WaaSMedicSvc`…), no snapshot |
| Component removal | Self-signed CAB packages built with sxsc (`AtlasModules/Packages/Z-Atlas-NoDefender-*`, `Z-Atlas-NoTelemetry-*`) and installed with `packageInstall.ps1`; uninstalling the CAB brings the component back (`Toggle Defender.cmd`) | Revision Tool `winpackage --install <name>-removal` (same CAB idea, called "reversible deletion" in AME docs) | `!file` deletes (322) and `!service … delete`; not reversible in place |
| AppX | Removes and **deprovisions**; "most can be reinstalled from Microsoft Store" | Revision Tool `appx --all-users --remove` | `!appx` removal plus file deletes |
| Edge | `RemoveEdge.ps1` (ShadowWhisperer-derived) + "Install or Remove Edge.cmd" in toolbox | `EDGE.ps1` + Revision Tool | Files deleted, `!systemPackage` for IE |
| hosts file | — | **Overwritten** with a 54-entry blocklist (`Executables/hosts`), no backup | — |
| Full uninstall | None. Docs point to "Reset this PC" (`9. Troubleshooting/Reset this PC (read first).url`) | None in repo | Privacy+ Settings → "Uninstall AME using a Windows ISO / USB" (restores from install media; matches recon §12) |

**Privacy+ uninstall in detail.** `TOOLS.bat` copies `privacy+_settings.exe`
and `appfetch.exe` to `%ProgramData%\AME` and registers both under
`HKLM\…\Uninstall\` with `UninstallString "<exe> --uninstall"`. Strings in the
binary (read, not run) include "Uninstall AME using a Windows ISO", "Uninstall
AME using a Windows USB", "Select Windows ISO file" and "You can only use an
ISO that matches your Windows version". Deleted files and services come back
from matching install media. Nothing is undone in place.

---

## 4. User-facing post-install toolbox

### 4.1 Atlas: `%windir%\AtlasDesktop` + `%windir%\AtlasModules`

Source: `atlas/src/playbook/Executables/AtlasDesktop/**`, copied into place by
`custom.yml`. A desktop/start shortcut is made by
`tweaks/misc/create-shortcuts.yml`.

| Folder | Toggle categories (each is a pair or set of `.cmd` files; `(default)` marks the Atlas default) |
|---|---|
| `1. Software` | Install Software (winget-based `InstallSoftware.ps1`), Install or Remove Edge, Remove Python Store Prompt |
| `2. Drivers` | Drivers from Windows Update enable/disable (`.reg`), Run Update Drivers, links (DDU, NVCleanInstall, Bluetooth, Apple) |
| `3. General Configuration` | AI Features → Copilot, Recall · Automatic Updates · Background Apps · CPU Idle (+ desktop context menu toggle) · Delivery Optimization · FSO and Game Bar · File Sharing (+ Give Access To menu, Network Navigation Pane) · Hibernation · Location · Mobile Devices (Phone Link) · Power-saving · Search Indexing (Disable / Enable / Minimal) · Sleep · Sleep Study · Store App Archiving · System Restore · Timer Resolution (+ MeasureSleep.exe) · Update Notifications · Web Search · Widgets · Windows Spotlight · Windows Updates (Toggle, Set/Reset Deferral) · Workplace |
| `4. Interface Tweaks` | Context Menus → Extract, Run With Priority, Send To debloat, Take Ownership, Terminals, Windows 11 old/new menu · Edge Swipe · File Explorer → App Icons on Thumbnails, Automatic Folder Discovery, Compact View, Gallery, Quick Access, Removable Drives in Sidebar · Lock Screen · Old Flyouts (Battery, Date/Time, Volume) · Restart Explorer · Shortcut Icon (Classic/Default/None) · Shortcut Text · Snap Layouts · Start Menu (Open-Shell installer + preset, links to ExplorerPatcher/StartAllBack) · Unlock Recent Items · Verbose Status Messages · Visual Effects |
| `5. Windows Settings` | Shortcuts (`.url` `ms-settings:` / `.lnk`) to Activation, Colors, Date & Time, Default Apps, Graphics (HAGS), Desktop Icons, Language, Privacy, Region, Taskbar |
| `6. Advanced Configuration` | Boot Configuration (bcdedit appearance/behaviour + view current) · Driver Configuration links (MSI util, interrupt affinity…) · Microsoft Store enable/disable · Process Explorer install/uninstall · Services → Bluetooth, Lanman Workstation (SMB), NVIDIA Display Container (+ context menu), Network Discovery, Printing, SuperFetch |
| `7. Security` | Core Isolation (VBS) enable/disable/current · Defender → Toggle Defender, Hide App & Browser Control, Security Health Tray · Mitigations → Disable All / Enable All / Windows Default, Fault Tolerant Heap |
| `8. Additional Tools` | Links: Autoruns, Everything, HWInfo, HWMonitor |
| `9. Troubleshooting` | Fix Errors 2502/2503 · Network reset (Atlas / Windows defaults) · Repair Windows Components · Reset this PC (link) · Safe Mode (3 modes + exit) · Set services to defaults · Telemetry Components |
| root | Links to docs, Discord, GitHub, website; Install AtlasOS Toolbox |

**How a toggle is implemented** (e.g.
`3. General Configuration/Background Apps/Disable Background Apps (default).cmd`):

1. Sets `settingName` and `stateValue`.
2. Self-elevates with `fltmc` as the admin check, then `Start-Process -Verb RunAs`.
3. Records state: `reg add HKLM\SOFTWARE\AtlasOS\Services\<settingName>` with
   `state` (DWORD) and `path` (the script's own path).
4. Applies the change with plain `reg add` / `reg delete` (the Enable twin
   deletes the values to restore the Windows default).
5. Takes `/silent` (and `/noAction`) so the playbook can call the same file
   unattended. `services.yml` does exactly that for Location and Search
   Indexing.

**`atlas/default.yml` → `DEFAULT.ps1`** runs every `*(default).cmd` in
AtlasDesktop with `/silent /noAction`, after `DEFAULT.reg` seeds the state keys.
The playbook and the toolbox therefore share one implementation of each tweak.
`onUpgrade: true` on DEFAULT.ps1 re-seeds after an upgrade.

**`AtlasModules`** (support library, not user-facing):

| Path | Purpose |
|---|---|
| `Scripts/Modules/*/*.psm1` | PowerShell modules (AllRegistryUsers, Themes, Utils, Performance, UserPaths, Scripts, Qol, Privacy, Miscellaneous, Debloat, Shortcuts); `initPowerShell.ps1` loads them; `start.yml` adds AtlasModules, Tools and Scripts to machine PATH |
| `Scripts/ScriptWrappers/*.ps1` | Heavier logic behind toggles: ToggleDefender, RemoveEdge, ConfigVBS, Enable/DisableFileSharing, Default/DisablePowerSaving, UpdateDrivers, TelemetryComponents, InstallSoftware, DebloatSendToContextMenu |
| `Scripts/Registry/*/*.reg` | `.reg` pairs (Terminals, TakeOwnership, SecurityHealthTray) |
| `Scripts/*.cmd` | Helpers: `RunAsTI.cmd`, `setSvc.cmd`, `serviceWarning.cmd`, `toggleDev.cmd`, `newUsers.cmd/.ps1` (apply to new users), `packageInstall.ps1` (CAB install/uninstall, GPL-3.0-only, from he3als/online-sxs) |
| `Packages/*.cab` | sxsc-built component removal packages (amd64 + arm64) |
| `Toolbox/` | Scripts used by the separate Atlas Toolbox app |
| `Tools/` | `SetTimerResolution.exe`, `multichoice.exe` (hashes and sources in `AtlasModules/README.md`) |
| `Other/` | icons, start layout, timer task XML, service backups at runtime |
| `Wallpapers/` | Atlas wallpapers |

Atlas Toolbox (`install-toolbox` option) is a separate GUI downloaded at apply
time from `github.com/Atlas-OS/atlas-toolbox/releases/latest`.

### 4.2 Revi: Revision Tool

Revi ships no toolbox folder. `start.yml` downloads and installs **Revision
Tool** (`github.com/meetrevision/revision-tool`, Inno Setup, `/VERYSILENT`).
CI also bundles a SHA256-checked copy as a fallback. Revision Tool is both the
user-facing settings GUI and the playbook's engine; the playbook calls its CLI
`revitool.exe`:

| CLI call (from Revi YAML) | Purpose |
|---|---|
| `winpackage --install system-components-removal` / `ai-removal` / `onedrive-removal` / `xbox-removal` | CAB-based component removal |
| `tweaks security defender disable --force` / `enable` | Defender |
| `tweaks security vbs disable` | VBS/HVCI |
| `tweaks utilities hibernation enable/disable`, `fast-startup …` | Power |
| `tweaks performance powerplan enable`, `superfetch enable`, `background-apps enable`, `ntfs-last-access disable`, `ntfs-8dot3-naming disable`, `service-grouping set recommended`, `intel-tsx enable` | Performance |
| `tweaks updates wu-drivers disable`, `wu-pause-updates enable` | Update |
| `tweaks personalization input-personalization disable` | Privacy |
| `appx --all-users --remove <list>` | AppX removal |
| `tweaks patches` | "micro patches… to avoid new playbook releases for minor changes" |

Design consequence: most Revi behaviour lives **outside** the playbook, in a
separately versioned binary fetched at apply time.

### 4.3 Privacy+: Privacy+ Settings (closed-source .NET exe, ~20 MB)

Installed by `TOOLS.bat` (option `ame-tools`) to `%ProgramData%\AME`, with a
Start menu shortcut and an Add/Remove Programs entry. Menu entries recovered with
`strings` (the file was not run):

| Menu | Entries |
|---|---|
| Manage User Settings | Change Username / Password / Administrator Password / Profile Picture, Enable/Disable AutoLogon |
| Manage System Settings | Enable/Disable Enhanced Security, Hibernation, Desktop Notifications, Notification Center, UI Modifications, Corporate Login, NCSI active probing, VBScript, WSH; Restore/Hide Settings pages; .NET 3.5 from ISO/USB |
| Manage Keyboard Languages | Add/Remove |
| Manage Browsers / Software | Install/Uninstall configured Firefox, Ungoogled Chromium; NVIDIA Control Panel; AppFetch |
| Uninstall | Uninstall AME using a Windows ISO / USB; Remove AME Tools |

AME 10 ships the earlier `ame10_settings.exe`; P+ `TOOLS.bat` removes it on
upgrade.

---

## 5. Software installs

| | Mechanism | Browser choice | Other software |
|---|---|---|---|
| Atlas | `Executables/SOFTWARE.ps1` downloads with `curl.exe` from vendor URLs (Brave `laptop-updates.brave.com`, Firefox `download.mozilla.org`, Chrome enterprise MSI) and installs silently. LibreWolf via `LIBREWOLF.ps1` (GitLab API + Codeberg WinUpdater). **No `!software`, no `!download`, no `<Software>` in conf.** | RadioImagePage gated by `install-another-browser` checkbox; `Images/{brave,librewolf,firefox,chrome}.png` | Always installs 7-Zip (scraped from 7-zip.org), all VC++ redists 2005–2015+, DirectX June 2010, NanaZip check |
| Revi | Brave: `!download` (GitHub release, `cpuArch: X64` and `Arm64` variants, `package: 'brave'`) then `!run` the installer, then robocopy `BraveSoftware` policy/prefs. Firefox: `!software: {source: chocolatey, package: 'firefox'}`. `<Software>` lists both with `DefaultWebBrowser="true"`. | RadioImagePage with a `None` option | VC++ x64 via `!download` + `!run`; Revision Tool |
| Privacy+ | **`!software` (Chocolatey)** for git, 7zip, firefox, librewolf, thunderbird, spark, mailspring, vlc, mpv, nomacs, vcredist-all, onlyoffice, freeoffice, libreoffice, cascadiamono. `!download` with `git:` + `regex:` for UGC (`iso: only`), and URL for Brave. Post-install `.bat` per app writes config/policies/associations (e.g. `FIREFOX.bat`, `BRAVE.bat`, `VLCASSOC.bat`, `FILEASSOC.bat`). | RadioImagePage, Firefox default, no None | Office/mail/media RadioImagePages each with `None` |

How `<Software>` ties in (Revi, Privacy+): a `Package` with `Option="browser-x"`
and `<Name>x</Name>` matches `package: 'x'` on the `!software`/`!download`
action. At ISO injection AME pre-downloads it; at OOBE AME shows it with the icon
from `Images/`. Atlas skips this and requires internet at OOBE
(`<Internet>Force</Internet>`).

Images: all four use `Images/<FileName>.png` for RadioImageOption art. Atlas and
Revi keep `playbook.png` in the root; P+ and AME 10 keep it in `Images/`.

Hardening after install: P+ sets Brave policies (`BraveVPNDisabled`,
`BraveRewardsDisabled`, `BraveWalletDisabled`, `BraveAIChatEnabled=0`) and the
Firefox `BackgroundAppUpdate=0` policy. Revi copies a `BraveSoftware`
prefs tree. Atlas says "Browser settings are not modified".

---

## 6. Build gating, UCPD, ISO/OOBE

### 6.1 `builds:`

| | Usage |
|---|---|
| Atlas | Task-level `builds: [ '>=22000' ]` on ~15 Win11-only tweak files (Copilot, Recall, Gallery, compact mode, old context menu, taskbar left, end-task, etc.); action-level `'<22000'`/`'>=22000'` pairs in `set-hidden-settings-pages.yml` and `set-unpinned-notification-items.yml`. These are leftovers from Win10 support, because `SupportedBuilds` is now only 26100/26200. No 23H2-vs-24H2 gating anywhere. `cpuArch: 'Arm64'`/`'X64'` used for arch splits. |
| Revi | **No `builds:` at all.** Win10 vs 11 is detected at runtime: `FINALIZE.cmd` reads `CurrentBuild` and sets `w11` if > 19045. Build-specific behaviour is pushed into Revision Tool. |
| Privacy+ | `builds: [ '<22621.2428' ]` (UBR-precise) to install ExplorerPatcher only on older builds. |
| AME 10 | Separate playbook per OS (10 vs 11), not gating. |

Conclusion: in practice, target-build differences are handled by **narrowing
`SupportedBuilds`** (Atlas), **shipping separate playbooks** (AME), or **runtime
detection in a helper binary** (Revi). Per-tweak `builds:` is used sparingly.

### 6.2 UCPD (User Choice Protection Driver)

| | Handling |
|---|---|
| Atlas | `UCPDDisabled` requirement (user does it in Prepare System), and also sets `UCPD` service start=4 in `services.yml`, disables the `UCPD velocity` scheduled task, and `FILEASSOC.cmd` uses "a temporary renamed PowerShell executable to bypass UCPD" |
| Revi | No requirement. Sets `UCPD` service start=4 and disables `UCPD velocity` task in `services.yml`. Associations via `FILEASSOC.cmd` / `assoc.ps1` |
| Privacy+ | `UCPDDisabled` requirement |

UCPD matters only if the playbook writes default-app associations (browser,
media, photos).

### 6.3 ISO / OOBE

| | ISO | OOBE internet | Per-action flags |
|---|---|---|---|
| Atlas | `SupportsISO` true | `Force` | `iso: only` on deleting `HKLM\OfflineSys\ControlSet001\Services\WdBoot` (offline hive during injection, Defender-disable only); `oobe: false` on hive load/unload; `oobe: only` on context-menu and search tweaks; `oobe: true` on theme |
| Revi | true (README: "ISO Injection is only supported on Windows 11 ISOs") | `Request` | `oobe: true` on an AppX step; `oobe: false, iso: false` on `ONED.cmd`; `oobe: only` on wallpaper RunOnce |
| Privacy+ | true | (commented) | `iso: only` on the UGC `!download`; `iso: false, oobe: false` on Mailspring; `Executables/ISO/*.bat` variants exist (mostly unreferenced) |

`HKLM\OfflineSys` (the offline SYSTEM hive mounted during injection) is not in
our `docs/`. It is an observed convention only.

---

## 7. Repo, CI and release engineering

| | Atlas | Revi |
|---|---|---|
| Repo layout | `src/playbook/` (playbook root), `src/dependencies/local-build.ps1`, `src/sxsc/*.yaml` (CAB definitions), `src/release-zip/` (extra files shipped with the release), `.github/workflows/apbx.yaml` | `src/` is the playbook root; `.github/workflows/main.yml` |
| Trigger | push touching `src/**` or any YAML; manual dispatch | manual dispatch only |
| Lint | `yamllint` (relaxed; line length etc. disabled) | none |
| Extra build step | If `src/sxsc/*.yaml` changed: clone `Atlas-OS/sxsc`, make self-signed cert, build CABs, **commit them back** to `AtlasModules/Packages` | Download latest `RevisionTool-Setup.exe`, verify SHA256 against the GitHub asset digest, bundle as fallback |
| Version | Hand-edited SemVer in `playbook.conf`; `local-build.ps1` injects `v<Version>` (+ " (dev)" if Title has "(dev)") into OEM info YAML at build time | CalVer `YY.MM` computed from date; CI rewrites `<Version>` in `playbook.conf` and `set version=` in `FINALIZE.cmd` |
| Packaging | `local-build.ps1`: 7-Zip **`-tzip` with `-pmalte`, `-mx1`**; can strip `<Requirement>`, `SupportedBuilds`, `ProductCode` lines for test builds (CI uses `-Removals Verification, WinverRequirement`), and inject a live-log `!cmd` into `custom.yml` | `7z a -pmalte -mhe=on Revi-PB-<ver>.apbx ./src/*` (7z, header encryption) |
| Output | Artifact `Atlas Playbook` = `.apbx` + `release-zip/*` (`.reg`, `.url`); **GitHub release is manual** (not in workflow) | `svenstaro/upload-release-action`: tag = version, release name = version, one `.apbx`, body with SHA256 of the apbx and of bundled Revision Tool, `overwrite: true` |
| Dev build | `build-playbook.cmd` / `.sh` (pwsh on Linux/macOS) → "Atlas Test.apbx" | none |

Notes:

- Both **`.zip` and `.7z` containers with password `malte` are accepted in
  practice**. Our docs (recon §2) describe 7z. Keep 7z.
- Revi's CI artifact strips nothing; Atlas's CI artifact strips verification and
  the build gate, so the CI artifact is **not** the release artifact.
- Revi's `overwrite: true` on a fixed tag can replace a release in place. That
  breaks "tag = Version, exactly one .apbx" only if re-run in the same month.

---

## 8. Licensing

| Project | License file | Per-file notices found |
|---|---|---|
| Atlas | `atlas/LICENSE`: **GNU GPL v3** (full text). README: "The Atlas Playbook is open source under the GPLv3 license." | `AtlasModules/Scripts/packageInstall.ps1`: "GPL-3.0-only … Modified from he3als/online-sxs". `ScriptWrappers/RemoveEdge.ps1`: "originally made by ShadowWhisperer … CC0-1.0". `AtlasModules/README.md`: bundled binaries are GPLv3 (multichoice, SetTimerResolution/MeasureSleep), ViVeTool from thebookisclosed. `src/sxsc/*.yaml`: `copyright: Atlas`. |
| ReviOS | `revi/LICENSE`: **CC BY-SA 4.0** (full legal code). README says the same. | `Executables/WALLPAPER.ps1`: snippet from superuser.com, CC BY-SA 4.0. `Executables/Licenses/`: `brave-browser-mpl.txt` (MPL-2.0, for the Brave config), `fluent-gtk-theme-gnu-gpl-v3.0.txt` (GPLv3 art). `Executables/hosts` starts with Microsoft's sample hosts header. |
| Privacy+ / AME 10 | **No license file** in either `.apbx` | Closed-source binaries: `privacy+_settings.exe`, `appfetch.exe`, `ame-hexer.exe`, `install_wim_tweak.exe`, plus third-party ones (NSudo, Open-Shell, ExplorerPatcher, 7za). |
| AME Wizard backend | — | Atlas README: TrustedUninstaller CLI is MIT (`github.com/Ameliorated-LLC/trusted-uninstaller-cli`), useful for checking action semantics. |

**What we may do, in plain terms** (not legal advice):

- **Reading, learning, and re-implementing ideas is free.** A registry path and
  value name ("set X to 0") is a fact about Windows, not creative expression. If
  we write our own YAML from our own understanding and cite where we learned it
  (our CLAUDE.md already asks for `# AtlasOS: …` comments), no license
  obligation follows. Keep the citations: they are good hygiene, not a
  requirement.
- **Copying Atlas files or substantial chunks (scripts, YAML layouts, the
  toggle .cmd files, modules) makes our playbook a derivative of GPLv3 code.**
  Obligations when we distribute the `.apbx` or the repo:
  1. License the combined work as **GPLv3** (we cannot use MIT/Apache/
     proprietary for the whole). No extra restrictions.
  2. Keep Atlas's copyright and license notices; include the GPLv3 text.
  3. Mark modified files with a prominent notice that we changed them, and when.
  4. Provide the corresponding source. Our public repo covers this, and the
     `.apbx` is mostly source anyway. Any binary we ship needs its source
     available too.
  5. Do not use Atlas's names or branding for our product. GPL gives no
     trademark rights, and Atlas has a branding policy.
- **Copying ReviOS material under CC BY-SA 4.0** requires: attribution
  (credit "Revision / ReviOS", link the source and the license, say what we
  changed); **ShareAlike**: our adaptation must be under CC BY-SA 4.0 **or a
  compatible license**. Creative Commons lists **GPLv3 as a one-way compatible
  license** for BY-SA 4.0, so ReviOS-derived pieces may live inside a GPLv3
  Claude Playbook, with attribution kept. No DRM or extra restrictions.
  CC BY-SA is awkward for code (no patent clause, attribution rules per file), so
  prefer rewriting Revi logic over copying it.
- **Do not copy anything from Privacy+ / AME 10.** No license is granted, so
  treat it as all-rights-reserved. Never redistribute their binaries.
- **Third-party pieces inside Atlas/Revi keep their own licenses** (CC0 Edge
  remover, MPL Brave config, GPLv3 tools). If we take one, carry its notice.
- **Our repo has no license today.** If we intend to copy any Atlas code, adopt
  **GPL-3.0-only or GPL-3.0-or-later now**, add `LICENSE` and a
  `THIRD_PARTY_NOTICES.md`, and keep per-file headers on anything copied. If we
  intend to stay clean-room, any license works, but GPLv3 keeps both doors
  (Atlas and Revi) open.

---

## 9. Fields and parameters seen in refs but not in `docs/`

Per CLAUDE.md rule 3, these stay **unknown until proven in a VM**. `validate.py`
must not learn them from this file alone.

| Item | Seen in | Status in `docs/` |
|---|---|---|
| `<Overhaul>` | Atlas, P+, AME 10 | not documented |
| `<EstimatedMinutes>` | Atlas | not documented |
| `DefaultWebBrowser="true"` on `<Package>` | Revi, P+ | not documented |
| `NoTweakware`, `LocalAccounts` requirements | P+, AME 10 | not documented |
| Task-level `privilege:` (`Admin`, `TrustedInstaller`), `description:`, `onUpgrade:` | all | only `title`, `option`, `options`, `builds` documented |
| `!writeStatus` | Atlas, Revi | conflict recorded in recon §15; refs prove it is accepted |
| Backslash `!task` paths | all | accepted in practice; we keep forward slashes |
| `custom.yml` as entrypoint | Atlas | deprecated per changelog, still accepted |
| `status:` parameter on `!download`/`!run` | P+ | documented as a shared parameter (`action-catalog.md`); OK |
| `hideWindow:` on `!run` | P+ | not in `action-catalog.md` (`validate.py` already tolerates it, citing P+) |
| `HKLM\OfflineSys\…` paths with `iso: only` | Atlas | not documented |
| `.zip` container (`-tzip`) | Atlas | docs say 7z |
| `cpuArch: Arm64` / `'X64'` | Atlas, Revi | catalog has `cpuArch`; enum case per recon §15 |

---

## 10. Recommendations for Claude Playbook

### 10.1 Stance (to confirm in Phase 3)

Follow the **Atlas model**: tweaks are reversible, opt-in where risky, and the
same scripts serve the playbook and a post-install toolbox. Avoid the
**Privacy+ model** (file deletion, service deletion, uninstall needs an ISO).
Avoid the **Revi model** of depending on an external binary fetched at apply
time.

### 10.2 Target builds

```xml
<SupportedBuilds>
  <string>26100</string> <!-- 24H2 -->
  <string>26200</string> <!-- 25H2 -->
</SupportedBuilds>
```

- Start with 24H2 and 25H2 only, as Atlas does. Each extra build is another VM
  matrix row in Phase 6.
- 23H2 (22631): Home/Pro servicing ended 2025-11-11 (Enterprise/Education end
  2026-11-10). Add it only if a user need appears, and then gate 24H2-only tweaks
  (Recall, new Copilot app, etc.) with task-level `builds: ['>=26100']`.
- No Windows 10.

### 10.3 Requirements

```xml
<Requirements>
  <Requirement>Internet</Requirement>
  <Requirement>NoPendingUpdates</Requirement>
  <Requirement>NoAntivirus</Requirement>
  <Requirement>PluggedIn</Requirement>
  <Requirement>DefenderToggled</Requirement>   <!-- needed to write Defender/SmartScreen policy; keeps Defender installable -->
  <!-- <Requirement>UCPDDisabled</Requirement>  add only when we set default-browser associations -->
</Requirements>
```

Do **not** use `DefenderDisabled`: it also strips Defender during ISO injection,
which cannot be undone in place. Do not use `Activation`, `PasswordSet`, or
`AdministratorPasswordSet`; they add friction for no benefit to us.

### 10.4 Feature pages (proposal)

Set `IsChecked` explicitly on every checkbox; don't rely on the implicit `true`.

| # | Page | Options (Name → default) | Rationale |
|---|---|---|---|
| 1 | RadioPage "Microsoft Defender" | `defender-keep` (recommended, default) · `defender-policy-off` (disable via policy/services only, reversible by toggle script) | Rule 5: no CAB/file removal in v1 |
| 2 | RadioPage "Windows Update" | `updates-default` (default) · `updates-notify` (no automatic install, no auto-reboot, no feature-update jump) | Atlas defaults to disabling auto updates; we default to Windows behaviour and offer notify-only |
| 3 | CheckboxPage "Remove built-in apps" | `remove-consumer-appx` ✓ (Bing apps, Clipchamp, Solitaire, …, re-installable from Store) · `remove-copilot-recall` ✓ · `remove-onedrive` ✓ · `remove-edge` ✗ · `remove-xbox` ✗ · `remove-phone-link` ✗ | Revi-style granular choices with conservative defaults; Edge/Xbox off by default |
| 4 | CheckboxPage "Interface" | `ui-classic-context-menu` ✓ · `ui-dark-mode` ✗ · `ui-taskbar-left` ✗ · `ui-no-start-recommendations` ✓ · `ui-show-extensions` ✓ | Matches Revi page 6 / Atlas QoL; cosmetic changes default off |
| 5 | CheckboxPage "Power & performance" | `disable-hibernation` ✗ · `power-high-performance` ✗ · `disable-core-isolation` ✗ | Atlas page 4, but unchecked: security and battery trade-offs |
| 6 | CheckboxPage "Extras" | `install-toolbox` ✓ (copies our post-install folder) · `install-browser` ✗ | Toolbox is the documented way back (rule 5) |
| 7 | RadioImagePage "Browser", `DependsOn="install-browser"`, `CheckDefaultBrowser="true"` | `None` · `browser-firefox` (default) · `browser-brave` · `browser-librewolf` | P+/Revi pattern; `Images/<name>.png` at 128 px height |

Leave CPU mitigations out of v1. If we add them later, copy Atlas page 2 with
`mitigations-default` as the default.

### 10.5 Repository and `main.yml` layout

Keep our current layout (`playbook/Configuration/main.yml`, forward slashes,
`!status`). Proposed order, from the reasoning in §2.2:

```yaml
title: Main
actions:
  - !status: {status: 'Preparing'}
  - !task: {path: 'Tasks/start.yml'}            # copy toolbox to %windir%\ClaudePlaybook, back up service Start values, export touched reg keys, PATH
  - !status: {status: 'Removing apps'}
  - !task: {path: 'Tasks/components.yml'}       # Edge / OneDrive / Copilot+Recall (option-gated, script-based, reversible)
  - !task: {path: 'Tasks/appx.yml'}             # !appx + Deprovisioned keys (as Atlas)
  - !status: {status: 'Configuring services'}
  - !task: {path: 'Tasks/services.yml'}         # !service change only, never delete
  - !task: {path: 'Tasks/scheduled-tasks.yml'}  # disable, never delete
  - !status: {status: 'Applying tweaks'}
  - !task: {path: 'Tasks/registry.yml'}         # → Tasks/registry/{privacy,qol,explorer,updates,security}.yml
  - !task: {path: 'Tasks/performance.yml'}      # power plan last-ish, as Atlas
  - !status: {status: 'Installing software'}
  - !task: {path: 'Tasks/software.yml'}         # !software chocolatey + <Software> packages
  - !task: {path: 'Tasks/upgrade.yml'}          # onUpgrade: true — roll back tweaks dropped since older versions (Atlas/Revi revert.yml role)
  - !status: {status: 'Finalizing'}
  - !task: {path: 'Tasks/finalize.yml'}         # run "(default)" toggles silently, snapshot post-state, clear AppX caches, restart explorer
```

No explicit reboot. AME Wizard reboots at the end, and none of the four refs
reboots from YAML.

### 10.6 Revert strategy

1. **Toolbox of paired scripts** (Atlas pattern) under
   `playbook/Executables/Toolbox/<Category>/<Setting>/{Enable,Disable} … (default).cmd`,
   copied to `%windir%\ClaudePlaybook`. Each script records
   `HKLM\SOFTWARE\ClaudePlaybook\Settings\<Setting>` `state`/`path`, supports
   `/silent`, and is the **only** implementation. The YAML calls it, so revert is
   always the twin script.
2. **Snapshots before change:** export service `Start` values (Atlas
   `BACKUP.ps1` idea) and every registry key we touch to
   `%windir%\ClaudePlaybook\Backup\*.reg`. Ship `Restore Windows defaults.cmd`
   that re-imports them.
3. **Never** `!file` delete system files, `!service … delete`, overwrite `hosts`,
   or install removal CABs in v1. AppX are removed with deprovisioning and can
   come back from the Store.
4. **Upgrades:** `UpgradableFrom` set to the previous minor range; task-level
   `onUpgrade: false` on one-shot removals once proven in a VM; `Tasks/upgrade.yml`
   with `onUpgrade: true` for rollbacks; use `onUpgradeVersions` for
   version-specific fixes.
5. **Full uninstall** is documented as "run *Restore Windows defaults*, then
   reinstall removed apps from Store", with "Reset this PC" as the fallback.

### 10.7 ISO / OOBE

v1: `SupportsISO` **off**. Most of our work is scripts, and dynamic actions
cannot run at injection. Once the live-apply path is proven, enable ISO with
`<Internet>Request</Internet>`. Add `<Software>` packages whose `<Name>` matches
`package:` on `!software` so browsers are cached at injection. Add `iso`/`oobe`
flags per action.

### 10.8 CI build

`.github/workflows/build.yml` (adapt the pattern; write it ourselves):

1. On push/PR: `pip install pyyaml py7zr`, `python3 tools/validate.py`
   (fail on errors). Optionally run `yamllint` relaxed, as Atlas does.
2. `python3 tools/package.py` → upload `dist/*.apbx` as an artifact named with
   the short SHA (test build).
3. On tag `v*` or manual dispatch: assert `tag == <Version>` from
   `playbook.conf`, build, compute SHA256, and create a GitHub release with
   **exactly one** `.apbx` and the hash in the body (Revi pattern). Never use
   `overwrite: true` on an existing tag.
4. Keep SemVer (`0.2.0`, …), hand-bumped per CLAUDE.md rule 6, rather than Revi's
   CalVer. That makes `UpgradableFrom` ranges meaningful.
5. If we ever bundle a binary, pin its URL and verify its SHA256 in CI (Revi
   pattern), and list it in an `Executables/README.md` hash table (Atlas
   pattern).

### 10.9 Licensing action

Decide before Phase 4: adopt **GPL-3.0** for Claude Playbook if any Atlas code
may be copied (recommended), add `LICENSE` and `THIRD_PARTY_NOTICES.md`, and
require a header on any file derived from Atlas or Revi.

---

## Summary

All four refs share one skeleton: `playbook.conf` with feature pages, an
orchestrating entry YAML, domain task files, and `Executables/`. Their
philosophies differ. **Atlas** (GPLv3, 24H2/25H2 only) keeps Defender and
Update available, ships 159 toggle/helper scripts (58 marked `(default)`) in
`%windir%\AtlasDesktop` that the playbook itself reuses, backs up service
states, and removes components with reversible CAB packages. **ReviOS**
(CC BY-SA 4.0, Win10+11) delegates most work to its external Revision Tool
binary and uses CalVer CI releases. **Privacy+/AME 10** (no license) delete
files and services outright; uninstall needs a Windows ISO. Every
`revert.yml` only rolls back older-version tweaks on upgrade (`onUpgrade:
true`); none undoes the playbook. For Claude Playbook we recommend: target
26100/26200, light requirements (`DefenderToggled`, not `DefenderDisabled`),
seven explicit feature pages with conservative defaults, the Atlas-style toggle
toolbox plus `.reg` snapshots as the revert path, no ISO in v1, SemVer with a CI
release that checks tag = Version and attaches one `.apbx`, and adopting GPLv3
before copying any Atlas code.
