# Debloat inventory: AtlasOS, ReviOS, AME Privacy+, AME 10

Research for Phase 3 (design). Compiled 2026-10-09 by reading the extracted
reference playbooks only. No script or binary from them was executed.

Abbreviations: **A** = AtlasOS 0.5.0, **R** = ReviOS 26.04 (release `.apbx`),
**P+** = AME Privacy+ 0.8.2 (Win11), **10** = AME 10 0.8 (Win10 19044/19045).
Paths are relative to `refs/` (the scratchpad extraction):

| Short | Root used in this doc |
|-------|-----------------------|
| A | `atlas/src/playbook/` (sxsc packages: `atlas/src/sxsc/`) |
| R | `revi-apbx/` (same layout as `revi/src/`; the release was preferred) |
| P+ | `privacyplus/` |
| 10 | `ame10/` |

Legend in tables: `x` = removed or applied unconditionally; `opt:name (on)` /
`opt:name (off)` = behind feature-page option `name`, checked or unchecked by
default; `-` = not touched. **Bold** row = consensus (3 or more playbooks).
Checkbox defaults come from `playbook.conf`; per `docs/reconnaissance.md`
`IsChecked` defaults to `true` when omitted, so all Atlas checkboxes start checked.

Supported builds (from each `playbook.conf`):

| | Builds |
|---|---|
| A | 26100, 26200 only |
| R | 19044, 19045, 22631, 26100, 26200 |
| P+ | 22000, 22621, 22631, 22635, 26100, 26200 |
| 10 | 19044, 19045 |

---

## 0. How each playbook removes things

| | APPX | Components | Big items |
|---|---|---|---|
| A | `!appx` per family in `Configuration/atlas/appx.yml`, plus a PowerShell diff that writes `AppxAllUserStore\Deprovisioned\<family>` for everything that disappeared | Self-built CBS packages from `atlas/src/sxsc/*.yaml` (`Z-Atlas-NoTelemetry-Package`, `Z-Atlas-NoDefender-Package`) installed by `AtlasModules/Scripts/packageInstall.ps1`. They "update" target components to version 38655.38527.65535.65535 with empty payloads. **Reversible**: uninstalling the package restores the originals. | Toggle scripts in `Executables/AtlasDesktop/**` (each writes `HKLM\SOFTWARE\AtlasOS\Services\<name>` state) |
| R | `Executables/APPX-REMOVER.ps1` (pattern `*name*` on PackageFullName; writes `Deprovisioned`, `EndOfLife\<SID>`, clears NonRemovable via `Set-NonRemovableAppsPolicy`, then `Remove-AppxPackage -AllUsers`) | `revitool.exe winpackage --install <pkg>` (Revision Tool, downloaded from GitHub `releases/latest` in `Tasks/start.yml`). Package contents are **not in this repo**. `Tasks/packages/win-sxs.yml` says `!systemPackage` is deprecated by Revision ("main cause of #49"). | `revitool.exe tweaks ...` sub-commands, PowerShell scripts |
| P+ / 10 | Plain `!appx` wildcard list in `Configuration/tasks/appx.yml` | One `!systemPackage` (`Microsoft-Windows-Internet-Browser-Deployment`, amd64) plus about 320 hard `!file` deletes, `!service ... delete`, and an `sfc.exe` replacement (`Executables/SFCDEPLOY.bat`) so SFC cannot restore deleted files | Hard deletion, no revert path |

---

## 1. APPX packages

### 1.1 Comparison table

Names are the family or the pattern each playbook uses. P+ and 10 use `*x*` wildcards.

