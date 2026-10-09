# Performance and quality-of-life inventory (Phase 3 research)

Collected 2026-10-09 by reading the playbook sources only. No reference
script or binary was run. Everything below describes what the reference
playbooks do. None of it is an approved change for this repo; Phase 4 picks
from this list.

## Sources and abbreviations

All paths are relative to the scratchpad `refs/` directory.

| Key | Playbook | Root | Target builds (`playbook.conf`) |
|-----|----------|------|----------------------------------|
| **A** | AtlasOS 0.5.0 | `atlas/src/playbook/` | 26100, 26200 only |
| **R** | ReviOS 26.04 (release `.apbx`, preferred over `revi/src`) | `revi-apbx/` | 19044, 19045, 22631, 26100, 26200 |
| **P** | AME Privacy+ 0.8.2 (Win11) | `privacyplus/` | 22000 … 26200 |
| **T** | AME 10 0.8 (Win10) | `ame10/` | 19044, 19045 |

Path shorthands: `A:tw/` = `atlas/src/playbook/Configuration/tweaks/`,
`A:AD/` = `atlas/src/playbook/Executables/AtlasDesktop/`,
`A:SW/` = `atlas/src/playbook/Executables/AtlasModules/Scripts/ScriptWrappers/`,
`R:reg/` = `revi-apbx/Configuration/Tasks/registry/`,
`R:T/` = `revi-apbx/Configuration/Tasks/`, `R:X/` = `revi-apbx/Executables/`,
`P:` = `privacyplus/`, `T:` = `ame10/`.

**Gate column:** `always` = runs unconditionally. `opt:x (on)` / `opt:x (off)` =
gated by feature-page option `x`, with its default state. Atlas checkbox
options omit `IsChecked`, so per `docs/reconnaissance.md` they default to
**checked**. `toolbox` = the change exists only as an opt-in toggle script in
the Atlas desktop folder and does not run during install.

**Consensus** = 3 or more of the 4 playbooks do the same thing (**C** in the
tables). Win10-only AME10 counts toward consensus, but note its relevance to
Win11.

**Flag column:** `SEC` = reduces security. `UNPROVEN` = no measured benefit
cited, or benefit disputed. `BREAKS` = a reference playbook itself documents
breakage. `OPAQUE` = done by a downloaded binary whose logic is not in the
playbook.

### Important caveat: ReviOS delegates to `revitool.exe`

ReviOS downloads `RevisionTool-Setup.exe` from GitHub *latest* at install time
(`R:T/start.yml`) and calls `revitool.exe tweaks …` for the power plan, VBS,
Intel TSX, NTFS, service grouping, hibernation, background apps, Superfetch
and Settings page hiding. The registry and command changes behind these calls
are not in the playbook, so the inventory can only record the intent
(`OPAQUE`). Running an unpinned binary from "latest" also conflicts with our
reproducibility rules. Do not copy this pattern.

---

## 1. Performance