| Package (family) | What it is | A | R | P+ | 10 |
|---|---|---|---|---|---|
| **Microsoft.549981C3F5F10** | Cortana app | x | x | x | x |
| **Microsoft.BingNews** | News | x | x | x (`*Bing*`) | x |
| **Microsoft.BingWeather** | Weather | x | x | x (`*Bing*`) | x |
| **Microsoft.BingSearch** | Bing search app (24H2) | x | x | x (`*Bing*`) | x |
| **Clipchamp.Clipchamp** | Video editor | x | x | x | x |
| **Microsoft.GetHelp** | Get Help | x | x | x | x |
| **Microsoft.Getstarted** | Tips | x | x | x | x |
| **Microsoft.Microsoft3DViewer** | 3D Viewer | x | x | x | x |
| **Microsoft.MicrosoftOfficeHub** | Office/M365 hub | x | x | x | x |
| **Microsoft.MicrosoftSolitaireCollection** | Solitaire | x | x | x (`*Solit*`) | x |
| **Microsoft.MicrosoftStickyNotes** | Sticky Notes | x | x | x (`*Sticky*`) | x |
| **Microsoft.Office.OneNote** | OneNote UWP | x | x | x (`*OneNote*`) | x |
| **Microsoft.People** | People | x | x | x | x |
| **Microsoft.PowerAutomateDesktop** | Power Automate | x | x | x (`*PowerAutomate*`) | x |
| **Microsoft.SkypeApp** | Skype | x | x | x | x |
| **Microsoft.Todos** | To Do | x | x | x | x |
| **Microsoft.WindowsAlarms** | Clock | x | x | x | x |
| **Microsoft.WindowsCamera** | Camera | x | x | x | x |
| **Microsoft.WindowsFeedbackHub** | Feedback Hub | x | x | x (`*FeedbackHub*`) | x |
| **Microsoft.WindowsMaps** | Maps | x | x | x | x |
| **Microsoft.WindowsSoundRecorder** | Sound Recorder | x | x | x | x |
| **microsoft.windowscommunicationsapps** | Mail and Calendar | x | x | x | x |
| **Microsoft.ZuneVideo** | Films & TV | x | x | x (`*Zune*`) | x |
| **Microsoft.MixedReality.Portal** | Mixed Reality Portal | x | x (`MixedReality.Portal`) | x (`*MixedReality*`) | x |
| **Microsoft.OutlookForWindows** | New Outlook | x | x | x | x |
| **SpotifyAB.SpotifyMusic** | Spotify stub | x | x | x | x |
| **MicrosoftCorporationII.MicrosoftFamily** | Family Safety | x | x | x | x |
| **Microsoft.Windows.DevHome** | Dev Home | x | opt:`remove-appx-devhome` (on) | x | x |
| **MicrosoftTeams / MSTeams** | Teams (consumer/chat, new Teams) | x | opt:`remove-teams` (on) | x | x |
| **Microsoft.YourPhone** | Phone Link | x (PowerShell, see note) | opt:`remove-appx-yourphone` (on) | x | x |
| **Microsoft.MSPaint** | Paint 3D (not new Paint) | x | x | - | - |
| **Microsoft.XboxApp** | Xbox Console Companion (deprecated) | x | opt:`remove-appx-xbox` (off) | x | x |
| **Microsoft.Copilot** | Copilot app | x | opt:`remove-winsxs-ai` (on) | x | - (Win10) |
| **Microsoft.MicrosoftEdge** (UWP/stub) | Edge AppX | opt:`uninstall-edge` (on) | opt:`remove-edge` (on) | x (`*MicrosoftEdge*`) | x |
| **MicrosoftWindows.Client.WebExperience** | Widgets / Web Experience Pack | - (policy only) | x | x | x |
| **MicrosoftCorporationII.QuickAssist** | Quick Assist | - | x | x | x |
| **Microsoft.ZuneMusic** | Media Player (new) / Groove | - | x | x (`*Zune*`) | x |
| **Microsoft.Windows.Photos** | Photos | - | opt:`remove-appx-photos` (on) | x (`*Photos*`) | x |
| **Microsoft.GamingApp** | Xbox app | - | opt:`remove-appx-xbox` (off) | x | x |
| **Microsoft.Xbox.TCUI / XboxGamingOverlay / XboxGameOverlay / XboxSpeechToTextOverlay / XboxIdentityProvider** | Game Bar, Xbox sign-in UI | - | opt:`remove-appx-xbox` (off), pattern `Microsoft.Xbox` | x (separate patterns; **`*XboxIdenitity*` is a typo**, so XboxIdentityProvider survives) | x (same typo) |
| **Microsoft.XboxGameCallableUI** | Xbox callable UI (system app) | - | explicitly excluded | x | x |
| Microsoft.Windows.PeopleExperienceHost | People bar host | - | x | x | x |
| Microsoft.Windows.SecureAssessmentBrowser | Take a Test | - | x | x | x |
| Microsoft.StartExperiencesApp | Start "experiences" (24H2+) | - | x | x | - |
| Microsoft.Edge.GameAssist | Edge Game Assist | - | opt (edge or xbox) | x | - |
| Microsoft.WidgetsPlatformRuntime | Widgets runtime | - | x | - | - |
| Disney.37853FC22B2CE | Disney+ stub | x | - | x | x |
| MicrosoftWindows.CrossDevice | Cross Device Experience Host | - | opt:`remove-appx-yourphone` (on) | - | - |
| Microsoft.MicrosoftEdgeDevToolsClient | Edge DevTools client | - | opt:`remove-edge` | (via `*MicrosoftEdge*`) | same |
| Microsoft.ScreenSketch | Snipping Tool | opt:`remove-snipping-tool` (on) | - | - | - |
| Ink.Handwriting.Main.Store.en-US1.0 | Handwriting pack | x | - | - | - |
| Microsoft.Whiteboard, Microsoft.MicrosoftPowerBIForWindows, MicrosoftTeamsforSurfaceHub, MailforSurfaceHub | Surface Hub/Team edition apps | - | x | - | - |
| Microsoft.Office.Excel / PowerPoint / Word, OutlookPWA | Office PWAs | - | x | - | - |
| Microsoft.Advertising (Xaml framework) | Ad SDK | - | x | - | - |
| Flipgrid | Flip | - | opt:`remove-teams` | - | - |
| OneDrive / microsoft.microsoftskydrive (AppX) | OneDrive AppX | - | opt:`remove-onedrive` (on) | x (`*OneDrive*`) | x |
| Microsoft.WindowsStore | **Microsoft Store** | - | - | x | x |
| *StorePurchaseApp* | Store purchase UI | - | - | x | x |
| *SecHealthUI* | **Windows Security app** | - | - | x | x |
| *Apprep.ChxApp* | SmartScreen UI host | - | deprovisioned only | x | x |
| *CloudExperienceHost* | OOBE / MSA sign-in / Windows Hello UI | - | - | x | x |
| *ContentDeliveryManager* | Spotlight / suggestions | - | deprovisioned only | x | x |
| *AssignedAccessLockApp*, *OOBENetwork*, *PinningConfirmationDialog*, *Parental*, *Wallet*, *CommsPhone*, *Messaging*, *OneConnect*, *ConnectivityStore*, *WindowsPhone*, *Sway*, *CamoStudio* | Kiosk lock, OOBE network page, misc legacy | - | - | x | x |
| AI set: *MicrosoftWindows.Client.AIX*, *Microsoft.Windows.Copilot*, *Client.CoPilot*, *Ai.Copilot*, *Client.CoreAI* | Recall/Click to Do/AI runtime (24H2+) | - | via revitool `ai-removal` (contents unknown) | x | - |
| `type: app` inside Client.CBS: *Global.IrisService*, *Global.Accounts*, *Global.ValueBanner*, *Global.DesktopSpotlight*, *WindowsBackup*, *CrossDeviceResume*, *WebExperienceHost* | Spotlight, Settings banners, Windows Backup app | - | - | x | x (no CrossDeviceResume) |

Sources: A `Configuration/atlas/appx.yml`, `Configuration/atlas/components.yml`;
R `Configuration/Tasks/packages/appx.yml`, `Configuration/Tasks/packages/app-win32.yml`;
P+ / 10 `Configuration/tasks/appx.yml`, P+ `Configuration/tasks/components.yml` ("Removing AI Components").

Notes:
- A removes YourPhone with raw PowerShell because "Removing using AME Wizard causes
  issues with Cross Device Experience Host installing" (`atlas/appx.yml`).
- A clears AppX caches of `*MicrosoftWindows.Client.CBS*`, `*Microsoft.Windows.Search*`,
  `*Microsoft.Windows.SecHealthUI*`; R and P+ do the same for Client.CBS,
  StartMenuExperienceHost, Windows.Search (and R: TCUI). `!appx operation: clearCache`
  is a consensus step after removals.
- **Deprovisioning (consensus A, R):** both write
  `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\<PackageFamilyName>`
  so feature updates do not re-provision removed apps. R also adds `EndOfLife\<SID>\<FullName>`.
  R's `Configuration/Tasks/registry/misc/deprovisioned-apps.yml` deprovisions **apps it keeps**
  too: `Microsoft.WindowsCalculator`, `Microsoft.WindowsNotepad`, `Microsoft.Paint`,
  `Microsoft.SecHealthUI`, `Microsoft.Windows.Photos` (even when the Photos option is off),
  `Microsoft.Windows.Apprep.ChxApp`, `Microsoft.Windows.ContentDeliveryManager`. Do not copy that blindly.
- A and R block the OOBE re-installers for Dev Home and new Outlook:
  `HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\{DevHomeUpdate,OutlookUpdate}`
  plus `...\UScheduler\<x>\workCompleted=1`; R also sets `UScheduler_Oobe\BlockedOobeUpdaters = ["MS_Outlook"]`.
  Both set `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications\ConfigureChatAutoInstall=0` (Teams).

### 1.2 Kept on purpose

| App | A | R | P+ / 10 | Why (as stated or evident) |
|---|---|---|---|---|
| Microsoft Store (`WindowsStore`) | kept (pinned in Start) | kept | **removed** | A, R: needed to reinstall removed apps ("most of these applications can be reinstalled via Microsoft Store", A `appx.yml`). A offers `AtlasDesktop/6. Advanced Configuration/Microsoft Store/Disable Microsoft Store.cmd` post-install. |
| DesktopAppInstaller (winget) | kept | kept | kept (line commented out) | Package manager; R/A install software via it |
| Calculator | kept | kept (deprovisioned) | kept (`*Microsoft.Calculator*` does not match `Microsoft.WindowsCalculator`; the WindowsCalculator line is commented out) | Core utility |
| Paint (new), Notepad, Terminal | kept | kept (deprovisioned) | kept (Paint line commented out; Terminal installed by `software.yml`) | Core utilities |
| Photos | kept | optional (default remove) | removed | R falls back to classic Photo Viewer (`registry/misc/classic-photo-viewer.yml`, `FILEASSOC.cmd` under the option) |
| Snipping Tool | optional (default remove) | kept | kept | A also disables PrintScreen hotkey when removed |
| Xbox app, Game Bar overlays, Xbox Identity | kept (only the deprecated XboxApp is removed) | optional, **default off** | removed (except XboxIdentityProvider by typo) | A: excludes Xbl/Xbox services from svchost grouping "to fix issues with Game Bar"; R: Xbox removal breaks Game Pass/Xbox sign-in, so opt-in, and keeps `XboxGameCallableUI` |
| Windows Security UI (`SecHealthUI`) | kept | kept (deprovisioned) | removed | P+ removes Defender entirely |
| Widgets (`WebExperience`) | kept, policy-disabled | removed | removed | A prefers a reversible policy toggle |
| Media Player (`ZuneMusic`), Quick Assist | kept | removed | removed | |
| Phone Link | removed | optional (default remove) | removed | |

---

## 2. Windows components

### 2.1 `!systemPackage` and component-store (WinSxS) removal

| Item | A | R | P+ | 10 |
|---|---|---|---|---|
| Edge Legacy / browser deployment: `!systemPackage: Microsoft-Windows-Internet-Browser-Deployment` (arch amd64, language neutral) | - | - | x | x |
| Telemetry components (Z-Atlas-NoTelemetry: Feedback engine/service/notifications, Application-Experience AIT/AppInv/Inventory/Program-Data, Compat-Appraiser, CompatTelRunner, DeviceCensus schedule, KeyboardDiagnostic, TelemetryClient, Unified-Telemetry-Client aggregators/autologger/decoder, PlatformTelemetryClient, SIUF settings handlers, SetupPlatform telemetry autologger, ...; 57 entries) | x (always, via sxsc CBS package) | via revitool `system-components-removal` (contents unknown) | (file deletes instead, §6) | (file deletes) |
| Defender (Z-Atlas-NoDefender: `Security-Malware-Windows-Defender`, `Windows-Defender-*` (AM engine, sigs, service, drivers, UI, group policy, MDM), `Windows-SenseClient-*`, `Microsoft-OneCore-WebThreatDefense-*`, SmartScreen `Microsoft-Windows-AppRep*`, `Microsoft-Windows-SmartScreen`; 83 entries) | opt:`defender-disable` (radio, default **enable**) | revitool `tweaks security defender disable --force` under opt:`disable-defender` (radio, default **disable**) | hard delete (§3) | hard delete |
| AI (Recall, Copilot) | - | revitool `winpackage --install ai-removal`, opt:`remove-winsxs-ai` (on) | appx + tasks + policies (§3) | - |
| OneDrive setup in WinSxS | - (Atlas-Misc package lives in `sxsc-disabled/` and only replaces Settings banner files) | revitool `winpackage --install onedrive-removal`, opt:`remove-onedrive` (on) | file delete of `OneDriveSetup.exe` | same |
| Generic "system components" | - | revitool `winpackage --install system-components-removal` (always) | - | - |
| Commented-out by A for breakage | `Microsoft-Windows-CoreSystem-Bluetooth-Telemetry` ("Breaks Bluetooth connectivity"), `Microsoft-Windows-DeviceCensus` ("Required for ... PcaSvc"), `Application-Experience-Infrastructure`, `Unified-Telemetry-Client` core | | | |

Sources: A `Configuration/atlas/components.yml`, `atlas/src/sxsc/Atlas-NoTelemetry.yaml`,
`atlas/src/sxsc/Atlas-Defender-Remover.yaml`, `Executables/AtlasModules/Scripts/ScriptWrappers/ToggleDefender.ps1`;
R `Configuration/Tasks/packages/win-sxs.yml`; P+ `Configuration/tasks/components.yml`.

### 2.2 DISM optional features and capabilities

| Feature / capability | Action | A | R | P+ | 10 |
|---|---|---|---|---|---|
| `DirectPlay` | **enable** | x (`DISM /Enable-Feature /All`) | x | - | - |
| `LegacyComponents` | enable | - | x | - | - |
| `MicrosoftWindowsPowerShellV2`, `MicrosoftWindowsPowerShellV2Root` | disable | - | x | - | - |
| `MSRDC-Infrastructure` | disable | - | x | - | - |
| `Printing-Foundation-Features`, `Printing-Foundation-InternetPrinting-Client` | disable | - | x (LPR/LPD/IPP client; local printing still works) | - | - |
| `WorkFolders-Client` | disable | - | x | - | - |
| `SmbDirect` | disable | - | commented out | - | - |
| Capability `App.StepsRecorder~~~~0.0.1.0` | remove | x (`/Remove-Capability`, `onUpgrade: false`) | - | - | - |
| `/Cleanup-Image /StartComponentCleanup` | cleanup | x | - | - | - |

R implementation: `Executables/DISM-FEATURES.ps1` checks
`HKLM\...\Component Based Servicing\Notifications\OptionalFeatures\<name>\Selection`
first so it only changes what differs (idempotent). A: `Configuration/atlas/start.yml`.
P+/10 use no DISM at all. All DISM steps are dynamic and cannot run during ISO injection.

---

## 3. Big-ticket items