| # | Area | Concrete change | A | R | P | T | Gate | C | Flag / notes | Source |
|---|------|-----------------|---|---|---|---|------|---|--------------|--------|
| P1 | Power plan | A: duplicate Ultimate Performance (`e9a42b02…`) as GUID `11111111-…`, rename "Atlas Power Scheme", NVMe idle 0, USB selective suspend off, USB3 LPM off, throttle states off, display off never, perf check 200 ms. Otherwise set Balanced. R: `revitool tweaks performance powerplan enable`. P/T: `powercfg /S` High Performance + `monitor-timeout-ac 0` | ✓ | ✓ | ✓ | ✓ | A: opt:`disable-power-saving` (on), else Balanced. R/P/T: always | **C** (plan change) | Battery/heat on laptops (Atlas warns when run interactively). R is `OPAQUE` | `A:tw/scripts/script-power.yml`, `A:SW/DisablePowerSaving.ps1`, `R:T/start.yml`, `P:Executables/REGI.bat`, `T:Executables/REGI.bat` |
| P2 | Power throttling | `HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling` `PowerThrottlingOff=1` | ✓ | | | | opt:`disable-power-saving` (on) | | Hurts battery life. `UNPROVEN` on desktops | `A:SW/DisablePowerSaving.ps1` |
| P3 | Device power saving | Rename + zero device `Enum` values (`EnhancedPowerManagementEnabled`, `SelectiveSuspendEnabled`, `D3ColdSupported`, `WakeEnabled`, …); `MSPower_DeviceEnable` off; `StorageD3InModernStandby=0`; `stornvme …\IdlePowerMode=0`; disable "ACPI Processor Aggregator" and "WMI for ACPI" devices | ✓ | | | | opt:`disable-power-saving` (on) | | Broad and hard to revert. Atlas keeps `*-OLD` copies. Breaks Modern Standby battery behaviour. `UNPROVEN` | `A:SW/DisablePowerSaving.ps1` |
| P4 | NIC power saving | Set NIC advanced properties to 0: EEE, GreenEthernet, ULPMode, uAPSD, `*SelectiveSuspend`, PowerSaveMode, … | ✓ | | | | opt:`disable-power-saving` (on) | | Low risk on desktops | same |
| P5 | CPU idle | `powercfg … sub_processor 5d76a2ca… 1` (disable idle states); refuses when SMT is on | toolbox | | | | not run at install | | High heat and power draw. `UNPROVEN`. Do not ship | `A:AD/3. General Configuration/CPU Idle/Disable Idle.cmd` |
| P6 | Timer resolution | `kernel\GlobalTimerResolutionRequests=1` + scheduled task "Force Timer Resolution". **Atlas default = removed** | toolbox | | | | not run | | `UNPROVEN`, costs power. Atlas ships "Disable (default)" | `A:AD/3. General Configuration/Timer Resolution/*.cmd` |
| P7 | Win32PrioritySeparation | `HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl` = `38` (0x26: short, variable, 3x foreground boost) | ✓ | ✓ | | | always | | Mild. Default Win11 client is 2. `UNPROVEN` but harmless | `A:tw/performance/system/win32-priority-separation.yml`, `R:reg/system/win32ps.yml` |
| P8 | MMCSS | `…\Multimedia\SystemProfile\SystemResponsiveness=10` (A). `NetworkThrottlingIndex=10` (R; this is the stock value, so effectively a reset) | ✓ | ✓ | | | always | | Low risk. Neither touches `Tasks\Games` | `A:tw/performance/config-mmcss.yml`, `R:reg/system/multimedia.yml` |
| P9 | bcdedit boot menu | `bootmenupolicy legacy` (F8 menu) | ✓ | ✓ | ✓ | ✓ | always | **C** | QoL rather than perf. A also sets `/timeout 10` | `A:tw/qol/bcdedit-tweaks.yml`, `R:X/FINALIZE.cmd`, `P:Executables/REGI.bat`, `T:Executables/REGI.bat` |
| P10 | bcdedit timers | R: `deletevalue useplatformclock`, `deletevalue disabledynamictick` (comment: forcing it "breaks ROG Ally sleep, #167"), `lastknowngood yes` | | ✓ | | | always | | Removes earlier tweaks, back to defaults. Good precedent | `R:X/FINALIZE.cmd` |
| P11 | bcdedit recovery | `/set {current} recoveryenabled no` | | | ✓ | ✓ | always | | `SEC`/resilience: disables automatic WinRE. Avoid | `P:Executables/REGI.bat` |
| P12 | CPU mitigations (Spectre/Meltdown etc.) | `FeatureSettingsOverride=3`/`Mask=3`, SEHOP off, system-wide `MitigationOptions` mask all `2` (disables CFG and others), DEP `nx OptIn`, `Session Manager\ProtectionMode=0`. Re-enables CFG for Valorant | ✓ | revert | | | A: opt:`mitigations-disable` (**off**; default = Windows defaults) | | **`SEC` — major.** Atlas itself says it may *hurt* perf on modern CPUs. R's `revert.yml` deletes `FeatureSettings*` and `ProcessMitigationOptions` policies (it walked this back) | `A:AD/7. Security/Mitigations/Disable All Mitigations.cmd`, `A:tw/scripts/script-mitigations.yml`, `R:T/revert.yml` |
| P13 | Per-app mitigations | R: IFEO `MitigationOptions` for `vgc.exe` (CFG on) and `osu!.exe` (ASLR) | | ✓ | | | always | | Compatibility fixes, needed only if mitigations are altered | `R:reg/misc/fixes.yml` |
| P14 | Intel TSX | `revitool tweaks performance intel-tsx enable` | | ✓ | | | always | | **`SEC`** (TSX is off by default because of TAA/ZombieLoad v2). `OPAQUE` | `R:reg/system/kernel.yml` |
| P15 | VBS / HVCI / Core Isolation | A: HVCI `Enabled=0`, KernelShadowStacks 0, CredentialGuard 0, `Lsa\RunAsPPL=0`, `DeviceGuard\EnableVirtualizationBasedSecurity=0` (comments: "forced since 24H2", "24H2 only"). R: `revitool tweaks security vbs disable` | ✓ | ✓ | | | A: opt:`disable-core-isolation` (**on**, IsChecked omitted). R: **always** | | **`SEC` — major.** Also disables LSA protection and Credential Guard. R gives no opt-out. Gaming gain is documented by Microsoft only for some workloads | `A:SW/ConfigVBS.ps1`, `A:tw/scripts/script-core-isolation.yml`, `R:reg/security/vbs.yml` |
| P16 | Vulnerable driver blocklist | `CI\Config\VulnerableDriverBlocklistEnable=1` (re-enable) | | ✓ | ✓ | ✓ | always | **C** | Security *positive*. R notes "0 breaks THE FINALS" | `R:T/revert.yml`, `P:Configuration/tasks/regedits.yml` |
| P17 | Fault Tolerant Heap | `rundll32 fthsvc.dll,FthSysprepSpecialize`; `HKLM\SOFTWARE\Microsoft\FTH\Enabled=0` (x64) | ✓ | | | | always | | Low risk. Toggle provided | `A:tw/performance/disable-fth.yml` |
| P18 | Paging executive | `DisablePagingExecutive=1`, `DisablePageCombining=1` | (commented out) | | | | not run | | Atlas disabled its own task. `UNPROVEN` | `A:tw/performance/system/disable-paging.yml`, `A:Configuration/tweaks.yml` |
| P19 | Memory compression | `Disable-MMAgent -mc` | | ✓ | | | always | | `UNPROVEN`. More paging on low-RAM machines | `R:T/final.yml` |
| P20 | SysMain / Superfetch | A: Disable script (SysMain Start=4, ReadyBoost off) is **not** default. R: `revert.yml` re-enables Superfetch ("disabling breaks `defrag c: -b`") | toolbox | revert | | | — | | Both now leave SysMain on. Do not disable | `A:AD/6. Advanced Configuration/Services/Superfetch/*.cmd`, `R:T/revert.yml` |
| P21 | NTFS | `fsutil behavior set disablelastaccess 1`; `fsutil 8dot3name set 1` (A). R: revitool `ntfs-last-access disable`, `ntfs-8dot3-naming disable` | ✓ | ✓ | | | always | | Low risk. 8.3 off can break very old installers | `A:tw/performance/system/optimize-ntfs.yml`, `R:T/final.yml` |
| P22 | Service host split | A: `SvcHostSplitDisable=1` on every service except `Xbl*`/`Xbox*`. R: revitool `service-grouping set recommended`, and `revert.yml` resets `SvcHostSplitThresholdInKB=3670016` because the threshold method "breaks XboxGipSvc (#34)" | ✓ | ✓ | | | always | | `BREAKS` when done crudely. Lower process count, weaker fault isolation | `A:tw/performance/system/disable-service-host-split.yml`, `R:T/final.yml`, `R:T/revert.yml` |
| P23 | Game DVR / capture | `HKCU\System\GameConfigStore\GameDVR_Enabled=0`; `…\GameDVR\AppCaptureEnabled=0` | toolbox | ✓ | ✓ | ✓ | R: `GameDVR_Enabled` always, `AppCaptureEnabled` opt:`remove-appx-xbox` (off). P/T: always | **C** | R reverted `AppCaptureEnabled` once ("Start Recording greyed out, #74") | `R:reg/explorer/win-settings.yml`, `R:T/revert.yml`, `P:Configuration/tasks/regedits.yml` |
| P24 | Game Bar | A: full disable (policy `AllowGameDVR=0`, PresenceWriter `ActivationType=0`, tips) exists but is **commented out** in `tweaks.yml`. P/T: `UseNexusForGameBarEnabled=0` and hijack `ms-gamebar` protocol to `systray.exe` | toolbox | | ✓ | ✓ | P/T always | | Protocol hijack is hacky and hard to revert. Atlas keeps Game Bar on for compatibility | `A:tw/performance/disable-game-bar.yml`, `P:Configuration/tasks/regedits.yml` |
| P25 | FSO (fullscreen optimizations) | A toolbox: `GameDVR_FSEBehaviorMode=2`, `__COMPAT_LAYER=~ DISABLEDXMAXIMIZEDWINDOWEDMODE`, etc. R: `GameDVR_FSEBehaviorMode=0` | toolbox | ✓ | | | R always | | `UNPROVEN`. FSO is now generally beneficial (flip model) | `A:AD/3. General Configuration/FSO and Game Bar/*.cmd`, `R:T/final.yml` |
| P26 | Background apps | `BackgroundAccessApplications\GlobalUserDisabled=1`, `Search\BackgroundAppGlobalToggle=0` | ✓ | revert | | | A always. R re-enables via revitool | | `BREAKS`: R says it breaks the Xbox Game Bar KGL update and notification-dependent apps | `A:tw/performance/disable-background-apps.yml`, `R:reg/explorer/win-settings.yml` (commented), `R:T/revert.yml` |
| P27 | Hibernation | `powercfg /h off` (+ hide Hibernate in flyout, A) | ✓ | ✓ | ✓ | ✓ | A: opt:`disable-hibernation` (on). R: opt:`disable-hibernate` (default radio). P/T: always | **C** | R warns "may overheat laptops in sleep mode". Breaks Hybrid Sleep | `A:AD/3. General Configuration/Hibernation/Disable Hibernation (default).cmd`, `R:reg/system/power.yml`, `P:Executables/REGI.bat` |
| P28 | Fast Startup | `Session Manager\Power\HiberbootEnabled=0` (A). R: revitool `fast-startup disable`. P/T: implied by `/h off` | ✓ | ✓ | ✓ | ✓ | A always. R opt:`disable-hibernate`. P/T always | **C** | Low risk. Fixes dual-boot issues | `A:tw/scripts/script-power.yml`, `R:reg/system/power.yml` |
| P29 | Sleep Study logging | `wevtutil set-log` off for SleepStudy, Kernel-Processor-Power, UserModePowerService; disable `Power Efficiency Diagnostics\AnalyzeSystem` | ✓ | ✓ | | | always | | Low risk | `A:tw/performance/disable-sleep-study.yml`, `R:X/FINALIZE.cmd` |
| P30 | Search indexing | A: "Minimal" indexing: index Start Menu and Atlas folder, exclude `C:\Users`. A+R: `Gather\Windows\SystemIndex\RespectPowerModes=1`. R: policy `PreventIndexOnBattery=1`, IFEO `SearchIndexer.exe` CPU priority Below Normal. P/T: `AllowIndexingEncryptedStoresOrItems=0` | ✓ | ✓ | (✓) | (✓) | always | | Excluding Users breaks file search content. `RespectPowerModes` is the safe consensus-lite item | `A:AD/3. General Configuration/Search Indexing/Minimal Search Indexing (default).cmd`, `A:tw/performance/respect-power-modes-search.yml`, `R:reg/explorer/search.yml`, `R:reg/system/ifeo.yml` |
| P31 | Process priorities via IFEO | R: `CpuPriorityClass` Below Normal for `ctfmon`; **Idle** for `lsass`, `sihost`, `fontdrvhost` (+ `IoPriority=0`) | | ✓ | | | always | | `UNPROVEN`. Idle-priority lsass can delay logon/auth under load | `R:reg/system/ifeo.yml` |
| P32 | Automatic maintenance | A: only policy `Task Scheduler\Maintenance\WakeUp=0` (keeps maintenance for TRIM/defrag). R: `MaintenanceDisabled=1` + `ScheduledDiagnostics\EnabledExecution=0` | ✓ | ✓ | | | A always. R opt:`disable-automatic-maintenance` (off) | | Disabling maintenance stops TRIM/defrag; A explicitly avoided it | `A:tw/performance/config-automatic-maintenance.yml`, `R:reg/system/disable-automatic-maintenance.yml` |
| P33 | Auto disk check | `BootExecute = autocheck autochk /k:C*` (skip chkdsk on C:) | | ✓ | | | always | | Resilience risk: hides filesystem repair | `R:reg/system/boot.yml` |
| P34 | Network adapter tuning | NIC class key: `AutoDisableGigabit`, `ApCompatMode`, `SipsEnabled`, `ReduceSpeedOnPowerDown`, `DMACoalescing` → `0` (A explicitly leaves LSO, FlowControl, etc. alone as "unknown benefit") | ✓ | | | | always ("Reset Network to Atlas Default") | | Revert script ships ("Reset Network to Windows Default") | `A:AD/9. Troubleshooting/Network/Reset Network to Atlas Default.cmd`, `A:tw/networking/atlas-network-settings.yml` |
| P35 | Adapter bindings | `Disable-NetAdapterBinding` `ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr` | ✓ | | | | always | | **Disables SMB client/server** (file sharing). A re-enables these with its File Sharing toggle | `A:tw/scripts/script-devices.yml` |
| P36 | NetBT | Service `NetBT` Start=4 | ✓ | ✓ | | | always | | Breaks NetBIOS name resolution and legacy shares | `A:Configuration/atlas/services.yml`, `R:T/services.yml` |
| P37 | Nagle / TcpAckFrequency / TCPNoDelay | — | | | | | — | | **None of the four do this.** No basis to include | (grep: none) |
| P38 | LLMNR | Policy `DNSClient\EnableMulticast=0` | (commented out) | | | | not run | | Security-positive, but A turned it off "for compatibility" | `A:tw/networking/disable-llmnr.yml`, `A:Configuration/tweaks.yml` |
| P39 | SMB | A: `LanmanWorkstation\Parameters\DisableBandwidthThrottling=1`; `RestrictNullSessAccess=1`; `Lsa\RestrictAnonymous=1`. P/T: `LanmanWorkstation DependOnService = bowser,mrxsmb20,nsi` (drops SMB1 dependency) | ✓ | | ✓ | ✓ | always | | A's anonymous restrictions are security-positive (STIG). P/T change matters only after SMB1 removal | `A:tw/networking/shares/*.yml`, `P:Configuration/tasks/regedits.yml` |
| P40 | TCP stack misc | R: `tcpipreg` service disabled ("experimental"); Teredo set to default; `revert.yml` resets congestion provider (BBR2 "causes websocket issues, #27") | | ✓ | | | always | | `BREAKS` precedent for BBR2. `tcpipreg` disable is `UNPROVEN` | `R:T/services.yml`, `R:X/FINALIZE.cmd`, `R:T/revert.yml` |
| P41 | MSI mode (interrupts) | — | | | | | — | | **None of the four set `MSISupported`.** Leave out | (grep: none) |
| P42 | Disable PnP devices | Disable "High precision event timer", "System Timer", "System CMOS/real time clock", "Composite Bus Enumerator", "Intel Management Engine", SMBus, PCI memory/RAM controllers, "System Speaker", … | ✓ | | | | always | | **`UNPROVEN` and risky** (HPET/RTC/ME). Hard to revert. Do not ship | `A:Executables/DISABLEPNP.ps1`, `A:tw/scripts/script-devices.yml` |
| P43 | Misc drivers | `GpuEnergyDrv` Start=4 (A, R); `dam` Start=4 (R). R re-enabled `bam` ("breaks Efficiency Mode") | ✓ | ✓ | | | always | | Low impact | `A:Configuration/atlas/services.yml`, `R:T/services.yml`, `R:T/revert.yml` |
| P44 | ngen | ngen the assemblies loaded by PowerShell (`[AppDomain]::CurrentDomain.GetAssemblies()`); R also starts the `\Microsoft\Windows\.NET Framework\` tasks | ✓ | ✓ | | | always | | Safe. A: "speeds up powershell startup 10x" | `A:Executables/NGEN.ps1`, `R:X/ngen.ps1` |
| P45 | Shutdown timeouts | `WaitToKillServiceTimeout` 2000 (A, P, T) / 1500 (R); `HKCU\Control Panel\Desktop` `HungAppTimeout=2000`, `WaitToKillAppTimeout=2000` (A, R; P/T set the latter) | ✓ | ✓ | ✓ | ✓ | always | **C** | Slight risk of unsaved data on shutdown. **P/T write `HungAppTimeout` and `AutoEndTasks` under `HKLM\SYSTEM\CurrentControlSet\Control`**, which is likely the wrong key (unverified) | `A:tw/qol/startup-shutdown/decrease-shutdown-time.yml`, `R:reg/explorer/control-panel.yml`, `R:reg/explorer/explorer.yml`, `P:Configuration/tasks/regedits.yml` |
| P46 | AutoEndTasks | `HKCU\Control Panel\Desktop\AutoEndTasks=1` | (commented out) | ✓ | (HKLM) | (HKLM) | R always | | Data-loss risk on shutdown; A disabled its own task | `A:tw/qol/startup-shutdown/force-end-shutdown-apps.yml`, `R:reg/explorer/control-panel.yml` |
| P47 | Startup delay | `Explorer\Serialize\StartupDelayInMSec=0` | ✓ | | | | always | | Low risk | `A:tw/qol/startup-shutdown/disable-startup-delay.yml` |
| P48 | Explorer folder discovery | `…\Bags\AllFolders\Shell\FolderType=NotSpecified` | ✓ | ✓ | | | always | | Safe, real benefit on media-heavy folders | `A:tw/performance/disable-auto-folder-discovery.yml`, `R:reg/explorer/explorer.yml` |
| P49 | Explorer misc perf | R: Explorer GPU preference `GpuPreference=2`; `DisableGraphRecentItems=1`; remove `GroupBy` on Downloads. A: `Max Cached Icons=4096`; classic Explorer search box (`TreatAs` CLSID) | ✓ | ✓ | (✓ ui) | (✓ ui) | always (P/T classic search gated `ui`) | | Low risk | `R:reg/explorer/explorer.yml`, `A:tw/qol/explorer/extend-cache.yml`, `A:tw/qol/explorer/classic-search.yml`, `P:Configuration/tasks/software.yml` |
| P50 | Visual effects | A: `VisualFXSetting=3` + custom `UserPreferencesMask`, `TaskbarAnimations=0`, `MinAnimate=0`, `EnableAeroPeek=0`. R: `EnableTransparency=0` + `MinAnimate=0` | ✓ | ✓ | | | A always. R opt:`configure-te` (on) | | Cosmetic. Atlas ships a "Default Windows Visual Effects" revert | `A:tw/qol/visual-effects.yml`, `R:reg/explorer/win-settings.yml` |
| P51 | Crash dumps | `CrashControl\AutoReboot=0` (A, R); `CrashDumpEnabled=0` (A, no dumps) vs `3` (R, small dump) | ✓ | ✓ | | | always | | Prefer R's small dump; no dump hampers diagnosis | `A:tw/qol/system/crash-control-qol.yml`, `R:reg/system/crash-control.yml` |
| P52 | WPBT | `Session Manager\DisableWpbtExecution=1` | ✓ | ✓ | | | always | | Blocks firmware-injected OEM binaries. Undocumented value | `A:tw/qol/system/disable-wpbt.yml`, `R:reg/misc/fixes.yml` |
| P53 | HAGS | `GraphicsDrivers\HwSchMode=2` | | considered, **not applied** | | | — | | R comment: "One of our users had Hardware Acceleration issues, therefore discarded" | `R:reg/explorer/win-settings.yml` |

---

## 2. Quality of life and UI

| # | Area | Concrete change | A | R | P | T | Gate | C | Flag / notes | Source |
|---|------|-----------------|---|---|---|---|------|---|--------------|--------|
| Q1 | Classic context menu (Win11) | `HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32` = `""` | ✓ | ✓ | ✓ | n/a | A always (+ `oobe: only` fallback via `reg add`). R opt:`configure-lcm` (on). P opt:`ui` (on) | **C** (Win11 3/3) | Reversible (delete key). Per-user HKCU, so it must reach the default-user hive too | `A:tw/qol/shell/restore-old-context-menu.yml`, `R:reg/explorer/context-menu.yml`, `P:Configuration/tasks/software.yml` |
| Q2 | Context menu additions | A: "Merge as TrustedInstaller" for .reg, New → .bat/.ps1/.reg. R: "Take Ownership" for files/dirs/dll + exe runas | ✓ | ✓ | | | always | | R's Take Ownership is a footgun on system dirs (it excludes some via `AppliesTo`) | `A:tw/qol/explorer/add-context-menus/*.yml`, `R:reg/explorer/context-menu.yml` |
| Q3 | Context menu removals | Cast to device, Share, Include in Library, Previous Versions, Troubleshoot compatibility, Paint 3D, New BMP/RTF, Extract, Print; Send To debloat | ✓ | | | | always | | Previous Versions removal hides shadow-copy restore | `A:tw/qol/explorer/remove-context-menus/*.yml`, `A:tw/qol/explorer/remove-previous-versions.yml`, `A:tw/qol/explorer/debloat-send-to.yml` |
| Q4 | >15 items context | `Explorer\MultipleInvokePromptMinimum=100` | ✓ | ✓ | | | always | | Safe | `A:tw/qol/explorer/full-context-on-more-than-15-items.yml`, `R:reg/explorer/explorer.yml` |
| Q5 | File extensions | `Advanced\HideFileExt=0` | ✓ | ✓ | ✓ | ✓ | always | **C** | Security-positive | `A:tw/qol/explorer/show-files.yml`, `R:reg/explorer/view.yml`, `P:Configuration/tasks/regedits.yml` |
| Q6 | Hidden files | `Advanced\Hidden=1` | ✓ | | ✓ | ✓ | always | **C** | Taste | same as Q5 |
| Q7 | Explorer opens to This PC | `Advanced\LaunchTo=1` | ✓ | ✓ | ✓ | ✓ | always | **C** | Taste. Safe | `A:tw/qol/explorer/open-to-this-pc.yml`, `R:reg/explorer/explorer.yml`, `P:Configuration/tasks/regedits.yml` |
| Q8 | Checkbox selection off | `Advanced\AutoCheckSelect=0` | ✓ | | ✓ | ✓ | always | **C** | Taste | `A:tw/qol/explorer/disable-check-boxes.yml`, `P:Configuration/tasks/regedits.yml` |
| Q9 | Copy dialog details | `OperationStatusManager\EnthusiastMode=1` | ✓ | ✓ | | | always | | Safe | `A:tw/qol/explorer/always-more-details-transfer.yml`, `R:reg/explorer/explorer.yml` |
| Q10 | "- Shortcut" suffix | A: `NamingTemplates\ShortcutNameTemplate="%s.lnk"`. R: `Explorer\link` = `00000000` | ✓ | ✓ | | | always | | Safe | `A:tw/qol/explorer/remove-shortcut-text.yml`, `R:reg/explorer/explorer.yml` |
| Q11 | Quick Access / Home | A: `ShowFrequent=0`, `ShowRecent=0`, `Start_TrackDocs=0`, `ClearRecentDocsOnExit`, `NoRecentDocsHistory`, `ShowCloudFilesInQuickAccess=0`, Gallery hidden, compact mode, removable drives only in This PC, network nav pane hidden | ✓ | | | | always | | Taste. Several use toolbox `.cmd` because of an "AME hives issue" noted in comments | `A:tw/qol/explorer/*.yml` |
| Q12 | Full path in title bar | `CabinetState\FullPath=1`; `ShowInfoTip=0` | | ✓ | | | always | | Taste | `R:reg/explorer/view.yml`, `R:reg/explorer/explorer.yml` |
| Q13 | Long paths | `FileSystem\LongPathsEnabled=1` | ✓ | | | | always | | Safe | `A:tw/qol/explorer/enable-long-paths.yml` |
| Q14 | AutoPlay / AutoRun | `AutoplayHandlers\DisableAutoplay=1` (all four); `NoDriveTypeAutoRun` 255 (R) / 181 (P, T); `NoAutorun=1` (P, T) | ✓ | ✓ | ✓ | ✓ | always | **C** | Security-positive | `A:tw/qol/shell/config-autorun.yml`, `R:reg/explorer/explorer.yml`, `P:Configuration/tasks/regedits.yml` |
| Q15 | Low disk warning off | `Policies\Explorer\NoLowDiskSpaceChecks=1` | ✓ | ✓ | | | always | | Hides a useful warning | `A:tw/qol/shell/disable-low-disk-warning.yml`, `R:reg/explorer/explorer.yml` |
| Q16 | Shortcut resolve | `NoResolveSearch=1` (A, R); `NoResolveTrack=1` (A); `LinkResolveIgnoreLinkInfo=1` (R) | ✓ | ✓ | | | always | | Safe | `A:tw/qol/explorer/disable-invalid-shortcuts-search.yml`, `R:reg/explorer/start-menu.yml` |
| Q17 | Start: recommendations off | `Advanced\Start_IrisRecommendations=0`, `Start_AccountNotifications=0` | ✓ | ✓ | ✓ | ✓ | always | **C** | Safe | `A:tw/qol/shell/no-recommendations-start-menu.yml`, `R:reg/explorer/explorer.yml`, `P:Configuration/tasks/regedits.yml` |
| Q18 | Start: pins | `PolicyManager\current\device\Start\ConfigureStartPins` JSON (A: Settings, Terminal, Explorer, Store, Xbox, Calc, Notepad, Paint, Security. R: Store, Settings, Notepad, Paint, Explorer, Calc) + clear StartMenuExperienceHost cache | ✓ | ✓ | (Open-Shell) | (Open-Shell) | A always. R opt:`remove-pinned-items-startmenu` (on). P/T opt:`ui` | | The `PolicyManager\current` path is a policy-store write; it may lock the user's pins (needs a VM check) | `A:tw/qol/config-start-menu.yml`, `A:Executables/STARTMENU.ps1`, `R:reg/explorer/start-menu.yml`, `R:X/STARTMENU.cmd` |
| Q19 | Start: lists | A: `NoStartMenuMFUprogramsList`, `ShowOrHideMostUsedApps=2`, `HideRecentlyAddedApps=1`, `HideRecommendedPersonalizedSites=1`, `Start_Layout=1` (more pins). R: Start folders all hidden except Settings | ✓ | ✓ | | | always | | Taste | `A:tw/qol/config-start-menu.yml`, `A:tw/qol/shell/show-more-pins.yml`, `R:reg/explorer/start-menu.yml` |
| Q20 | Start replacement | Install Open-Shell + ExplorerPatcher (`ep_setup-22621.2428.59.1.exe`) with Win10 taskbar/start settings; `ame-hexer.exe` binary-patches `shellstyle.dll` | | | ✓ | ✓ (Open-Shell) | opt:`ui` (on) | | Third-party shell hooks break on feature updates; binary patching system DLLs is fragile. Avoid | `P:Configuration/tasks/software.yml`, `P:Executables/OLDUI.bat` |
| Q21 | Taskbar: Widgets/News | Policy `Windows Feeds\EnableFeeds=0`; `Dsh\AllowNewsAndInterests=0` (A, R); `TaskbarDa=0` (R, P, T) | ✓ | ✓ | ✓ | ✓ | always (T `TaskbarDa` gated `ui`) | **C** | Safe | `A:tw/qol/taskbar/disable-news-and-interests.yml`, `R:reg/explorer/taskbar.yml`, `P:Configuration/tasks/regedits.yml` |
| Q22 | Taskbar: Chat/Teams | Policy `Windows Chat\ChatIcon=3`; `TaskbarMn=0` | ✓ | ✓ | ✓ | ✓ | always | **C** | Mostly moot on 24H2+ (Chat removed) | `A:tw/qol/taskbar/disable-windows-chat.yml`, `R:reg/explorer/taskbar.yml`, `P:Configuration/tasks/regedits.yml` |
| Q23 | Taskbar: Copilot | `WindowsCopilot\TurnOffWindowsCopilot=1` (A in **HKCU**: "Doesn't work with HKLM"; P/T in HKLM); `ShowCopilotButton=0` (P, T); A: `AuxilliaryPins\CopilotPWAPin=0`. R removes the Copilot package (opt:`remove-winsxs-ai`) | ✓ | (removal) | ✓ | ✓ | always | **C** | On 24H2+ Copilot is an app; the policy is legacy | `A:tw/qol/taskbar/disable-copilot.yml`, `A:tw/qol/taskbar/config-pins.yml`, `P:Configuration/tasks/regedits.yml` |
| Q24 | Taskbar: Meet Now | `Policies\Explorer\HideSCAMeetNow=1` | ✓ | ✓ | ✓ | ✓ | always | **C** | Legacy (Win10). Harmless | `A:tw/qol/taskbar/hide-meet-now.yml`, `R:reg/explorer/taskbar.yml`, `P:Configuration/tasks/regedits.yml` |
| Q25 | Taskbar: Task View button | `Advanced\ShowTaskViewButton=0` | ✓ | ✓ | ✓ | ✓ | always (P/T gated `ui` for HKCU) | **C** | Taste | `A:tw/qol/taskbar/hide-task-view.yml`, `R:reg/explorer/taskbar.yml` |
| Q26 | Taskbar: left alignment | `Advanced\TaskbarAl=0` | ✓ | | ✓ | (✓) | A always. P/T opt:`ui` | **C** | Taste | `A:tw/qol/taskbar/set-to-left.yml`, `P:Configuration/tasks/regedits.yml` |
| Q27 | Taskbar: search box | `Search\SearchboxTaskbarMode` = 1 icon (R) / 0 hidden (P, T) | | ✓ | ✓ | ✓ | R always. P/T opt:`ui` | **C** (value differs) | Taste | `R:reg/explorer/taskbar.yml`, `P:Configuration/tasks/regedits.yml` |
| Q28 | Taskbar: End Task | `Advanced\TaskbarDeveloperSettings\TaskbarEndTask=1` | ✓ | ✓ | | | A `builds: ['>22000']`. R always | | Safe | `A:tw/qol/taskbar/end-task.yml`, `R:reg/explorer/explorer.yml` |
| Q29 | Taskbar misc | A: `DisablePreviewDesktop=1`, `DontUsePowerShellOnWinX=1`, cloud-optimized content off (`DisableCloudOptimizedContent=1`, also P "prevents Outlook pin on 24H2"), taskbar pins (browser + Explorer). P/T: `TaskbarGlomLevel=1` | ✓ | | ✓ | ✓ | mixed | | Taste | `A:tw/qol/taskbar/*.yml`, `P:Configuration/tasks/regedits.yml` |
| Q30 | Notifications: tips & suggestions | ContentDeliveryManager: `ContentDeliveryAllowed=0`, `SubscribedContent-310093/338388/338389/338393/353694/353696Enabled=0`, `SystemPaneSuggestionsEnabled=0`, `SilentInstalledAppsEnabled=0`, `SoftLandingEnabled=0` | ✓ | ✓ | ✓ | ✓ | always | **C** | Privacy plus QoL. Safe | `A:tw/debloat/config-content-delivery.yml`, `R:reg/explorer/win-settings.yml`, `P:Configuration/tasks/regedits.yml` |
| Q31 | Notifications: system toasts | Security and Maintenance toast `Enabled=0` (P, T permanently; R at deploy start); A turns all toasts off during deploy (`ToastEnabled=0`) and back on at the end; `NoWinBackupNotifications=1`; BackupReminder toast off (P, T); R: `NoBalloonFeatureAdvertisements`, `NoAutoTrayNotify`, `NoCloudApplicationNotification`, `ScoobeSystemSettingEnabled=0` ("Let's finish setting up"); A: USB error / weak-charger notifications off | ✓ | ✓ | ✓ | ✓ | always | **C** (S&M toast: R, P, T) | Hiding Security and Maintenance permanently hides real warnings (`SEC`, mild) | `A:Executables/DISABLENOTIFS.cmd`, `A:tw/misc/enable-notifications.yml`, `R:T/start.yml`, `R:reg/explorer/notifications.yml`, `P:Configuration/tasks/regedits.yml` |
| Q32 | Windows Update notifications | R: `UpdateNotificationLevel=2` (no notifications, including restart warnings) | | ✓ | | | always | | `SEC`: users miss pending security restarts | `R:reg/explorer/notifications.yml` |
| Q33 | Settings: tips / banner | `AllowOnlineTips=0` (A, R); ValueBanner `ActivationType` = 0 (A) / 0xFFFFFFFF + `Server=""` (R, TrustedInstaller) | ✓ | ✓ | | | A banner `builds: ['>=22000']` | | Safe | `A:tw/qol/disable-settings-tips.yml`, `A:tw/qol/disable-win11-settings-banner.yml`, `R:reg/explorer/win-settings.yml` |
| Q34 | Settings: hidden pages | `Policies\Explorer\SettingsPageVisibility` — A: `hide:recovery;maps;…;home` (Win11 variant `>=22000`). R: revitool `hide-page cortana,privacy-feedback,windowsinsider,home` (+ `crossdevice` with Phone Link removal). P: `hide:windowsdefender;activation;…;windowsupdate…`. T: `showonly:…` | ✓ | ✓ | ✓ | ✓ | always | **C** | Hiding pages for features that still exist confuses users; hide only removed components | `A:tw/qol/set-hidden-settings-pages.yml`, `R:reg/explorer/win-settings.yml`, `P:Configuration/tasks/regedits.yml` |
| Q35 | Windows Spotlight | A: CloudContent policy `DisableWindowsSpotlightFeatures` etc. + hide desktop Spotlight icon. R: hide Spotlight desktop icon (24H2, HKLM `HideDesktopIcons\NewStartPanel`). A: lock-screen overlays off | ✓ | ✓ | | | always | | Safe | `A:tw/qol/disable-windows-spotlight.yml`, `R:reg/explorer/explorer.yml` |
| Q36 | Appearance: theme | A: custom `atlas-v0.5.x-dark.theme` + default-user `ThemeFile` policy, lock-screen image, `ThemeChangesMousePointers/DesktopIcons=0`, blue tooltips. R: `Set-Theme.ps1` dark or light + `AppsUseLightTheme`/`SystemUsesLightTheme`. P/T: system dark, apps light (`aero.theme` edited in place) | ✓ | ✓ | ✓ | ✓ | A always. R opt:`configure-darkmode` (on). P/T opt:`ui` | **C** (dark system mode) | A's default-user `ThemeFile` **policy** locks the theme for new users. P/T edit a system theme file after `icacls /reset` | `A:tw/qol/appearance/*.yml`, `R:T/final.yml`, `R:X/Set-Theme.ps1`, `P:Executables/WALLPAPER.bat` |
| Q37 | Wallpaper | Own wallpaper + lock screen (A via theme; R `WALLPAPER.ps1` + RunOnce `WallpaperStartup.cmd`; P/T `WALLPAPER.bat` per hive) | ✓ | ✓ | ✓ | ✓ | A always. R opt:`configure-wallpaper` (on). P/T opt:`ui` | **C** | Branding. Our images need our own licence | `R:T/final.yml`, `P:Executables/WALLPAPER.bat` |
| Q38 | Wallpaper quality | `HKCU\Control Panel\Desktop\JPEGImportQuality=100` | ✓ | ✓ | | | always | | Safe | `A:tw/qol/best-wallpaper-quality.yml`, `R:reg/explorer/control-panel.yml` |
| Q39 | Accessibility shortcuts | A: `StickyKeys/ToggleKeys/Keyboard Response/MouseKeys/HighContrast\Flags=0`, language hotkeys off, Narrator Win+Enter off, `SlateLaunch\LaunchAT=0`, warning sounds off. R: **deletes** all `Control Panel\Accessibility\*` keys then writes `Flags="0"` (REG_SZ) for 13 features (HKCU and `.DEFAULT`) | ✓ | ✓ | | | always | | **Accessibility risk**: users who need these features lose the shortcut. R's key deletion is destructive. Prefer A's narrower approach, behind an option | `A:tw/qol/ease-of-access/*.yml`, `R:reg/explorer/control-panel.yml` |
| Q40 | Mouse acceleration | `HKCU\Control Panel\Mouse` `MouseSpeed=0`, `MouseThreshold1=0`, `MouseThreshold2=0` | ✓ | ✓ | | | always | | Taste (gamers). Hurts some touchpad users | `A:tw/qol/disable-mouse-accel.yml`, `R:reg/explorer/control-panel.yml` |
| Q41 | Menu / hover delays | `MenuShowDelay=0` (A, R); `MouseHoverTime=20` (A) — **R reverted its own to 400** ("hints overlapping each other"); R `ActiveWndTrkTimeout=10`, `LowLevelHooksTimeout=1000` | ✓ | ✓ | | | always | | `BREAKS` precedent for MouseHoverTime. `LowLevelHooksTimeout` can break input hooks (AutoHotkey, accessibility tools) | `A:tw/qol/shell/disable-menu-delay.yml`, `A:tw/qol/explorer/minimize-mouse-hover-time.yml`, `R:reg/explorer/control-panel.yml`, `R:T/revert.yml` |
| Q42 | Typing / touch | Autocorrect, spellcheck, text prediction off (`TabletTip\1.7`); R also hardware-keyboard `Input\Settings`; A touch visual feedback off, Ink Workspace suggestions off | ✓ | ✓ | | | always | | Taste. Spellcheck-off is a usability regression for many | `A:tw/qol/disable-spell-checking.yml`, `R:reg/explorer/win-settings.yml` |
| Q43 | Misc shell | Aero Shake off (A; P/T commented out); Alt+Tab windows only (A); Snap/nearby sharing off (A); tablet mode never (A, R); audio ducking "do nothing" `UserDuckingPreference=3` (A, R); clipboard history off (R); Sudo inline (R); system beep off (R); first-logon animation and startup sound off (R); `DisableAutomaticRestartSignOn=1` (R) | ✓ | ✓ | | | always | | Taste | `A:tw/qol/shell/*.yml`, `A:tw/qol/do-not-reduce-sounds.yml`, `R:reg/explorer/win-settings.yml`, `R:reg/misc/enable-audio-communications-do-nothing.yml`, `R:reg/system/logon.yml` |
| Q44 | UAC | A: `PromptOnSecureDesktop=0`. P/T opt:`security-enhanced` (default): `ConsentPromptBehaviorAdmin=5`, `PromptOnSecureDesktop=1`, + separate admin account (`ADMIN.bat`) | ✓ | | ✓ | ✓ | A always. P/T radio (default enhanced) | | **A = `SEC`** (secure desktop off). P/T harden | `A:tw/qol/security/disable-uac-secure-desktop.yml`, `P:Configuration/tasks/config.yml` |
| Q45 | Control Panel | A: "All Tasks" (God Mode) namespace; `.pow` double-click import | ✓ | | | | always | | Safe | `A:tw/qol/show-all-tasks-control-panel.yml`, `A:tw/qol/explorer/import-power-plan.yml` |
| Q46 | Default browser / file associations | A: `FILEASSOC.cmd` → `ASSOC.ps1` computes the UserChoice hash (SetUserFTA algorithm) per user, run through a **copied, randomly renamed `powershell.exe` to bypass UCPD**; also sets 7-Zip associations. R: playbook.conf `<Software … DefaultWebBrowser="true">` + `OEMDefaultAssociations.xml` + `assoc.ps1` that deletes `UserChoice` keys; Photo Viewer associations under opt:`remove-appx-photos`. P/T: `DefaultWebBrowser` package attribute + `assoc.ps1` (same as R's) for nomacs/VLC/etc. | ✓ | ✓ | ✓ | ✓ | per browser option | **C** (scripted per-user assoc) | UCPD-sensitive, see §3 | `A:Executables/FILEASSOC.cmd`, `A:Executables/ASSOC.ps1`, `R:X/FILEASSOC.cmd`, `R:X/assoc.ps1`, `R:X/OEMDefaultAssociations.xml`, `P:Executables/FILEASSOC.bat` |
| Q47 | Classic Photo Viewer | Register `PhotoViewer.FileAssoc.*` and associate images | | ✓ | | | opt:`remove-appx-photos` (on) | | Safe | `R:reg/misc/classic-photo-viewer.yml` |
| Q48 | Shortcuts / desktop | A: `SHORTCUTS.ps1` (desktop shortcuts, Atlas folder), profile pictures `PFP.ps1` (`onUpgrade: false`), "Sharing Settings" shortcut. P/T: `SOFTSHRT.bat`, `Terminal.lnk` | ✓ | | ✓ | ✓ | always | **C** (loose) | Branding | `A:tw/misc/create-shortcuts.yml`, `A:tw/scripts/script-pfp.yml`, `P:Executables/SOFTSHRT.bat` |
| Q49 | Storage Sense | Enable monthly temp cleanup, never Downloads/Recycle Bin | ✓ | | | | always | | Safe, useful | `A:tw/debloat/config-storage-sense.yml` |
| Q50 | Store app archiving | Disable automatic archiving | ✓ | | | | always | | Safe | `A:tw/qol/disable-auto-app-archival.yml` |
| Q51 | Time | A, P, T: `w32tm` NTP peers set to `pool.ntp.org`. R: `RealTimeIsUniversal=1` (UTC RTC for dual boot) | ✓ | ✓ | ✓ | ✓ | always | **C** (NTP: A, P, T) | R's UTC RTC is **wrong for single-boot users** whose firmware clock is local time; it shifts the clock | `R:reg/misc/fixes.yml`, `P:Configuration/tasks/config.yml`, `A:tw/misc/config-time.yml` |

---

## 3. UCPD (User Choice Protection Driver)

UCPD (`UCPD.sys`, service `UCPD`, plus scheduled task
`\Microsoft\Windows\AppxDeploymentClient\UCPD velocity` that re-enables it)
blocks non-Microsoft processes such as `powershell.exe` and `reg.exe` from
writing `UserChoice` for http, https and .pdf. It affects Q46 (default
browser), and Windows may also protect some other `HKCU` shell keys.

| Playbook | How it handles UCPD | Source |
|----------|---------------------|--------|
| A | `<Requirement>UCPDDisabled</Requirement>` (AME Wizard makes the user disable it in Prepare System) **and** service `UCPD` Start=4 **and** disables the "UCPD velocity" task (`ignoreErrors: true`) **and**, as a belt-and-braces bypass, runs `ASSOC.ps1` from a copied, renamed `powershell<random>.exe` (cites hitco.at UCPD article) | `atlas/src/playbook/playbook.conf`, `A:Configuration/atlas/services.yml`, `A:tw/debloat/disable-scheduled-tasks.yml`, `A:Executables/FILEASSOC.cmd` |
| R | No `UCPDDisabled` requirement. Disables service `UCPD` (Start=4) and the "UCPD velocity" task in `services.yml`. Associations rely on `OEMDefaultAssociations.xml` plus deleting existing `UserChoice` keys, and on AME Wizard's own `DefaultWebBrowser` package handling | `R:T/services.yml`, `R:X/FILEASSOC.cmd` |
| P | `<Requirement>UCPDDisabled</Requirement>`. Associations via `assoc.ps1` and `DefaultWebBrowser` packages | `privacyplus/playbook.conf` |
| T | Nothing UCPD-specific (Win10 22H2 also received UCPD, so its association step may silently fail there) | `ame10/playbook.conf` |

**Consensus:** 3 of 4 (A, R, P) neutralise UCPD before touching
associations. `UCPDDisabled` is a documented requirement
(`docs/reconnaissance.md`). Disabling the service permanently is a mild
security trade-off: it removes Microsoft's protection against hijacking of
the default browser. Our playbook should either (a) use the
`UCPDDisabled` requirement and let AME's own `DefaultWebBrowser` mechanism set
the browser, without a renamed-binary bypass, or (b) leave browser
defaults to the user. Atlas's renamed-PowerShell trick is a deliberate
evasion. Do not copy it.

Changes that UCPD may block: the http/https/.pdf UserChoice (Q46). The other
QoL items in §2 are ordinary HKCU or HKLM values and are not known to be
UCPD-protected. No reference playbook gates them on UCPD.

---

## 4. Build-specific gates seen

| Item | Gate in reference | Source |
|------|-------------------|--------|
| Atlas overall | `SupportedBuilds` 26100, 26200 only (24H2/25H2) | `atlas/src/playbook/playbook.conf` |
| VBS disable | Comments say HVCI `Enabled` "needs to be forced since 24H2"; `Lsa\RunAsPPL` and `DeviceGuard\EnableVirtualizationBasedSecurity` described as "24H2 only" (no `builds:` key; applied unconditionally within the option) | `A:SW/ConfigVBS.ps1` |
| Win11-only shell tweaks | `builds: ['>=22000']`: classic context menu, Gallery, compact mode, Copilot, Chat, left taskbar, more pins, Iris recommendations, dynamic lighting, Resume, Office files in Home, Settings banner | `A:tw/qol/**` |
| End Task | `builds: ['>22000']` | `A:tw/qol/taskbar/end-task.yml` |
| Settings page list | Separate values for `<22000` and `>=22000` | `A:tw/qol/set-hidden-settings-pages.yml` |
| Spotlight desktop icon | Comment "24H2" | `R:reg/explorer/explorer.yml` |
| Recall snapshots | `WindowsAI\DisableAIDataAnalysis=1`, comment "24H2" | `R:reg/explorer/win-settings.yml` |
| Store results in Search | WinStore.Tasks.WindowsSearchTask `ActivationType` 0xFFFFFFFF, comment "25H2" | `R:reg/explorer/search.yml` |
| WebView2 from SearchHost | FeatureManagement override `1694661260=0` | `R:reg/explorer/search.yml` |
| Outlook auto-pin | `DisableCloudOptimizedContent=1`, comment "Prevents Outlook from getting pinned in 24H2" | `P:Configuration/tasks/regedits.yml` |
| Win10 vs Win11 in R | `FINALIZE.cmd` branches on `CurrentBuild > 19045` (branding only) | `R:X/FINALIZE.cmd` |
| FTH | `cpuArch: 'X64'`; folder deleted on Arm64 | `A:tw/performance/disable-fth.yml` |

R mostly relies on values being harmless on builds where they are not used,
and does not use `builds:` gates.

---

## 5. Consensus summary (3 or more of 4)

**Performance:** power-plan change (P1, with Atlas only when its option is on);
bcdedit `bootmenupolicy legacy` (P9); hibernation off (P27) and Fast Startup
off (P28); shorter shutdown timeouts (P45); vulnerable-driver blocklist on
(P16, security-positive); Game DVR capture off (P23).

**QoL:** classic context menu (Q1, all three Win11 playbooks); show
extensions (Q5); show hidden files (Q6); open to This PC (Q7); checkboxes off
(Q8); AutoPlay off (Q14); Start recommendations off (Q17); Widgets off (Q21);
Chat off (Q22); Copilot off (Q23); Meet Now hidden (Q24); Task View hidden
(Q25); left taskbar (Q26); search box changed (Q27); ContentDeliveryManager
suggestions off (Q30); Security and Maintenance toasts off (Q31); Settings page
hiding (Q34); dark system theme (Q36); custom wallpaper (Q37); scripted
per-user file associations (Q46); NTP pool time servers (Q51). UCPD is neutralised before associations in
3 of 4.

**Notably *not* consensus or *not done* by anyone:** Nagle/TcpAckFrequency,
MSI-mode interrupts, `LargeSystemCache`, `ClearPageFileAtShutdown`, Prefetch
registry values, HAGS (considered and rejected by R), forced timer resolution
(Atlas ships it disabled by default), SysMain disable (both A and R keep it on),
LLMNR disable (Atlas commented it out), and background-apps disable (R reverted
it).

## 6. Security trade-offs, stated plainly

- **Disabling CPU mitigations (P12)** re-exposes Spectre/Meltdown-class and
  exploit-mitigation attack surface (CFG, SEHOP, DEP limited to OptIn). Atlas
  ships it opt-in and default off, and says it may *reduce* performance on
  modern CPUs. ReviOS removed its old mitigation tweaks.
- **Disabling VBS/HVCI/Core Isolation (P15)** removes kernel code-integrity
  enforcement, Credential Guard and (Atlas) LSA protection. Atlas's checkbox is
  checked by default. ReviOS does it unconditionally through an opaque tool.
- **Enabling Intel TSX (P14)** reverses a Microsoft security default.
- **UAC secure desktop off (Q44)**, **Windows Update notifications off (Q32)**,
  **Security and Maintenance toasts off (Q31)** and **UCPD off (§3)** each
  weaken security a little.
- **WinRE auto-recovery off (P11)**, **autochk skipped on C: (P33)** and
  **crash dumps off (P51, Atlas)** make recovery and diagnosis harder.
- Unproven or risky with no cited measurement: CPU idle off (P5), timer
  resolution (P6), disabling HPET/RTC/ME devices (P42), lsass at Idle
  priority (P31), memory compression off (P19), `tcpipreg` off (P40).