| Item | A | R | P+ | 10 |
|---|---|---|---|---|
| **Edge (Chromium)** | opt:`uninstall-edge` (on). `RemoveEdge.ps1 -UninstallEdge -RemoveEdgeData -KeepAppX` which **downloads `Remove-Edge.exe` from ShadowWhisperer GitHub `releases/latest` at run time** and runs it; then `!appx` Edge + Deprovisioned keys. Revert: same script `-InstallEdge` (downloads MSI from edgeupdates API, hash-checked). | opt:`remove-edge` (on). `EDGE.ps1 -Mode EdgeBrowser`: deletes `NoRemove`, sets `EdgeUpdateDev\AllowUninstall=1`, creates fake `SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe`, runs Edge `setup.exe --force-uninstall --delete-profile` through a copied `cmd.exe` renamed `ImmersiveControlPanel\sihost.exe` (parent-process spoof). Then APPX-REMOVER. Policies: `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate` `Install{56EB18F8-...}=0`, `DoNotUpdateToEdgeWithChromium=1`. Revert: reinstall Edge installer (no script). | Unconditional. `EDGE.bat` (shortcuts, uninstall keys, `\MicrosoftEdge*` tasks), `!service delete` edgeupdate/edgeupdatem/MicrosoftEdgeElevationService, `!file` `%ProgramFiles(x86)%\Microsoft\{Edge,EdgeUpdate,EdgeCore,EdgeWebView}` and both `Internet Explorer` folders, ~70 registry deletes, `!systemPackage` Internet-Browser-Deployment. No revert. | same as P+ |
| **WebView2** | kept (Remove-Edge.exe is used without WebView flags; A's script can `-InstallWebView`) | **kept on purpose**: `EDGE.ps1` has a `WebView` mode but the playbook never calls it; `edgeupdate` set to Manual (3) because "Disabling it breaks WebView installation via Visual Studio"; policy `Install{F3017226-...}=1` | **removed** (EdgeWebView folder, per-user EdgeWebView data) | removed |
| **OneDrive** | Always. `ONED.cmd`: **aborts (exit 6000) if any user's OneDrive folder has files**, else `OneDriveSetup.exe /uninstall`, removes folders, SyncRootManager, per-user Run/BannerStore/namespace keys, OneDrive tasks. Revert: rerun `%windir%\System32\OneDriveSetup.exe` (left in place) or download OneDrive. | opt:`remove-onedrive` (on). `ONED.cmd` uninstalls per user and from System32/SysWOW64, removes folders; revitool `onedrive-removal` strips WinSxS; APPX-REMOVER OneDrive. `oobe: false, iso: false` on the script. Revert: manual download. | Always. `ONED.bat` **moves files out of `OneDrive\{Desktop,Documents,Pictures,Videos,Music}`** first, then deletes; `!file` `OneDriveSetup.exe` (System32 + SysWOW64), `OneDriveSettingSyncProvider.dll`; ~200 registry keys; policy `DisableFileSyncNGSC=1`. No revert. | same |
| **Microsoft Store** | Kept. Auto app updates off: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload=2`. Optional removal script in Atlas folder, with an Enable script. | Kept. Policy `HKLM\Software\Policies\Microsoft\WindowsStore` `AutoDownload=4` (auto-update stays on), `DisableOSUpgrade=1`; Store results removed from Search on 25H2 (`WinStore.Tasks.WindowsSearchTask` ActivationType 0xFFFFFFFF). | **Removed**: appx `WindowsStore`, `StorePurchaseApp`; service `InstallService` deleted; `ClipSVC` tokens.dat, `ClipUp.exe`, `\Microsoft\Windows\Clip\License Validation` task deleted. Breaks Store licensing for good. | same |
| **Windows Update** | Kept. Radio `auto-updates-disable` (default) → `WindowsUpdate\AU\AUOptions=2` (notify only; `NoAutoUpdate` deliberately not set because it "Breaks 'Receive updates for other Microsoft products'"). Always (`disable-feature-updates.yml`): `TargetReleaseVersion=1` (DWORD), `ProductVersion` = Windows 10/11, then a second command **overwrites `TargetReleaseVersion` with the DisplayVersion string** (probably meant `TargetReleaseVersionInfo`; intent is to pin the feature release, actual effect unverified), insider blocked, DO `DODownloadMode=0`, no auto-reboot with users, MSRT reporting off. Revert: `AtlasDesktop/3. General Configuration/Automatic Updates/Enable...cmd`, `Windows Updates/Toggle Windows Updates.cmd`. | Kept, paused: revitool `wu-pause-updates enable` (pause to 2038 via `FlightSettingsMaxPauseDays`), revitool `wu-drivers disable`; tasks `WindowsUpdate\Scheduled Start`, `UpdateOrchestrator\{Schedule Scan, StartOobeAppsScanAfterUpdate, Start Oobe Expedite Work}` disabled; `UpgradeNotification\UpgradeAvailable=0`; `RestartNotificationsAllowed2=0`; DO off; Update Health Tools / PC Health Check / Installation Assistant uninstalled (`FINALIZE.cmd`). `revert.yml` deletes the whole `Policies\...\WindowsUpdate` key on upgrade. Revert: Revision Tool. | **Destroyed**: services `wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `DoSvc` deleted; `wuaueng.dll`, `wuapi.dll`, `wuauclt.exe`, `UsoClient.exe`, `MoUsoCoreWorker.exe`, `WaaSMedic*`, `SIHClient.exe`, `wusa.exe`, `SoftwareDistribution`, WU troubleshooter, WU PowerShell module, MUS notification binaries deleted; Update Health Tools removed. No revert (reinstall Windows). | same |
| **Defender / Windows Security** | Radio `defender-enable` (default) / `defender-disable`. Disable installs `Z-Atlas-NoDefender-Package` (CBS); ISO only also deletes `OfflineSys\...\Services\WdBoot`. Always: Security Health tray removed from Run, unused Security pages hidden by policy (`UILockdown` for Family, Device performance, Account protection). Requirement `DefenderToggled`. Revert: `AtlasDesktop/7. Security/Defender/Toggle Defender.cmd` uninstalls the package. | Radio `disable-defender` (**default**) / `enable-defender`, via revitool `tweaks security defender disable --force` / `enable`. Always: Defender reporting off, signature updates on battery off. Requirement `DefenderToggled`. Revert: Revision Tool `enable`. | **Hard removal**: kills MsMpEng/NisSrv/SecurityHealth*; deletes `Program Files\Windows Defender` (+x86, ProgramData, ATP folders), `Program Files\Windows Security`, `SecurityHealth*.exe/.dll`, `WdNisDrv.sys`, `wscsvc.dll`, webthreatdefsvc files, `MRT.exe`; services Sense, SecurityHealthService, wscsvc, webthreatdefsvc, webthreatdefusersvc* deleted; WdNisDrv/WdNisSvc keys deleted; Defender tasks deleted; appx SecHealthUI removed. Requirement `DefenderDisabled`. No revert. | same |
| **SmartScreen / SAC** | Always: **Smart App Control off** (`HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy\VerifiedAndReputablePolicyState=0`; SAC cannot be turned back on without a reinstall/reset). SmartScreen itself removed only with `defender-disable` (AppRep/SmartScreen components in the CBS package). | Always: `Policies\...\Windows Defender\SmartScreen` `ConfigureAppInstallControlEnabled=1`, `ConfigureAppInstallControl=Anywhere`; `HKCU\...\AppHost\EnableWebContentEvaluation=0`; Edge `PhishingFilter\EnabledV9=0`; ChxApp deprovisioned. | Always: `smartscreen.exe`, `smartscreenps.dll` deleted; `Explorer\SmartScreenEnabled=Off`; appx `Apprep.ChxApp` removed. | same |
| **Copilot** | Always: appx `Microsoft.Copilot*`; `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot\TurnOffWindowsCopilot=1` (comment: "Doesn't work with HKLM"); `builds >=22000`. Revert: `AI Features/Microsoft Copilot/Enable Microsoft Copilot.cmd`. | opt:`remove-winsxs-ai` (on): revitool `ai-removal` + APPX-REMOVER `Microsoft.Copilot`. Always: IFEO `BingChatInstaller.exe` Debugger = `taskkill.exe`; Gaming Copilot blocked (`Microsoft.Xbox.GamingAI.Companion.Host.GamingCompanionHostOptions` ActivationType 0xFFFFFFFF). | Always: 6 AI appx patterns, kill `ai.exe`, `Copilot.exe`, `aihost.exe`, `aicontext.exe`, `ClickToDo.exe`, `aixhost.exe`, `WorkloadsSessionHost.exe`; HKLM+HKCU `TurnOffWindowsCopilot=1`, `Shell\Copilot\IsCopilotAvailable=0`, `ShowCopilotButton=0`, Edge Copilot policies (`HubsSidebarEnabled=0`, `CopilotPageContext=0`, ...), Paint AI policies (`DisableImageCreator`, `DisableCocreator`, `DisableGenerativeFill`, ...), `ms-copilot`/`ms-office-ai`/`ms-clicktodo` protocols deleted, generativeAI consent Deny. | n/a (Win10; only `TurnOffWindowsCopilot` absent) |
| **Recall** | Always: `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI\DisableAIDataAnalysis=1` via `AI Features/Recall/Disable Recall Support (default).cmd`. Revert: Enable script. | Always: same `DisableAIDataAnalysis=1`; opt:`remove-winsxs-ai` revitool removal. | Always: `WindowsAI` policies `DisableAIDataAnalysis=1`, `AllowRecallEnablement=0`, `TurnOffSavingSnapshots=1`, `DisableClickToDo=1`, `DisableSettingsAgent=1` (HKLM+HKCU); tasks folder `\Microsoft\Windows\WindowsAI\{Recall,Settings}` deleted; service `WSAIFabricSvc` deleted. | n/a |
| **Widgets** | Always: policy `Windows Feeds\EnableFeeds=0`, `Dsh\AllowNewsAndInterests=0`. Revert: `Widgets (News and Interests)/Enable Widgets.cmd`. | Always: appx `Client.WebExperience` + `WidgetsPlatformRuntime` removed and deprovisioned; same policies; `TaskbarDa=0`, `ShellFeedsTaskbarViewMode=2`. | Always: appx `Client.WebExperience`, `WebExperienceHost`; same two policies. | same |
| **Teams / Chat** | Always: appx `MicrosoftTeams*`, `MSTeams*`; `ConfigureChatAutoInstall=0`; `Windows Chat\ChatIcon=3`, `TaskbarMn=0`. | opt:`remove-teams` (on): appx MicrosoftTeams/MSTeams/Flipgrid, msiexec `/X{A7AB73A3-CB10-4AA5-9D38-6AEFFBDE4C91}` (Teams Meeting Add-in); always `ConfigureChatAutoInstall=0`, `ChatIcon=3`, `TaskbarMn=0`. | Always: appx MicrosoftTeams/MSTeams; `ChatIcon=3`. | same |
| **Xbox** | Keep. Only deprecated XboxApp removed. Game Bar/DVR disabled by registry (`AllowGameDVR=0`, `GameDVR_Enabled=0`, `AppCaptureEnabled=0`, PresenceWriter ActivationType 0); Atlas folder has "FSO and Game Bar" enable script. Svchost split threshold excludes `Xbl|Xbox` services. | opt:`remove-appx-xbox` (**off**). With it: Xbox apps removed, `ms-gamebar` protocol pointed at `systray.exe` (stops "get an app" popups, issue #139). Always: `GameDVR_Enabled=0`; `revert.yml` undoes `AppCaptureEnabled` that greyed out recording (#74) and svchost tweak that broke `XboxGipSvc` (#34). | Always: all Xbox appx (except XboxIdentityProvider by typo); `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc` stopped; `gamepanel.exe` deleted. | same |
| **Cortana / Search** | Appx Cortana removed; search policies `DisableWebSearch=1`, `ConnectedSearchUseWeb=0`, `AllowSearchToUseLocation=0`, `EnableDynamicContentInWSB=0`, `DisableSearchBoxSuggestions=1`, `BingSearchEnabled=0`; search icon-only. Indexing set to "minimal" via Atlas folder script. | Appx Cortana removed; `AllowCortanaAboveLock=0`, `AllowCortanaInAAD=0`, `CortanaConsent=0`; **`AllowCortana` is set to 1** despite the comment "Disabled"; WebView2 spawn from SearchHost blocked (`FeatureManagement\Overrides\1694661260=0`); Settings pages `cortana,privacy-feedback,windowsinsider,home` hidden via revitool. | Appx Cortana removed; `AllowCortana=0`, `AllowCloudSearch=0`, web search off; **outbound firewall block rules** for `SearchApp.exe`, `SearchHost.exe`, `StartMenuExperienceHost.exe`, `SystemSettings.exe`, `explorer.exe`. | same |

Sources: A `Configuration/atlas/components.yml`, `Configuration/tweaks/qol/taskbar/*.yml`,
`Configuration/tweaks/qol/windows-update/*.yml`, `Configuration/tweaks/privacy/search-settings.yml`,
`Configuration/tweaks/performance/disable-game-bar.yml`, `Executables/AtlasDesktop/**`,
`Executables/AtlasModules/Scripts/ScriptWrappers/RemoveEdge.ps1`, `Executables/ONED.cmd`;
R `Configuration/Tasks/packages/*.yml`, `Configuration/Tasks/registry/{updates,security,explorer,privacy,misc,system}/*.yml`,
`Configuration/Tasks/revert.yml`, `Executables/{EDGE.ps1,ONED.cmd,FINALIZE.cmd}`;
P+ `Configuration/tasks/{components,services,files,regedits}.yml`, `Executables/{EDGE,ONED,SERVICE,SFCDEPLOY}.bat`.

---

## 4. Services

Startup values: 2 Automatic, 3 Manual, 4 Disabled, 1 System. `stop` = `!service operation: stop`
(not persistent; P+/10 use it before deleting files). `del` = `!service operation: delete`.

| Service | What it is | A | R | P+ | 10 |
|---|---|---|---|---|---|
| **DiagTrack** | Connected User Experiences and Telemetry | 4 | 4 | del | del |
| **diagnosticshub.standardcollector.service** | Diagnostics Hub collector | 4 | 4 | stop | stop |
| **OneSyncSvc** | Sync host (Mail/People/Calendar) | 4 | - | del (`OneSyncSvc*`) | del |
| **TrkWks** | Distributed Link Tracking Client | 4 | - | stop | stop |
| **lfsvc** | Geolocation | 4 (Location script) | - | stop; ImagePath moved to firewalled `amehost.exe` | stop |
| **MapsBroker** | Downloaded Maps Manager | 4 (Location script) | - | stop | stop |
| **wisvc** | Windows Insider Service | - | 4 | del | del |
| WerSvc | Windows Error Reporting | 4 | 4 | - | - |
| PcaSvc | Program Compatibility Assistant | 4 | 4 | - | - |
| UCPD | User Choice Protection Driver | 4 | 4 | - (requirement `UCPDDisabled`) | - |
| GpuEnergyDrv | GPU energy driver | 4 | 4 | - | - |
| NetBT | NetBIOS over TCP/IP | 4 (Atlas folder's Enable File Sharing script turns it back on) | 4 | - | - |
| Telemetry | Intel(R) telemetry service | 4 | 4 | - | - |
| wercplsupport | Problem Reports control panel | 4 | - | - | - |
| WpnService / WpnUserService_* | Push notifications | 4 during deploy, restored at end (`DISABLENOTIFS.cmd` / `ENABLENOTIFS.cmd`) | - | stop | stop |
| dam | Desktop Activity Moderator driver | - | 4 | - | - |
| WdiServiceHost, WdiSystemHost | Diagnostic Service/System Host | - | 4 | - | - |
| tcpipreg | TCP/IP registry compat ("experimental") | - | 4 | - | - |
| Wecsvc | Windows Event Collector | - | 4 | - | - |
| edgeupdate | Edge Update | - (removed by Remove-Edge.exe if Edge removed) | **3** (kept for WebView2) | del | del |
| edgeupdatem, MicrosoftEdgeElevationService | Edge | - | - | del | del |
| condrv | Console driver | - | 2 (fix for error 0xd000003a, #184) | - | - |
| bam 1, Beep 1, GraphicsPerfSvc 3, Ndu 2, DPS 2 | | - | restored to defaults in `revert.yml` (`onUpgrade: true`) after earlier versions broke Efficiency Mode etc. | - | - |
| wuauserv, UsoSvc, WaaSMedicSvc, DoSvc | Windows Update stack, Delivery Optimization | - | - | del | del |
| InstallService | Store install service | - | - | del | del |
| Sense, SecurityHealthService, wscsvc, webthreatdefsvc, webthreatdefusersvc* | Defender ATP, Security Center, Web Threat Defense | - | - (revitool) | del | del |
| WSAIFabricSvc | Windows AI fabric (24H2+) | - | - | del | - |
| WpcMonSvc | Parental controls | - | - | del | del |
| WMPNetworkSvc | WMP network sharing | - | - | del | del |
| StorSvc | Storage Service | - | - | del (+ `StorSvc.dll`) | del |
| UevAgentService | User Experience Virtualization | - | - | del | del |
| cloudidsvc | Microsoft Cloud Identity | - | - | del | del |
| applockerfltr | AppLocker filter driver | - | - | stop + del (+ AppLocker files) | - |
| BITS | Background transfer | - | - | stop, then 3 | stop, then 3 |
| CryptSvc | Cryptographic Services | - | - | stop; ImagePath moved to `amehost.exe` (copy of svchost) with an outbound firewall block | same |
| appidsvc | AppLocker identity | - | - | stop | stop |
| iphlpsvc, Winmgmt, ClipSVC, RetailDemo, dmwappushservice, LicenseManager, NetTcpPortSharing, RemoteAccess, RemoteRegistry, SharedAccess, WbioSrvc, XblAuthManager, XblGameSave, XboxNetApiSvc | | - | - | stop only | stop only |
| WdNisDrv, WdNisSvc | Defender network inspection | - | - | registry key deleted | same |
| WdBoot | Defender ELAM driver | ISO only, opt:`defender-disable`, key deleted in offline hive | - | - | - |

Sources: A `Configuration/atlas/services.yml`, `Executables/AtlasDesktop/3. General Configuration/Location/Disable Location (default).cmd`,
`Executables/AtlasModules/Scripts/ScriptWrappers/DisableFileSharing.ps1`, `Executables/DISABLENOTIFS.cmd`;
R `Configuration/Tasks/services.yml`, `Configuration/Tasks/revert.yml`;
P+/10 `Configuration/tasks/services.yml`, `Configuration/tasks/components.yml`, `Configuration/tasks/files.yml`, `Executables/SERVICE.bat`.

Reversibility: A backs up every service/driver start value first
(`BACKUP.ps1 -FilePath %windir%\AtlasModules\Other\winServices.reg`) and ships
`AtlasDesktop/9. Troubleshooting/Set services to defaults.cmd`. R relies on Revision Tool
and its `revert.yml`. P+/10 cannot be reverted (deleted services and binaries).

---

## 5. Scheduled tasks

`dis` = disabled, `del` = deleted. All paths under `\Microsoft\Windows\` unless shown.

| Task | A | R | P+ | 10 |
|---|---|---|---|---|
| **Customer Experience Improvement Program\Consolidator** | dis | dis | del | del |
| **Customer Experience Improvement Program\UsbCeip** | dis | dis | del | del |
| **Customer Experience Improvement Program\KernelCeipTask** | - | dis | del | del |
| **Application Experience\Microsoft Compatibility Appraiser** | - (component removed by NoTelemetry pkg) | dis | del | del |
| **WindowsUpdate\Scheduled Start** | - | dis | del | del |
| **UpdateOrchestrator\Schedule Scan** | - | dis | del | del |
| Application Experience\ProgramDataUpdater | - | - | del | del |
| Application Experience\StartupAppTask | - | - | del | del |
| Application Experience\AitAgent | - | dis (legacy) | - | - |
| Application Experience\PcaPatchDbTask | dis | - | - | - |
| AppxDeploymentClient\UCPD velocity | dis | dis | - | - |
| DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector | dis | dis | - | - |
| Power Efficiency Diagnostics\AnalyzeSystem | dis | dis | - | - |
| Flighting\FeatureConfig\UsageDataReporting | dis (+ remove `Ubpm\CriticalMaintenance_UsageDataReporting`) | - | - | - |
| MemoryDiagnostic\ProcessMemoryDiagnosticEvents, RunFullMemoryDiagnostic | - | dis | - | - |
| Windows Error Reporting\QueueReporting | - | dis | - | - |
| UpdateOrchestrator\StartOobeAppsScanAfterUpdate, Start Oobe Expedite Work | - | dis | - | - |
| UpdateOrchestrator\Schedule Scan Static Task, UpdateModelTask, USO_UxBroker | - | - | del | del |
| WaaSMedic\PerformRemediation | - | - | task file deleted | same |
| Feedback\Siuf\DmClient, DmClientOnScenarioDownload | - | - | task files deleted | same |
| Clip\License Validation | - | - | del | del |
| HelloFace\FODCleanupTask | - | - | del | del |
| Maps\MapsToastTask, MapsUpdateTask | - | - | del | del |
| Windows Defender\{Cache Maintenance, Cleanup, Scheduled Scan, Verification} | - | - | del | del |
| WindowsAI\Recall, WindowsAI\Settings, WindowsAI (folders) | - | - | del (`deleteFolder`) | - |
| `\Microsoft\Office\*` | - | dis (PowerShell) | - | - |
| OneDrive Reporting Task / OneDrive Standalone Update Task (per user) | del (`ONED.cmd`) | - | del (`ONED.bat`) | del |
| `\MicrosoftEdge*` (EdgeUpdate tasks) | (Remove-Edge.exe) | - | del (`EDGE.bat`) | del |
| DiskCleanup\SilentCleanup | **enabled** (storage sense config) | started once (`CLEANER.ps1`) | - | - |

Sources: A `Configuration/tweaks/debloat/disable-scheduled-tasks.yml`, `Configuration/tweaks/performance/disable-sleep-study.yml`;
R `Executables/FINALIZE.cmd` (`schtasks /change /disable`), `Configuration/Tasks/services.yml`, `Configuration/Tasks/final.yml`;
P+/10 `Configuration/tasks/{components,files}.yml`.

Note: R disables tasks inside `FINALIZE.cmd` with `schtasks`, not `!scheduledTask`. A and R
use `disable` (reversible); P+/10 use `delete`.

---

## 6. File deletions (P+ / AME 10)

P+ has 322 `!file` actions (AME 10: 321; P+ adds `System32\flightsettings.dll`).
Grouped from `privacyplus/Configuration/tasks/{components,files,config}.yml`:

| Category | Count (approx.) | Examples |
|---|---|---|
| Windows Update / USO / WaaSMedic | ~120 | `System32\wuaueng.dll`, `wuapi.dll`, `wuauclt.exe`, `wuapihost.exe`, `UsoClient.exe`, `usocoreworker.exe`, `MoUsoCoreWorker.exe`, `usosvc.dll`, `WaaSMedic*.dll/.exe`, `SIHClient.exe`, `WindowsUpdateElevatedInstaller.exe`, `storewuauth.dll`, `wusa.exe`, `wups*.dll`, `MusNotification*`, `%windir%\SoftwareDistribution`, `%windir%\UUS`, `%windir%\WaaS\*`, `diagnostics\system\WindowsUpdate\*`, WindowsUpdate ADMX, USOShared ETL logs (many duplicated under `Users\All Users` and `Documents and Settings` junctions) |
| Telemetry / DiagTrack / CEIP | ~35 | `diagtrack.dll`, `%windir%\DiagTrack\*`, `DeviceCensus.exe`, `dmclient.exe`, `omadmclient.exe`, `invagent.dll`, `wsqmcons.exe`, Diagtrack-Listener ETLs |
| Delivery Optimization | ~35 | `dosvc.dll`, DO PowerShell module, DO ADMX, NetworkService DO state/logs |
| Defender / Security Center / SmartScreen | ~25 | `Program Files\Windows Defender` (+x86, ProgramData), ATP folders, `Program Files\Windows Security`, `SecurityHealth*`, `smartscreen.exe`, `WdNisDrv.sys`, `wscsvc.dll`, `webthreatdefsvc.dll`, `webthreatdefusersvc.dll`, `MRT.exe` |
| Edge / IE | ~13 | `%ProgramFiles(x86)%\Microsoft` (**whole folder**), `Microsoft\{Edge,EdgeUpdate,EdgeCore,EdgeWebView}`, `Internet Explorer` (x86/x64), Edge `.lnk` shortcuts |
| OneDrive | 5 | `OneDriveSetup.exe` (System32, SysWOW64), `OneDriveSettingSyncProvider.dll`, `OneDriveTemp`, `ProgramData\Microsoft OneDrive` |
| Licensing / Store | ~8 | `ClipSVC\tokens.dat`, `ClipUp.exe`, `slui.exe`, `InstallService.dll` |
| AppLocker | ~10 | `AppLockerCSP.dll`, `applockerfltr.sys`, AppLocker PS module |
| Remote assistance | ~7 | `msra.exe`, `msrahc.dll`, `MsraLegacy.tlb` |
| Misc services / features | ~25 | `WpcDesktopMonSvc.dll`, `AgentService.exe` (UE-V), `cloudidsvc.dll`, `StorSvc.dll`, `HotspotAuthentication.dll`, `gamepanel.exe`, `IESettingSync.exe`, `HelpPane.exe`, `Windows Media Player`, `Windows Mail` folders, `SystemSettingsExtensions.dll` (Client.Core and Client.CBS, removes Settings banners), Autologger PS cmdlets, EnhancedStorage ADMX |
| Update Health / PC Health Check | 3 | `Program Files\Microsoft Update Health Tools`, `PCHealthCheck`, its `.lnk` |
| Leftover Maps package | ~8 | `WindowsApps\DeletedAllUserPackages\Microsoft.WindowsMaps_*`, AppRepository XML |

Supporting steps that make the deletes stick: services stopped first (BITS, appidsvc,
cryptsvc), `SFCDEPLOY.bat` swaps in a custom `sfc.exe` (original renamed `sfc1.exe`),
`config.yml` runs `manage-bde -off C:` (BitLocker decryption).

---

## 7. Consensus (3 or more playbooks)

- APPX: Cortana, Bing News/Weather/Search, Clipchamp, Get Help, Tips, 3D Viewer, Office Hub,
  Solitaire, Sticky Notes, OneNote, People, Power Automate, Skype, To Do, Alarms, Camera,
  Feedback Hub, Maps, Sound Recorder, Mail and Calendar, Films & TV, Mixed Reality Portal,
  new Outlook, Spotify, Family, Dev Home, Teams, Phone Link, Copilot (Win11 playbooks),
  Edge AppX, Widgets (`Client.WebExperience`: R, P+, 10), Media Player and Quick Assist
  (R, P+, 10), Photos (R opt-default-on, P+, 10), Xbox Console Companion.
- Clear Client.CBS / Search AppX caches after removal.
- Services: DiagTrack, diagnosticshub collector disabled; OneSyncSvc, TrkWks, lfsvc,
  MapsBroker touched by A, P+, 10; wisvc by R, P+, 10.
- Tasks: CEIP Consolidator, UsbCeip, KernelCeipTask; Compatibility Appraiser; WU Scheduled Start
  and Schedule Scan.
- Policies: Widgets off (`EnableFeeds=0`, `AllowNewsAndInterests=0`), Chat icon off
  (`ChatIcon=3`), Recall off (`DisableAIDataAnalysis=1`), web search off, Delivery
  Optimization off (A, R, P+), Teams auto-install off (A, R).
- Edge: removed by default in all four (A and R behind a default-on checkbox).
- OneDrive: removed by default in all four (only R makes it optional).
- Defender: disabled by default in R, P+, 10; A defaults to enabled.

## 8. Risks and build-specific gates

| Change | Breaks | Who |
|---|---|---|
| Deleting WU services/binaries | All updates, cumulative security patches, Store app updates, `wusa`, feature upgrades; only fix is reinstall | P+, 10 |
| Store + InstallService + ClipSVC tokens + License Validation task | Store, app licensing, Game Pass, Store-delivered codecs and app updates | P+, 10 |
| Xbox appx/services (TCUI, IdentityProvider, GamingApp, XblAuthManager) | Game Pass, Xbox sign-in in games, Game Bar, Forza/Halo-type titles | P+, 10; R only if opted in |
| `CloudExperienceHost`, `OOBENetwork`, `AssignedAccessLockApp` appx | MS account sign-in, Windows Hello enrollment, OOBE pages, kiosk mode | P+, 10 (hence requirement `LocalAccounts`) |
| WebView2 deleted | New Outlook, Teams, Widgets, many third-party apps and installers using WebView2 | P+, 10 (R and A keep it) |
| `%ProgramFiles(x86)%\Microsoft` deleted | Anything else Microsoft installed there | P+, 10 |
| CryptSvc moved behind a firewall block | Root certificate / CRL updates, some code-signing checks | P+, 10 |
| Hard Defender delete + SFC replacement | Security; SFC/DISM repair no longer meaningful | P+, 10 |
| `manage-bde -off C:` | Removes BitLocker protection | P+, 10 |
| Smart App Control off | One-way: SAC cannot be re-enabled without reset | A |
| `Printing-Foundation-*` disabled | LPR/LPD and Internet Printing (IPP) clients; local/WSD printing kept | R |
| `TargetReleaseVersion` pinned to current release | No feature updates until the policy is removed | A |
| NetBT disabled, file-sharing bindings off | SMB name resolution via NetBIOS, network discovery; A ships an Enable File Sharing script | A, R |
| UCPD disabled | Lets scripts set default browser/file associations; removes Microsoft's protection against default-app hijacking | A, R (P+ requirement) |
| `Microsoft-Windows-CoreSystem-Bluetooth-Telemetry` removal | Bluetooth connectivity (A commented it out for this reason) | none (avoid) |
| `bam` disabled (older R) | Task Manager Efficiency Mode (R reverted it) | none now |
| `Beep`/`GraphicsPerfSvc`/`Ndu` disabled (older R) | reverted by R | none now |
| Svchost split threshold changed | XboxGipSvc / controllers (R #34); A excludes Xbl/Xbox services | A (with exclusion) |
| Remote downloads at apply time (Remove-Edge.exe `latest`, Revision Tool `latest`) | Reproducibility; unpinned third-party binaries run elevated | A, R |
| Phone Link removal through `!appx` | Cross Device Experience Host reinstall (A uses PowerShell instead) | A note |

Build-specific gates seen:
- A: whole playbook limited to 26100/26200; Copilot, Chat, Recall tweaks gated `builds: ['>=22000']`;
  `cpuArch` gates for ARM64 (FTH, Open-Shell); ARM64 has separate sxsc YAMLs; `WdBoot` delete is `iso: only`.
- R: no `builds:` gates in debloat; pattern-based removal is a no-op when a package is absent
  (lets one list span 19044 to 26200); `cpuArch` gates only for browsers; `ONED.cmd` is `oobe: false, iso: false`;
  25H2-only Store search tweak is applied unconditionally (harmless on older builds).
- P+: `!systemPackage` restricted to `arch: amd64` (ARM untouched); AI section only meaningful on 24H2+
  but not gated; Open-Shell gated `<22621.2428`.
- 10: Win10 only (19044/19045); no AI section.

---

## Summary

All four remove the same core of consumer apps (about 30 families, from Cortana and Bing
apps to Teams, Outlook and Phone Link) and disable DiagTrack, the CEIP tasks and the
Compatibility Appraiser. They split on the big items. AtlasOS keeps Defender on by default,
keeps Store, Xbox and Windows Update, and removes Defender and telemetry as reversible CBS
packages, with toggle scripts in the Atlas folder. ReviOS removes Edge, OneDrive, Teams, AI and
Photos behind checkboxes that start checked, keeps Xbox unless the user opts in, keeps WebView2
and the Store, pauses Windows Update until 2038 and turns Defender off by default. Most of this
runs through a downloaded closed-box tool (Revision Tool), so its package contents are not
visible here. Privacy+ and AME 10 hard-delete Windows Update, Store, Defender, SmartScreen,
Edge and WebView2, and about 320 files with no way back. For our playbook, the consensus
app list, the policy-based Widgets/Chat/Recall/Copilot switches and Atlas-style reversible
service changes are good candidates. Destructive removals belong behind options that start
unchecked.
