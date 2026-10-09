# Privacy and telemetry inventory (reference playbooks)

Research input for Phase 3/4. The inventory covers every privacy or telemetry change found in
four reference playbooks, grouped by theme, with exact paths, values and data.
Compiled 2026-10-09 by reading the sources only. Nothing was executed.

**Treat this as data, not as an approved tweak list.** Items move into our YAML only after the
Phase 3 stance decisions. Each item still needs a VM proof (CLAUDE.md hard rules 1, 3 and 5).

## 0. Sources, legend, conventions

### Playbooks compared

| Col | Playbook | Version / builds | Root (relative to `refs/`) |
|---|---|---|---|
| **A** | AtlasOS | v0.5.0; SupportedBuilds 26100, 26200 | `atlas/src/playbook/` |
| **R** | ReviOS | 26.04 release; 19044, 19045, 22631, 26100, 26200 | `revi-apbx/` (registry YAML is the same in `revi/src/`; only the appx-remover call differs) |
| **P** | AME Privacy+ | 0.8.2; 22000, 22621, 22631, 22635, 26100, 26200 | `privacyplus/` |
| **10** | AME 10 | Win10 19044, 19045 | `ame10/` |

### Path abbreviations used in the "Source" column

| Abbrev | Expands to (under `refs/`) |
|---|---|
| `A/` | `atlas/src/playbook/Configuration/` |
| `AX/` | `atlas/src/playbook/Executables/` |
| `AD/` | `atlas/src/playbook/Executables/AtlasDesktop/` (Atlas runs every `*(default).cmd` here through `AX/DEFAULT.ps1`, called from `A/atlas/default.yml`, so these scripts count as **applied by default**) |
| `R/` | `revi-apbx/Configuration/Tasks/` |
| `RX/` | `revi-apbx/Executables/` |
| `P/` | `privacyplus/Configuration/tasks/` |
| `PX/` | `privacyplus/Executables/` |
| `M/` | `ame10/Configuration/tasks/` |
| `MX/` | `ame10/Executables/` |

### Column legend

- **A / R / P / 10**: `Y` = the playbook applies the change exactly as written. `~` = same intent, but a
  different key, value or mechanism (see the Notes column). `S` = service `stop` only, which does not
  persist past a reboot. `-` = the playbook does not do it. `X` = the playbook does the **opposite**.
- **Cnt** = number of playbooks with `Y` or `~`. **Bold Cnt (3 or 4) = consensus**, the safest baseline.
  AME10 targets Win10 only. A 3/3 among the Win11-capable playbooks (A, R, P) also counts as consensus,
  marked `3*`.
- **Gate** = how the change is gated. `-` = always applied. `opt:<name>` = gated by a feature-page option.
  `b>=22000` = gated with `builds:`.
- **Rev** = how hard the change is to undo.
  - `E`: policy or registry value. Delete the value to revert.
  - `E*`: overwrites a non-policy value. Revert needs the original default, so record it.
  - `M`: service start type or task disable. Revert needs the original start type.
  - `H`: deletes a service, file, task, appx package or key. Revert needs a reinstall, DISM/SFC or the Store.
  - `X`: CBS package or WinSxS component removal. Revert by uninstalling the package, if a script for that exists.
- All registry data is `REG_DWORD` unless a type is given. Revi also writes every HKCU value to
  `HKU\.DEFAULT\...`. Atlas copies HKCU to the default user via `AX/APPLYDUHIVE.ps1`. AME Wizard
  applies `HKCU` to all user hives by default (`docs/action-catalog.md`, `scope`).
- AME `!scheduledTask` defaults to `operation: delete` (`docs/action-catalog.md`). P and 10 delete tasks.
  A and R disable them.

---

## 1. Core telemetry (DataCollection, DiagTrack, autologgers)

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes / risk | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| T1 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection` `AllowTelemetry`=0 | Y | Y | Y | Y | **4** | - | E | Value 0 (Security) is honoured only on Enterprise, Education and Server. Home and Pro clamp it to 1 (Required). Settings then shows "managed by your organization". | A/tweaks/privacy/telemetry/disallow-data-collection.yml; R/registry/privacy/telemetry.yml; P/regedits.yml; M/regedits.yml |
| T2 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection` `AllowTelemetry`=0 | Y | Y | Y | Y | **4** | - | E | Same caveat as T1. | same files |
| T3 | `HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection` `AllowTelemetry`=0 | Y | Y | Y | Y | **4** | - | E | 32-bit view. | same files |
| T4 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection` `MaxTelemetryAllowed`=0 | Y | - | - | - | 1 | - | E* | | A/…/disallow-data-collection.yml |
| T5 | `HKCU\SOFTWARE\Policies\Microsoft\Windows\DataCollection` `AllowTelemetry`=0 | - | Y | - | - | 1 | - | E | | R/registry/privacy/telemetry.yml |
| T6 | `HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowTelemetry` `value`=0 | - | Y | - | - | 1 | - | E* | MDM/CSP store. Revi writes it as TrustedInstaller. | R/…/telemetry.yml |
| T7 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CPSS\DevicePolicy\AllowTelemetry` `DefaultValue`=0; `…\CPSS\Store\AllowTelemetry` `Value`=0 | - | Y | - | - | 1 | - | E* | CPSS keys exist on 22H2+ only. May need TrustedInstaller (TI). Unverified. | R/…/telemetry.yml |
| T8 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection` `AllowDeviceNameInTelemetry`=0 | Y | Y | - | - | 2 | - | E | | A/…/disallow-data-collection.yml; R/…/telemetry.yml |
| T9 | same key: `AllowCommercialDataPipeline`=0, `DisableEnterpriseAuthProxy`=1, `MicrosoftEdgeDataOptIn`=0, `DisableTelemetryOptInChangeNotification`=1, `DisableTelemetryOptInSettingsUx`=1, `LimitEnhancedDiagnosticDataWindowsAnalytics`=0, `LimitDiagnosticLogCollection`=1, `LimitDumpCollection`=1 | - | Y | - | - | 1 | - | E | `DisableTelemetryOptInSettingsUx` greys out the Diagnostics page. | R/…/telemetry.yml |
| T10 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack` `ShowedToastAtLevel`=1 | Y | - | - | - | 1 | - | E* | Suppresses the diagnostic-level toast. | A/…/disallow-data-collection.yml |
| T11 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack\EventTranscriptKey` `EnableEventTranscript`=0 | Y | Y | - | - | 2 | - | E* | Turns off the local Diagnostic Data Viewer store. | A/…/disallow-data-collection.yml; R/registry/explorer/win-settings.yml |
| T12 | same key `MiniTraceSlotEnabled`=0 | Y | - | - | - | 1 | - | E* | | A/…/disallow-data-collection.yml |
| T13 | Autologger DiagTrack listener `Start`=0 | ~ | ~ | ~ | ~ | **4** | - | E* | **Key names differ:** A uses `HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Diagtrack-Listener`; R uses `HKLM\SYSTEM\ControlSet001\Control\WMI\Autologger\Diagtrack-Listener`; P and 10 use `HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener`. **Check which key exists in the VM.** | A/…/disallow-data-collection.yml; R/…/telemetry.yml; P/regedits.yml; M/regedits.yml |
| T14 | `HKLM\SYSTEM\…\Control\WMI\Autologger\SQMLogger` `Start`=0 | - | Y | Y | Y | **3** | - | E* | | R/…/telemetry.yml; P/regedits.yml; M/regedits.yml |
| T15 | `HKLM\SYSTEM\ControlSet001\Control\WMI\Autologger\SetupPlatformTel` `Start`=0 | - | Y | - | - | 1 | - | E* | | R/…/telemetry.yml |
| T16 | Delete DiagTrack ETL logs: `%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\DiagTrack*` and `…\ShutdownLogger\DiagTrack*` | Y | - | Y | Y | **3** | - | H (logs only, harmless) | A uses `!cmd del`. P and 10 use `!file` on specific `.etl` paths. | A/…/disallow-data-collection.yml; P/files.yml; M/files.yml |
| T17 | Stop DiagTrack before editing (`!service stop`) | Y | - | - | - | 1 | - | - | Atlas uses `ignoreErrors`. We would use `errorAction`. | A/…/disallow-data-collection.yml |
| T18 | `HKLM\SYSTEM\CurrentControlSet\Control\Diagnostics\Performance` `DisableDiagnosticTracing`=1 | Y | - | - | - | 1 | - | E | | A/tweaks/privacy/telemetry/disable-diagnostic-tracing.yml |
| T19 | PerfTrack: `HKLM\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}` `ScenarioExecutionEnabled`=0 | Y | - | - | - | 1 | - | E | | A/tweaks/privacy/disable-perf-track.yml |
| T20 | Experimentation off: A `HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation` `Value`=0; R `HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\System` `AllowExperimentation`=0 | Y | ~ | - | - | 2 | - | E* | Different PolicyManager branches. | A/tweaks/privacy/disable-experimentation.yml; R/…/telemetry.yml |
| T21 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds` `EnableConfigFlighting`=0 (A also `EnableExperimentation`=0) | Y | Y | - | - | 2 | - | E | "If disabled, all experimentations turned off" (Revi comment). | A/tweaks/qol/windows-update/disable-insider.yml; R/…/telemetry.yml |
| T22 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds` `AllowBuildPreview`=0 (R also writes it under `…\DataCollection`) | Y | Y | - | - | 2 | - | E | Blocks the Insider program. | A/…/disable-insider.yml; R/registry/updates/updates.yml; R/…/telemetry.yml |
| T23 | `HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform` `NoGenTicket`=1 (R also HKCU) | Y | Y | Y | Y | **4** | - | E | Disables KMS client online AVS validation. Activation itself is unaffected. | A/tweaks/privacy/telemetry/disable-activation-telemetry.yml; R/registry/privacy/privacy.yml; P/regedits.yml; M/regedits.yml |
| T24 | `HKLM\SOFTWARE\Policies\Microsoft\DeviceHealthAttestationService` `EnableDeviceHealthAttestationService`=0 | Y | - | - | - | 1 | - | E | Breaks MDM/Intune compliance (DHA). Irrelevant on home PCs. | A/tweaks/privacy/disable-device-monitoring.yml |
| T25 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\System` `RSoPLogging`=0 | Y | Y | - | - | 2 | - | E | `gpresult` loses detail. | A/tweaks/privacy/disable-rsop-logging.yml; R/registry/misc/disable-logging.yml |
| T26 | Diagnostic event logs off: `wevtutil set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false`, the same for `Microsoft-Windows-Kernel-Processor-Power/Diagnostic` and `Microsoft-Windows-UserModePowerService/Diagnostic` | Y | ~ | - | - | 2 | - | M | R runs `wevtutil sl … /q:false` instead of `/e:false`. That may not disable the logs. Unverified. | A/tweaks/performance/disable-sleep-study.yml; RX/FINALIZE.cmd |

## 2. Services (privacy-relevant only)

Startup values: 2 = Automatic, 3 = Manual, 4 = Disabled.

| # | Service | A | R | P | 10 | Cnt | Gate | Rev | Notes / risk | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| SV1 | `DiagTrack` (Connected User Experiences and Telemetry) | Y (4) | Y (4) | ~ delete | ~ delete | **4** | - | A/R: M. P/10: H | P/10 also delete `diagtrack.dll` (see §4). MS guidance: "OK to disable". | A/atlas/services.yml; R/services.yml; P/services.yml; M/services.yml |
| SV2 | `diagnosticshub.standardcollector.service` | Y (4) | Y (4) | S | S | **4** (2 persistent) | - | M | Breaks the Visual Studio diagnostics hub and profiling. | same |
| SV3 | `WerSvc` (Windows Error Reporting) | Y (4) | Y (4) | - | - | 2 | - | M | | A/atlas/services.yml; R/services.yml |
| SV4 | `wercplsupport` (Problem Reports control panel) | Y (4) | - | - | - | 1 | - | M | | A/atlas/services.yml |
| SV5 | `PcaSvc` (Program Compatibility Assistant) | Y (4) | Y (4) | - | - | 2 | - | M | Old-app compatibility prompts stop appearing. | A/atlas/services.yml; R/services.yml |
| SV6 | `dmwappushservice` (WAP push, used by telemetry) | - | - | S | S | 2 | - | - | Stop only. | P/services.yml; M/services.yml |
| SV7 | `TrkWks` (Distributed Link Tracking Client) | Y (4) | - | S | S | **3** (1 persistent) | - | M | Shortcuts to moved files on NTFS shares may break. | A/atlas/services.yml; P/services.yml |
| SV8 | `OneSyncSvc` (and per-user `OneSyncSvc_*`) | Y (4) | - | ~ delete `OneSyncSvc*` | ~ delete | **3** | - | A: M. P/10: H | **Breaks Mail/Calendar/People sync and MS account settings sync.** | A/atlas/services.yml; P/components.yml; M/components.yml |
| SV9 | `wisvc` (Windows Insider) | - | Y (4) | ~ delete | ~ delete | **3** | - | M / H | R notes that blocking wisvc in the firewall breaks Xbox. Disabling is fine. | R/services.yml; P/services.yml |
| SV10 | `WdiServiceHost`, `WdiSystemHost` (Diagnostic Service/System Host) | - | Y (4) | - | - | 1 | - | M | **Breaks the network troubleshooter, the SRUM-based app history and diagnostics.** | R/services.yml |
| SV11 | `Telemetry` (Intel(R) Telemetry Service, driver) | Y (4) | Y (4) | - | - | 2 | - | M | Exists only on Intel systems with that driver. Use `errorAction: Ignore`. | A/atlas/services.yml; R/services.yml |
| SV12 | `lfsvc` (Geolocation) | Y (4, via script) | - | S + rehost | S | **3** (1 persistent) | - | M | P also rehosts lfsvc into firewall-blocked `amehost.exe` (see FW5). **Breaks location for all apps and Find My Device.** | AD/3. General Configuration/Location/Disable Location (default).cmd; P/services.yml; PX/SERVICE.bat |
| SV13 | `MapsBroker` (Downloaded Maps Manager) | Y (4, via script) | - | S | S | **3** (1 persistent) | - | M | | same |
| SV14 | `DoSvc` (Delivery Optimization) | - | - | ~ delete | ~ delete | 2 | - | H | **Deleting DoSvc breaks Store downloads and Windows Update.** A and R use the DO policy instead (§19). | P/services.yml; M/services.yml |
| SV15 | `cloudidsvc`, `UevAgentService` | - | - | ~ delete | ~ delete | 2 | - | H | Microsoft Cloud Identity / UE-V. | P/services.yml |
| SV16 | `WpcMonSvc` (Parental controls) | - | - | ~ delete | ~ delete | 2 | - | H | Family Safety stops working. | P/services.yml |
| SV17 | `RetailDemo`, `RemoteRegistry` | - | - | S | S | 2 | - | - | Stop only. | P/services.yml |
| SV18 | `WSAIFabricSvc` (Windows AI Fabric) | - | - | ~ delete | - | 1 | - | H | 24H2+ AI stack (see §10). | P/components.yml |
| SV19 | `UCPD` (User Choice Protection Driver) and task `\Microsoft\Windows\AppxDeploymentClient\UCPD velocity` | Y (4) | Y (4) | - | - | 2 | - | M | Lets tools change default browser/PDF associations. **Phase 3 stance item (UCPD).** Reduces protection against hijacking of file associations. | A/atlas/services.yml; A/tweaks/debloat/disable-scheduled-tasks.yml; R/services.yml |
| SV20 | `Wecsvc` (Windows Event Collector) | - | Y (4) | - | - | 1 | - | M | | R/services.yml |
| SV21 | `WMPNetworkSvc` | - | - | ~ delete | ~ delete | 2 | - | H | WMP network sharing. | P/services.yml |
| SV22 | `WbioSrvc` (Windows Biometric) | - | - | S | S | 2 | - | - | **Stopping it breaks Windows Hello face/fingerprint until reboot.** | P/services.yml |
| SV23 | `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc` | - | - | S | S | 2 | - | - | Stop only. | P/services.yml |
| SV24 | `edgeupdate` → Manual (3) (R). P/10 **delete** `edgeupdate` and `edgeupdatem` | - | ~ (3) | ~ delete | ~ delete | **3** | R -, P/10 - | M / H | R notes that disabling edgeupdate breaks WebView2 install via Visual Studio. | R/services.yml; P/components.yml |
| SV25 | `CryptSvc` ImagePath → `%SystemRoot%\System32\amehost.exe -k NetworkService -p` (`amehost.exe` = copy of svchost, firewall-blocked) | - | - | Y | Y | 2 | - | E* + H | **High risk.** Blocks CRL/OCSP checks and root-certificate auto-update. Signature checks on new certs and TLS to services that rely on them can fail. | PX/SERVICE.bat; MX/SERVICE.bat |

Not privacy-related (listed for completeness, out of scope): P/10 also stop `BITS`, `iphlpsvc`, `Winmgmt`, `ClipSVC`,
`LicenseManager`, `NetTcpPortSharing`, `RemoteAccess` and `SharedAccess`, and delete the Windows Update and Defender services.
R disables `dam`, `GpuEnergyDrv`, `NetBT` and `tcpipreg`.

## 3. Scheduled tasks

| # | Task path | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| ST1 | `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator` | Y dis | Y dis | ~ del | ~ del | **4** | - | M / H | | A/tweaks/debloat/disable-scheduled-tasks.yml; RX/FINALIZE.cmd (`schtasks /change /disable`); P/files.yml; M/files.yml |
| ST2 | `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip` | Y dis | Y dis | ~ del | ~ del | **4** | - | M / H | P lists it twice. | same |
| ST3 | `\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask` | - | Y dis | ~ del | ~ del | **3** | - | M / H | May not exist on 11. Use `errorAction: Ignore`. | RX/FINALIZE.cmd; P/files.yml |
| ST4 | `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser` | ~ (component removed) | Y dis | ~ del | ~ del | **4** | - | M / H / X | A removes `Microsoft-Windows-Compat-Appraiser*` through the NoTelemetry CBS package (§4). | RX/FINALIZE.cmd; P/files.yml; atlas/src/sxsc/Atlas-NoTelemetry.yaml |
| ST5 | `\Microsoft\Windows\Application Experience\ProgramDataUpdater` | - | - | ~ del | ~ del | 2 | - | H | | P/files.yml |
| ST6 | `\Microsoft\Windows\Application Experience\StartupAppTask` | - | - | ~ del | ~ del | 2 | - | H | Breaks startup-impact ratings in Task Manager. | P/files.yml |
| ST7 | `\Microsoft\Windows\Application Experience\AitAgent` | - | Y dis | - | - | 1 | - | M | Legacy. Probably absent on 11. | RX/FINALIZE.cmd |
| ST8 | `\Microsoft\Windows\Application Experience\PcaPatchDbTask` | Y dis | - | - | - | 1 | - | M | | A/…/disable-scheduled-tasks.yml |
| ST9 | `\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector` | Y dis | Y dis | - | - | 2 | - | M | | A/…; RX/FINALIZE.cmd |
| ST10 | `\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting` and delete `HKLM\System\CurrentControlSet\Control\Ubpm` value `CriticalMaintenance_UsageDataReporting` | Y | - | - | - | 1 | - | M + E* | A/B-testing usage reports. | A/…/disable-scheduled-tasks.yml |
| ST11 | `\Microsoft\Windows\Windows Error Reporting\QueueReporting` | - | Y dis | - | - | 1 | - | M | | RX/FINALIZE.cmd |
| ST12 | `\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem` | Y dis | Y dis | - | - | 2 | - | M | | A/tweaks/performance/disable-sleep-study.yml; RX/FINALIZE.cmd |
| ST13 | `\Microsoft\Windows\Feedback\Siuf\DmClient`, `…\DmClientOnScenarioDownload` | ~ (component) | - | ~ (task file deleted) | ~ | **3** | - | H / X | P/10 delete `%windir%\System32\Tasks\Microsoft\Windows\Feedback\Siuf\*` with `!file`. That leaves the TaskCache registration behind. Prefer `!scheduledTask`. A removes `Microsoft-Windows-Feedback-DeploymentMgrClient-Desktop-TaskSch`. | P/files.yml; atlas/src/sxsc/Atlas-NoTelemetry.yaml |
| ST14 | `\Microsoft\Windows\Maps\MapsToastTask`, `\Microsoft\Windows\Maps\MapsUpdateTask` | - | - | ~ del | ~ del | 2 | - | H | | P/files.yml |
| ST15 | `\Microsoft\Windows\HelloFace\FODCleanupTask` | - | - | ~ del | ~ del | 2 | - | H | Hello face cleanup. Low value. | P/files.yml |
| ST16 | `\Microsoft\Windows\Clip\License Validation` | - | - | ~ del | ~ del | 2 | - | H | **Risk: Store app licence refresh.** | P/files.yml |
| ST17 | `\Microsoft\Windows\WindowsAI\Recall`, `\Microsoft\Windows\WindowsAI\Settings`, `\Microsoft\Windows\WindowsAI` (`deleteFolder`) | - | - | Y | - | 1 | - | H | 24H2+ only. | P/components.yml |
| ST18 | All tasks under `\Microsoft\Office\*` (`Get-ScheduledTask -TaskPath "\Microsoft\Office\*" \| Disable-ScheduledTask`) | - | Y | - | - | 1 | - | M | Includes OfficeTelemetryAgentLogOn/Fallback, **and the ClickToRun update tasks: Office stops auto-updating.** | R/final.yml |
| ST19 | OneDrive tasks (`OneDrive Reporting Task*`, `OneDrive Standalone Update Task*`) | ~ | ~ | Y | Y | **4** | A -, R opt:remove-onedrive | H | Removed with OneDrive (§9). | PX/ONED.bat; AX/ONED.cmd; RX/ONED.cmd |
| ST20 | `\MicrosoftEdge*` tasks | ~ | ~ | Y | Y | **4** | A opt:uninstall-edge, R opt:remove-edge | H | Removed with Edge (§16). | PX/EDGE.bat |

Out of scope (Windows Update): R disables `\Microsoft\Windows\WindowsUpdate\Scheduled Start`,
`\Microsoft\Windows\UpdateOrchestrator\{StartOobeAppsScanAfterUpdate, Start Oobe Expedite Work, Schedule Scan}`.
P/10 delete `UpdateOrchestrator\{Schedule Scan, Schedule Scan Static Task, UpdateModelTask, USO_UxBroker}` and `WaaSMedic\PerformRemediation`.

Gap: none of the references touch `\Microsoft\Windows\Autochk\Proxy`, `\Microsoft\Windows\Device Information\Device`
or `\Microsoft\Windows\Feedback\Siuf\*` through `!scheduledTask`. These are **unknown**. Prove them in a VM before adding them.

## 4. Component and file removal (hard to reverse)

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes / risk | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| CR1 | CBS package `Z-Atlas-NoTelemetry-Package`, installed via `packageInstall.ps1`. It supersedes these components: Feedback (StringFeedbackEngine, CourtesyEngine, DeploymentMgrClient(+TaskSch), FeedbackNotifications-Adm, Feedback-Service), InputCloudStore, Application-Experience-{AIT-Static, AppInv, Core-Inventory-Service, Inventory-Data-Sources, Mitigations-C8, Program-Data}, CodeIntegrity-Aggregator, Compat-Appraiser(+InboxDataFiles, Logger), Compat-CompatTelRunner(+DailyTask), Compat-GeneralTel, Compatibility-Aggregator, DataCollection-Adm, DeviceCensus-Schedule-ClientServer, KeyboardDiagnostic, MediaFoundationAggregator, Power-EnergyEstimationEngine-Client-Overrides, Security-PwdlessPlat-Aggregator, SetupPlatform-Telemetry-AutoLogger, SettingsHandlers-SIUF, TelemetryClient, Unified-Telemetry-Client-{Aggregators, AutoLogger-Default, Decoder-Host, Settings-WindowsClient, WoWOnly}, Update-Aggregators, PlatformTelemetryClient | Y | - | - | - | 1 | Effectively always: installed under both `opt:defender-enable` and `opt:defender-disable` | X | Revert with `AD/9. Troubleshooting/Telemetry Components.cmd` → `AX/AtlasModules/Scripts/ScriptWrappers/TelemetryComponents.ps1` (uninstalls the package). We would need our own signed CBS package build (sxsc). That is a Phase 3 decision. | A/atlas/components.yml; atlas/src/sxsc/Atlas-NoTelemetry.yaml |
| CR2 | Revision Tool `winpackage --install system-components-removal` | - | Y | - | - | 1 | - | X | **Opaque.** The contents live in the external Revision Tool binary. Contents unknown. Do not copy. | R/packages/win-sxs.yml |
| CR3 | Delete telemetry binaries: `%windir%\System32\diagtrack.dll` (+`en-US\diagtrack.dll.mui`), `%windir%\DiagTrack\{utc.allow.diffbase, analyticsevents.dat, utc.privacy.diffbase, Settings\utc.app.json, Settings\utc.tracing.json, RunExeActionAllowedList.dat, GetFileActionAllowedList.dat, GetFileInfoActionAllowedList.dat, Scenarios\windows.uif_ondemand.xml, Settings\windows.uif_ondemand.json, RemoteAggregatorTriggerCriteria.dat, Scenarios\windows.diag_ondemand.xml, Settings\telemetry.ASM-WindowsDefault.json}`, `System32\DeviceCensus.exe`, `System32\dmclient.exe`, `System32\DDFs\DMClient_DDF.xml`, `System32\omadmclient.exe`, `System32\wsqmcons.exe` (+mui), `System32\invagent.dll`, `System32\SIHClient.exe` (+mui), `System32\cloudidsvc.dll`, `System32\WpcDesktopMonSvc.dll`, `System32\IESettingSync.exe`, `System32\flightsettings.dll` (P only), `System32\MRT.exe`, `System32\msra.exe`/`msrahc.dll` (Remote Assistance), EventTracingManagement `MSFT_AutologgerConfig_v1.0.*` cmdlets, `provautologger_{add,del}.reg` | - | - | Y | Y | 2 | - | H | P also runs `SFCDEPLOY.bat` (an "SFC mitigation") so that SFC does not restore these files. **That makes repair and upgrade much harder.** Cumulative updates may also put the files back. | P/files.yml; M/files.yml; P/config.yml |
| CR4 | IFEO `Debugger`=`%windir%\System32\taskkill.exe` (REG_SZ) under `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\<exe>` for `CompatTelRunner.exe`, `AggregatorHost.exe`, `DeviceCensus.exe` | ~ (component) | Y | ~ (file delete) | ~ (file delete) | **4** (intent) | - | E (delete the IFEO key) | Reversible and update-proof. R also blocks `FeatureLoader.exe` (PC Manager), `BingChatInstaller.exe`, `BGAUpsell.exe` and `BCILauncher.exe` (Bing upsell). | R/registry/system/ifeo.yml |
| CR5 | Update Health Tools / PC Health Check: `msiexec /X{43D501A5-E5E3-46EC-8F33-9E15D2A2CBD5}` and `/X{804A0628-543B-4984-896C-F58BF6A54832}`; delete keys `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\UpdateHealthTools`, `…\rempl`, `HKLM\SOFTWARE\Microsoft\CloudManagedUpdate`; delete `%ProgramW6432%\Microsoft Update Health Tools`, `%ProgramW6432%\PCHealthCheck` | - | Y | Y | Y | **3** | - | H | Reinstalled by WU (KB4023057 family). Harmless to remove. | RX/FINALIZE.cmd; P/components.yml; PX/UPDHEALTH.bat |

## 5. Hosts-file blocking

Only **R** blocks hosts. It replaces `%WINDIR%\System32\drivers\etc\hosts` with `RX/hosts` (`copy /y`), then runs `ipconfig /flushdns` (R/start.yml).
Gate: none. Rev: E*. Keep a backup of the original hosts file. Restoring the original reverts the change.
Risk: hosts entries are ignored by some system components that use DoH or hard-coded IPs. The list also blocks
Visual Studio/VSCode telemetry and Brave P3A. R deliberately leaves `browser.events.data.microsoft.com` unblocked ("breaks Visual Studio Download page").

| Group | Hostnames (all `0.0.0.0`) |
|---|---|
| General | `browser.pipe.aria.microsoft.com`, `dmd.metaservices.microsoft.com`, `ris.api.iris.microsoft.com`, `teams.events.data.microsoft.com`, `telecommand.telemetry.microsoft.com`, `telemetry.microsoft.com`, `vortex-win.data.microsoft.com`, `watson.events.data.microsoft.com`, `activity.windows.com`, `outlookads.live.com` |
| WER | `watson.microsoft.com`, `watson.telemetry.microsoft.com`, `umwatsonc.events.data.microsoft.com`, `ceuswatcab01.blob.core.windows.net`, `ceuswatcab02.blob.core.windows.net`, `eaus2watcab01.blob.core.windows.net`, `eaus2watcab02.blob.core.windows.net`, `weus2watcab01.blob.core.windows.net`, `weus2watcab02.blob.core.windows.net` |
| DiagTrack | `events-sandbox.data.microsoft.com`, `events.data.microsoft.com`, `v10.events.data.microsoft.com`, `v20.events.data.microsoft.com`, `v10c.events.data.microsoft.com`, `v10.vortex-win.data.microsoft.com`, `eu-v10.events.data.microsoft.com`, `eu-v20.events.data.microsoft.com`, `au.vortex-win.data.microsoft.com`, `au-v10.events.data.microsoft.com`, `au-v20.events.data.microsoft.com`, `uk.vortex-win.data.microsoft.com`, `uk-v20.events.data.microsoft.com`, `us-v10.events.data.microsoft.com`, `us-v20.events.data.microsoft.com`, `us4-v20.events.data.microsoft.com`, `us5-v20.events.data.microsoft.com`, `pipe.dev.trafficmanager.net`, `in-v10.events.data.microsoft.com`, `in-v20.events.data.microsoft.com`, `jp-v10.events.data.microsoft.com`, `jp-v20.events.data.microsoft.com` |
| Brave | `p3a.brave.com`, `p2a.brave.com`, `p3a-json.brave.com`, `p2a-json.brave.com`, `cr.brave.com`, `star-randsrv.bsg.brave.com` (`laptop-updates.brave.com` and `variations.brave.com` are commented out) |
| VS/VSCode | `vortex.data.microsoft.com`, `dc.services.visualstudio.com`, `visualstudio-devdiv-c2s.msedge.net`, `az667904.vo.msecnd.net`, `scus-breeziest-in.cloudapp.net`, `nw-umwatson.events.data.microsoft.com`, `mobile.events.data.microsoft.com` |

`activity.windows.com` also serves Timeline and cross-device features. `teams.events.data.microsoft.com` is Teams telemetry.

## 6. Firewall rules (written as registry values)

All rules are written as REG_SZ values under `HKLM\SYSTEM\ControlSet001\Services\SharedAccess\…\FirewallPolicy\FirewallRules`.
They take effect after BFE/MpsSvc reload or a reboot. Rev: E (delete the value). They are useless if the Windows Firewall service is off.

| # | Rule name (value) | Data | A | R | P | 10 | Notes | Source |
|---|---|---|---|---|---|---|---|---|
| FW1 | `Block-Unified-Telemetry-Client` (under both `…\Defaults\FirewallPolicy\FirewallRules` and `…\Parameters\FirewallPolicy\FirewallRules`) | `v2.31\|Action=Block\|Active=TRUE\|Dir=Out\|RA42=IntErnet\|RA62=IntErnet\|App=%SystemRoot%\system32\svchost.exe\|Svc=DiagTrack\|Name=Block-Unified-Telemetry-Client\|Desc=Block-Unified-Telemetry-Client\|EmbedCtxt=DiagTrack\|` | - | Y | - | - | Writing under `Defaults` makes the rule survive a firewall reset. | R/registry/privacy/privacy.yml |
| FW2 | `Block-Windows-Error-Reporting` (both keys) | `v2.31\|Action=Block\|Active=TRUE\|Dir=Out\|RA42=IntErnet\|RA62=IntErnet\|App=%SystemRoot%\system32\svchost.exe\|Svc=WerSvc\|Name=Block-Unified-Error-Reporting\|Desc=Block-Windows-Error-Reporting\|EmbedCtxt=WerSvc\|` | - | Y | - | - | The Parameters copy sets `Name=Block-Unified-Telemetry-Client`, a copy-paste slip. A wisvc rule is commented out ("Breaks Xbox"). | R/…/privacy.yml |
| FW3 | `Block SearchApp` | `v2.32\|Action=Block\|Active=TRUE\|Dir=Out\|RA42=IntErnet\|RA62=IntErnet\|App=%SystemRoot%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe\|Name=Block SearchApp\|Desc=Block Cortana Outbound UDP/TCP Traffic\|` | - | - | Y | Y | Win10 search host. | P/services.yml; M/services.yml |
| FW4 | `Block SearchHost` | `…\|App=%SystemRoot%\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\SearchHost.exe\|Name=Block SearchHost\|…` | - | - | Y | Y | Win11 search host. Kills web results even if policies fail. | same |
| FW5 | `Block Services` | `…\|App=%SystemRoot%\System32\amehost.exe\|Name=Block Services\|Desc=Block Certain Services Outbound UDP/TCP Traffic\|` | - | - | Y | Y | Pairs with SV25 (CryptSvc, and lfsvc in P, rehosted). **High risk.** | same |
| FW6 | `Block StartMenuExperienceHost` | `…\|App=%SystemRoot%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe\|…` | - | - | Y | Y | Blocks Start recommendations and web content. | same |
| FW7 | `Block SystemSettings` | `…\|App=%SystemRoot%\ImmersiveControlPanel\SystemSettings.exe\|…` | - | - | Y | Y | **Settings cannot sign in to an MS account or fetch online help.** | same |
| FW8 | `Block Explorer` | `…\|App=%SystemRoot%\explorer.exe\|…` | - | - | Y | Y | **Breaks Explorer "Home" cloud items, and online `ms-` links that Explorer opens itself.** | same |
| FW9 | Disable firewall group "Remote Assistance" (`netsh advfirewall firewall set rule group="Remote Assistance" new enable=no`) | - | Y | - | - | - | Security, not privacy. | A/tweaks/security/disable-remote-assistance.yml |

Atlas has commented-out block rules for "Windows Web Experience Pack" (A/tweaks/qol/windows-update/disable-auto-updates.yml). P has a commented-out rule for the Search package.

## 7. Windows Error Reporting (WER)

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| W1 | WER disabled. Policy: `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting` `Disabled`=1. Non-policy: `HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting` `Disabled`=1 | Y (policy) | Y (both) | ~ (non-policy) | ~ (non-policy) | **4** | - | E | Crash dumps are no longer uploaded. Local dumps (`LocalDumps`) are unaffected. | A/tweaks/privacy/disable-win-error-reporting.yml; R/registry/privacy/wer.yml + privacy.yml; P/regedits.yml; M/regedits.yml |
| W2 | Policy `DontSendAdditionalData`=1 | Y | Y | Y | Y | **4** | - | E | | same |
| W3 | Policy `DontShowUI`=1 | Y | Y | - | - | 2 | - | E | | A/…; R/…/wer.yml |
| W4 | Policy `LoggingDisabled`=1 | Y | Y | - | - | 2 | - | E | | same |
| W5 | `HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting` `Disabled`=1 | Y | - | - | - | 1 | - | E | | A/… |
| W6 | `HKLM\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting` `DoReport`=0 (A also `ShowUI`=0) | Y | Y | - | - | 2 | - | E | | A/…; R/…/privacy.yml |
| W7 | `HKLM\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing` `DisableWerReporting`=1 | Y | - | - | - | 1 | - | E* | | A/… |
| W8 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings` `DisableSendGenericDriverNotFoundToWER`=1, `DisableSendRequestAdditionalSoftwareToWER`=1 | Y | - | - | - | 1 | - | E | | A/… |
| W9 | Policy `AutoApproveOSDumps`=0 | - | Y | - | - | 1 | - | E | | R/…/wer.yml |
| W10 | `HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent` `DefaultConsent`=0, `DefaultOverrideBehavior`=1; policy `…\Windows Error Reporting\Consent` value `0` (REG_SZ) = `''` | - | Y | - | - | 1 | - | E* | | R/…/wer.yml |
| W11 | `Disable-WindowsErrorReporting` (PowerShell cmdlet) | - | Y | - | - | 1 | - | E | | RX/FINALIZE.cmd |
| W12 | `HKLM\Software\Policies\Microsoft\Windows Defender\Reporting` `DisableGenericRePorts`=1 | - | Y | - | - | 1 | - | E | Defender Watson events. Writable only while Tamper Protection is off. | R/registry/security/security.yml |
| W13 | MSRT: `HKLM\SOFTWARE\Policies\Microsoft\MRT` `DontReportInfectionInformation`=1; A also sets `HKLM\SOFTWARE\Microsoft\RemovalTools\MpGears` `HeartbeatTrackingIndex`=0 and `SpyNetReportingLocation` (REG_MULTI_SZ)=`''` | Y | X (**sets 0**) | ~ (deletes MRT.exe) | ~ | 3 | - | E | **R sets `DontReportInfectionInformation`=0 under the comment "Disable … – Enabled". This looks like a bug.** Use 1. | A/tweaks/qol/windows-update/disable-msrt-telemetry.yml; R/registry/updates/updates.yml |
| W14 | Services `WerSvc`/`wercplsupport`, task `QueueReporting`, firewall FW2, hosts "WER" group | see SV3, SV4, ST11, FW2, §5 | | | | | | | | |

## 8. CEIP / SQM and application compatibility telemetry

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| C1 | `HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows` `CEIPEnable`=0 | Y | Y | - | - | 2 | - | E | | A/tweaks/privacy/telemetry/disable-ceip.yml; R/registry/privacy/ceip.yml |
| C2 | `HKLM\SOFTWARE\Policies\Microsoft\AppV\CEIP` `CEIPEnable`=0 | Y | Y | - | - | 2 | - | E | | same |
| C3 | `HKLM\Software\Policies\Microsoft\Internet Explorer\SQM` `DisableCustomerImprovementProgram`=1 | - | Y | - | - | 1 | - | E | | R/…/ceip.yml |
| C4 | `HKLM\Software\Policies\Microsoft\Messenger\Client` `CEIP`=2 | - | Y | - | - | 1 | - | E | Legacy. | R/…/ceip.yml |
| C5 | `HKLM\Software\Microsoft\Windows NT\CurrentVersion\UnattendSettings\SQMClient` `CEIPEnabled`=0 | - | Y | - | - | 1 | - | E* | | R/…/ceip.yml |
| C6 | CEIP tasks, SQMLogger, `wsqmcons.exe` | see ST1–ST3, T14, CR3 | | | | | | | | |
| AC1 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat` `AITEnable`=0 | Y | Y | - | - | 2 | - | E | Application Telemetry. | A/tweaks/privacy/disable-pca.yml; R/registry/privacy/app-compat.yml |
| AC2 | same key `DisableInventory`=1 | Y | Y | - | - | 2 | - | E | | same |
| AC3 | same key `DisablePCA`=1 | Y | Y | - | - | 2 | - | E | | same |
| AC4 | same key `DisableUAR`=1 (Steps Recorder) | Y | Y | - | - | 2 | - | E | Atlas also removes the `App.StepsRecorder~~~~0.0.1.0` capability (A/atlas/start.yml). | same |
| AC5 | same key `DisableEngine`=1 | Y | Y | - | - | 2 | - | E | **Turns off the AppCompat shim engine. Some legacy apps and games that need shims break.** Consider leaving it out. | same |
| AC6 | same key `AllowTelemetry`=0 | Y | - | - | - | 1 | - | E | | A/…/disable-pca.yml |
| AC7 | same key `SbEnable`=1 | - | ? | - | - | - | - | E | R comments "Turn off SwitchBack … – Enabled" but writes 1. The ADMX "Enabled" state writes 0. **Likely inverted; skip.** | R/…/app-compat.yml |

## 9. Cloud sync, accounts, cross-device

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes / risk | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| CS1 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync` `DisableSettingSync`=2, `DisableSettingSyncUserOverride`=1 | Y | Y | Y | Y | **4** | - | E | Settings and theme roaming via MSA stops. | A/tweaks/privacy/cloud/disable-setting-sync.yml; R/registry/explorer/win-settings.yml; P/regedits.yml; M/regedits.yml |
| CS2 | same key `DisableSyncOnPaidNetwork`=1, `DisableWindowsSettingSync`=2 | Y | Y | - | - | 2 | - | E | | A/…; R/… |
| CS3 | same key, R only: `DisableWindowsSettingSyncUserOverride`=1, `DisableApplicationSettingSync`=2 (+`…UserOverride`=1), `DisableWebBrowserSettingSync`=2 (+1), `DisableDesktopThemeSettingSync`=2 (+1), `DisableCredentialsSettingSync`=2 (+1), `DisablePersonalizationSettingSync`=2 (+1), `DisableStartLayoutSettingSync`=2 (+1) | - | Y | - | - | 1 | - | E | | R/…/win-settings.yml |
| CS4 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\{Personalization, BrowserSettings, Credentials, Accessibility, Windows}` `Enabled`=0; `HKCU\…\SettingSync` `SyncPolicy`=5 | Y | - | - | - | 1 | - | E* | | A/…/disable-setting-sync.yml |
| CS5 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging` `AllowMessageSync`=0 | Y | Y | - | - | 2 | - | E | SMS cloud backup. | A/tweaks/privacy/cloud/disallow-message-cloud-sync.yml; R/registry/privacy/privacy.yml |
| CS6 | OneDrive removal (uninstaller + leftovers) | Y | Y | Y | Y | **4** | A -, R opt:remove-onedrive (checked by default), P/10 - | H | A `AX/ONED.cmd` **skips the removal if `%USERPROFILE%\OneDrive` holds files**. Copy that safety check. R also runs `winpackage --install onedrive-removal` (opaque). P/10 delete `OneDriveSetup.exe` in System32/SysWOW64 and many `HKCU\SOFTWARE\Classes\…` OneDrive keys, and reset `User Shell Folders` to the local paths. | A/atlas/components.yml; R/packages/app-win32.yml; P/components.yml; PX/ONED.bat |
| CS7 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive` `DisableFileSyncNGSC`=1 | - | - | Y | Y | 2 | - | E | Policy-only alternative to removal. Reversible. | P/regedits.yml |
| CS8 | Block Microsoft accounts: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` `NoConnectedUser`=1 | Y | - | - | - | 1 | - | E | **Users cannot add an MSA. Store, Xbox and OneDrive sign-in for the OS account break.** R instead sets `MSAOptional`=1 (allow apps without an MSA). | A/tweaks/privacy/disallow-ms-accounts.yml; AD/3. General Configuration/Mobile Devices (Phone Link)/Disable Mobile Device Settings (default).cmd; R/registry/privacy/privacy.yml |
| CS9 | Cross-device Resume: `HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration` `IsResumeAllowed`=0; `HKLM\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume` `value`=1; `HKLM\SYSTEM\ControlSet001\Policies\Microsoft\FeatureManagement\Overrides` `1387020943`=0 | - | Y | ~ (removes `*CrossDeviceResume*` appx) | - | 2 | R opt:remove-appx-yourphone | E / H | Feature override IDs are build-specific (24H2+). | R/…/win-settings.yml; P/appx.yml |
| CS10 | Nearby sharing / shared experiences: `HKCU\Software\Microsoft\Windows\CurrentVersion\CDP` `CdpSessionUserAuthzPolicy`=1, `NearShareChannelUserAuthzPolicy`=0; `…\CDP\SettingsPage` `BluetoothLastDisabledNearShare`=0 | Y | - | - | - | 1 | - | E* | | A/tweaks/qol/shell/disable-nearby-sharing.yml |
| CS11 | Phone Link: hide `mobile-devices` Settings page (A); remove `Microsoft.YourPhone` appx (R opt, P, 10) | ~ | Y | Y | Y | **4** | R opt:remove-appx-yourphone | E / H | | AD/…/Phone Link…; R/packages/appx.yml; P/appx.yml |
| CS12 | Clipboard: `HKCU\Software\Microsoft\Clipboard` `EnableClipboardHistory`=0 (policies `AllowClipboardHistory`=1 and `AllowCrossDeviceClipboard`=1 are kept explicitly) | - | Y | - | - | 1 | - | E* | Win+V history starts off but the user can turn it on. | R/…/win-settings.yml |
| CS13 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced` `ShowSyncProviderNotifications`=0 | Y | - | - | - | 1 | - | E* | OneDrive ads in Explorer. | A/tweaks/privacy/advertising/disable-sync-provider-notifs.yml |
| CS14 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer` `DisableGraphRecentItems`=1 | - | Y | - | - | 1 | - | E | Explorer Home no longer shows OneDrive/Graph "recommended" items. | R/registry/explorer/explorer.yml |
| CS15 | Remove `*WindowsBackup*` (app), `*CloudExperienceHost*` appx | - | - | Y | Y | 2 | - | H | **Removing CloudExperienceHost breaks OOBE and MSA sign-in flows.** | P/appx.yml |

## 10. Copilot, Recall and AI features (Win11; mostly 24H2/26100+)

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes / risk | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| AI1 | `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot` `TurnOffWindowsCopilot`=1 | Y | - | Y | - | 3* | A b>=22000 | E | Atlas notes "Doesn't work with HKLM". P writes both hives. | A/tweaks/qol/taskbar/disable-copilot.yml; AD/3. General Configuration/AI Features/Microsoft Copilot/Disable Microsoft Copilot (default).cmd; P/components.yml |
| AI2 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot` `TurnOffWindowsCopilot`=1 | - | - | Y | Y | 2 | - | E | | P/regedits.yml; P/components.yml; M/regedits.yml |
| AI3 | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` `ShowCopilotButton`=0 | Y | - | Y | Y | **3** | - | E* | | AD/…/Disable Microsoft Copilot (default).cmd; P/regedits.yml; M/regedits.yml |
| AI4 | Remove the Copilot app: A `Microsoft.Copilot*`; R `Microsoft.Copilot`; P `*Microsoft.Copilot*`, `*Microsoft.Windows.Copilot*`, `*Client.CoPilot*`, `*Ai.Copilot*` | Y | Y | Y | - | 3* | R opt:remove-winsxs-ai (checked by default) | H (reinstall from Store) | | A/atlas/appx.yml; R/packages/app-win32.yml; P/components.yml |
| AI5 | Recall: `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI` `DisableAIDataAnalysis`=1 | Y | Y | Y (HKLM+HKCU) | - | 3* | A b>=22000 | E | A applies it via a script (`!cmd … /silent`, `wait: true`). We can use a plain `!registryValue`. | A/tweaks/privacy/disable-recall-snap.yml; AD/3. General Configuration/AI Features/Recall/Disable Recall Support (default).cmd; R/registry/explorer/win-settings.yml; P/components.yml |
| AI6 | `…\WindowsAI` (HKLM+HKCU) `AllowRecallEnablement`=0, `DisableClickToDo`=1, `TurnOffSavingSnapshots`=1, `DisableSettingsAgent`=1 | - | - | Y | - | 1 | - | E | `AllowRecallEnablement`=0 removes the Recall optional component on 24H2 Copilot+ PCs. The reverse direction is unverified. | P/components.yml |
| AI7 | `HKLM\SOFTWARE\Microsoft\Windows\Shell\Copilot` (and HKCU) `IsCopilotAvailable`=0, `CopilotDisabledReason`=`FeatureIsDisabled` (REG_SZ); `…\Shell\Copilot\BingChat` `IsUserEligible`=0 | - | - | Y | - | 1 | - | E* | Undocumented shell keys. | P/components.yml |
| AI8 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsCopilot` `AllowCopilotRuntime`=0 | - | - | Y | - | 1 | - | E* | | P/components.yml |
| AI9 | Generative-AI app access: `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy` `LetAppsAccessGenerativeAI`=2, `LetAppsAccessSystemAIModels`=2; `HKLM\…\CapabilityAccessManager\ConsentStore\generativeAI` `Value`=`Deny` (REG_SZ) | - | - | Y | - | 1 | - | E | 2 = Force Deny. | P/components.yml |
| AI10 | Notepad AI: `HKLM\SOFTWARE\Policies\WindowsNotepad` `DisableAIFeatures`=1 | - | - | Y | - | 1 | - | E | | P/regedits.yml |
| AI11 | Paint AI: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint` `DisableImageCreator`=1, `DisableCocreator`=1, `DisableGenerativeFill`=1, `DisableGenerativeErase`=1, `DisableRemoveBackground`=1 | - | - | Y | - | 1 | - | E | | P/components.yml |
| AI12 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings` `AutoOpenCopilotLargeScreens`=0 | - | - | Y | - | 1 | - | E* | | P/components.yml |
| AI13 | Remove AI appx: `*MicrosoftWindows.Client.AIX*`, `*Client.CoreAI*`; kill `ai.exe`, `Copilot.exe`, `aihost.exe`, `aicontext.exe`, `ClickToDo.exe`, `aixhost.exe`, `WorkloadsSessionHost.exe` | - | - | Y | - | 1 | - | H | **System packages. Click to Do and AI Settings agent stop working. Risk to CBS servicing.** | P/components.yml |
| AI14 | Delete protocol handlers `HKCR\ms-office-ai`, `HKCR\ms-copilot` | - | - | Y | - | 1 | - | H (keys) | | P/components.yml |
| AI15 | Gaming Copilot: `HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.Xbox.GamingAI.Companion.Host.GamingCompanionHostOptions` `ActivationType`=4294967295, `Server` (REG_SZ)=`''` | - | Y | - | - | 1 | - | E* (needs TI) | | R/registry/privacy/privacy.yml |
| AI16 | Revision Tool `winpackage --install ai-removal` | - | Y | - | - | 1 | R opt:remove-winsxs-ai | X | **Opaque.** | R/packages/win-sxs.yml |
| AI17 | IFEO taskkill on `BingChatInstaller.exe`, `BGAUpsell.exe`, `BCILauncher.exe` | - | Y | - | - | 1 | - | E | Bing/Copilot upsell installers. | R/registry/system/ifeo.yml |
| AI18 | WindowsAI task folders, `WSAIFabricSvc` | see ST17, SV18 | | | | | | | | |
| AI19 | Hide the `aicomponents` Settings page (in `SettingsPageVisibility`) | - | - | Y | - | 1 | - | E | | P/regedits.yml |

## 11. Advertising ID, tailored experiences, suggestions

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| AD1 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo` `Enabled`=0 | Y | Y | Y | Y | **4** | - | E* | | A/tweaks/privacy/advertising/disable-advertising-info.yml; R/registry/explorer/win-settings.yml; P/regedits.yml; M/regedits.yml |
| AD2 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo` `DisabledByGroupPolicy`=1 | Y | Y | Y | Y | **4** | - | E | | same |
| AD3 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo` `Enabled`=0; delete value `Id` in HKCU and HKLM `…\AdvertisingInfo` | - | Y | - | - | 1 | - | E* | Deleting `Id` resets the ID. Windows regenerates it if re-enabled. | R/…/win-settings.yml |
| AD4 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy` `TailoredExperiencesWithDiagnosticDataEnabled`=0 | Y | Y | - | - | 2 | - | E* | R also `HKLM\…\CPSS\DevicePolicy\TailoredExperiencesWithDiagnosticDataEnabled` `DefaultValue`=0. | A/tweaks/privacy/disable-tailored-experiences.yml; R/…/win-settings.yml |
| AD5 | `HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent` `DisableTailoredExperiencesWithDiagnosticData`=1 (R also HKLM) | Y | Y | - | - | 2 | - | E | | A/…; R/registry/privacy/cloud-content.yml |
| AD6 | `HKCU\Control Panel\International\User Profile` `HttpAcceptLanguageOptOut`=1 | Y | Y | Y | Y | **4** | - | E* | Websites no longer see the language list (anti-fingerprinting). | A/tweaks/privacy/disable-web-lang-list-access.yml; R/…/win-settings.yml; P/regedits.yml; M/regedits.yml |
| AD7 | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` `Start_IrisRecommendations`=0 | Y | Y | Y | Y | **4** | A b>=22000 | E* | Start "Recommended" tips and ads. | A/tweaks/qol/shell/no-recommendations-start-menu.yml; R/registry/explorer/explorer.yml; P/regedits.yml; M/regedits.yml |
| AD8 | same key `Start_AccountNotifications`=0 | Y | Y | Y | Y | **4** | - | E* | | same |
| AD9 | `HKCU\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications` `EnableAccountNotifications` | Y (=0) | X (=1) | - | - | 1 | - | E* | **Conflict:** R's comment says "Off" but it writes 1. Use 0. | A/tweaks/debloat/config-content-delivery.yml; R/…/win-settings.yml |
| AD10 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement` `ScoobeSystemSettingEnabled`=0 ("Let's finish setting up") | Y | Y | - | - | 2 | - | E* | R also `HKCU\…\ContentDeliveryManager\Context\CloudExperienceHostIntent\Wireless` `ScoobeCheckCompleted`=1. | A/tweaks/privacy/cloud/disable-suggest-ways-to-finish-setup.yml; R/registry/explorer/notifications.yml |
| AD11 | Online tips: `HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowOnlineTips` `value`=0; `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` `AllowOnlineTips`=0 | Y | - | - | - | 1 | - | E | | A/tweaks/qol/disable-settings-tips.yml |
| AD12 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI` `DisableHelpSticker`=1; `HKCU\Software\Policies\Microsoft\Windows\EdgeUI` `DisableMFUTracking`=1 | - | Y | - | - | 1 | - | E | "EdgeUI" means screen-edge UI, not the Edge browser. | R/registry/privacy/privacy.yml |
| AD13 | Remove `Microsoft.Advertising` appx | - | Y | - | - | 1 | - | H | | R/packages/appx.yml |
| AD14 | `HKCU\Software\Policies\Microsoft\Windows\Explorer` `NoBalloonFeatureAdvertisements`=1 | - | Y | - | - | 1 | - | E | | R/registry/explorer/notifications.yml |
| AD15 | Settings "Home"/value banner: `HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\ValueBanner.IdealStateFeatureControlProvider` `ActivationType` (A=0, R=4294967295, R also `Server`=`''`) | ~ | ~ | ~ (removes `*Global.ValueBanner*` app) | - | 3* | A b>=22000 | E* (needs TI) | A and R disagree on the value. 4294967295 (0xFFFFFFFF) is the stronger block. | A/tweaks/qol/disable-win11-settings-banner.yml; R/…/win-settings.yml; P/appx.yml |

## 12. Content Delivery Manager, Spotlight, cloud content

All CDM values are under `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager` (REG_DWORD, 0 = off). Rev E*.

| # | Value(s) =0 | A | R | P | 10 | Cnt | Notes | Source |
|---|---|---|---|---|---|---|---|---|
| CD1 | `ContentDeliveryAllowed` | Y | Y | Y | Y | **4** | | A/tweaks/debloat/config-content-delivery.yml; R/registry/privacy/cdm.yml; P/regedits.yml; M/regedits.yml |
| CD2 | `SubscribedContent-310093Enabled` (welcome experience) | Y | Y | Y | Y | **4** | | same |
| CD3 | `SubscribedContent-338393Enabled`, `SubscribedContent-353694Enabled`, `SubscribedContent-353696Enabled` (Settings suggestions) | Y | - | Y | Y | **3** | | A/…; P/…; M/… |
| CD4 | `SubscribedContentEnabled` | Y | Y | - | - | 2 | | A/…; R/… |
| CD5 | `SilentInstalledAppsEnabled`, `PreInstalledAppsEnabled`, `PreInstalledAppsEverEnabled`, `OemPreInstalledAppsEnabled` | Y | Y | - | - | 2 | Stops auto-installs of "suggested" apps. | A/…; R/… |
| CD6 | `FeatureManagementEnabled`, `RemediationRequired` | Y | Y | - | - | 2 | Stops CDM from reverting these settings. | A/…; R/… |
| CD7 | `SoftLandingEnabled`, `SubscribedContent-338389Enabled` (tips) | Y | Y | - | - | 2 | | A/…; R/… |
| CD8 | `SubscribedContent-338388Enabled` (Start suggestions), `SystemPaneSuggestionsEnabled` | Y | Y | - | - | 2 | | A/…; R/…/win-settings.yml |
| CD9 | `SubscribedContent-338387Enabled`, `RotatingLockScreenOverlayEnabled` (lock-screen facts) | Y | Y | - | - | 2 | R also `RotatingLockScreenEnabled`=0. | A/…; R/…/cdm.yml |
| CD10 | `SubscribedContent-314559Enabled`, `-280815Enabled`, `-314563Enabled` (My People), `-202914Enabled`, `-280810Enabled` (OneDrive SyncProviders), `-280811Enabled` (OneDrive), `-353698Enabled` (Timeline suggestions) | - | Y | - | - | 1 | | R/…/cdm.yml; R/…/win-settings.yml |
| CD11 | **Delete keys** `…\ContentDeliveryManager\Subscriptions` and `…\ContentDeliveryManager\SuggestedApps` | - | Y | - | - | 1 | Atlas comments these out: "would likely break re-enabling content". Rev H. | R/…/cdm.yml |
| CD12 | Remove the `*ContentDeliveryManager*` appx | - | - | Y | Y | 2 | **H. Spotlight and lock-screen rotation stop working.** | P/appx.yml |

Cloud-content policies:

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| CC1 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent` `DisableCloudOptimizedContent`=1 | Y | Y | Y | Y | **4** | - | E | P: "Prevents Outlook from getting pinned in 24H2". Atlas: "seems to break Windows Spotlight". | A/tweaks/qol/taskbar/disable-cloud-optimized-content.yml; R/registry/privacy/cloud-content.yml; P/regedits.yml; M/regedits.yml |
| CC2 | same key `DisableSoftLanding`=1 | Y | Y | - | - | 2 | - | E | | A/tweaks/qol/disable-tips.yml; R/… |
| CC3 | `HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent` `DisableWindowsSpotlightFeatures`=1, `DisableWindowsSpotlightWindowsWelcomeExperience`=1, `DisableWindowsSpotlightOnActionCenter`=1, `DisableWindowsSpotlightOnSettings`=1, `DisableThirdPartySuggestions`=1 | Y | Y | - | - | 2 | - | E | | A/tweaks/qol/disable-windows-spotlight.yml; AD/3. General Configuration/Windows Spotlight/Disable Windows Spotlight (default).cmd; R/… |
| CC4 | same HKCU key `ConfigureWindowsSpotlight`=2, `IncludeEnterpriseSpotlight`=0 | - | Y | - | - | 1 | - | E | | R/… |
| CC5 | Spotlight desktop icon: `…\Explorer\HideDesktopIcons\NewStartPanel` `{2cc5ca98-6485-489a-920e-b3e88a6ccce3}`=1 (A HKCU, R HKLM) | Y | Y | ~ (removes `*Global.DesktopSpotlight*` app) | - | 3* | - | E* | **Typo in A's YAML: the key is `NewStartPanelt`.** The default script has the correct name. 24H2. | A/tweaks/qol/disable-windows-spotlight.yml; R/registry/explorer/explorer.yml; P/appx.yml |
| CC6 | `DisableWindowsConsumerFeatures` | - | - | - | - | 0 | - | - | **Deliberately not set.** R: "Breaks Your Phone". A's re-enable script deletes it. | R/…/cloud-content.yml (comment) |
| CC7 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications` `NoCloudApplicationNotification`=1 | - | Y | - | - | 1 | - | E | **Blocks WNS cloud toasts. Mail, Teams and Store app notifications stop.** | R/registry/explorer/notifications.yml |
| CC8 | Ink Workspace suggestions: A `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace` `PenWorkspaceAppSuggestionsEnabled`=0; R `HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace` `AllowSuggestedAppsInWindowsInkWorkspace`=0 | Y | Y | - | - | 2 | - | E | | A/tweaks/qol/config-windows-ink-workspace.yml; R/registry/explorer/explorer.yml |

## 13. Activity history, timeline, recent items, usage tracking

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes / risk | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| AH1 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\System` `EnableActivityFeed`=0 | Y | Y | Y | Y | **4** | - | E | | A/tweaks/privacy/disable-activity-feed.yml; R/registry/explorer/win-settings.yml; P/regedits.yml; M/regedits.yml |
| AH2 | same key `PublishUserActivities`=0 | Y | Y | - | - | 2 | - | E | | A/tweaks/privacy/disallow-user-activity-upload.yml; R/… |
| AH3 | same key `UploadUserActivities`=0 | Y | Y | - | - | 2 | - | E | | same |
| AH4 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced` `Start_TrackProgs`=0 | Y | - (commented out) | - | - | 1 | - | E* | Start "most used" list disappears. | A/tweaks/privacy/disable-app-launch-tracking.yml |
| AH5 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` `NoInstrumentation`=1 | Y | - | - | - | 1 | - | E | **Also disables UserAssist and some shell usage tracking. Start "most used" breaks.** | A/tweaks/privacy/disable-user-tracking.yml |
| AH6 | Recent documents: HKCU `…\Policies\Explorer` `NoRecentDocsHistory`=1, `ClearRecentDocsOnExit`=1; HKLM `…\Policies\Explorer` `NoRecentDocsHistory`=1; `HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer` `NoRemoteDestinations`=1; HKCU `…\Explorer\Advanced` `Start_TrackDocs`=0; HKCU `…\Explorer` `ShowFrequent`=0, `ShowRecent`=0 | Y | - | ~ | ~ | **3** | - | E | **Jump lists and Recent in Explorer/Office stop working.** QoL cost. P/10 only set `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Start` `ShowFrequentList`=0, `ShowRecentList`=0. | A/tweaks/qol/explorer/hide-frequently-used-items.yml; AD/4. Interface Tweaks/Unlock Recent Items/Disable Recent Items (default).cmd; P/regedits.yml |
| AH7 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` `NoStartMenuMFUprogramsList`=1; `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer` `ShowOrHideMostUsedApps`=1, `HideRecentlyAddedApps`=1 | Y | - | - | - | 1 | - | E | Check `ShowOrHideMostUsedApps` semantics (1 = show, 2 = hide?) in the VM. | AD/…/Disable Recent Items (default).cmd |
| AH8 | `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer` `NoResolveSearch`=1, `LinkResolveIgnoreLinkInfo`=1 | - | Y | - | - | 1 | - | E | Shell shortcut tracking. | R/registry/explorer/start-menu.yml; R/registry/explorer/explorer.yml |
| AH9 | `TrkWks` | see SV7 | | | | | | | | |

## 14. Search, Bing, Cortana

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| S1 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search` `DisableWebSearch`=1 | Y | Y | Y | Y | **4** | - | E | | A/tweaks/privacy/search-settings.yml; R/registry/explorer/search.yml; P/regedits.yml; M/regedits.yml |
| S2 | same key `ConnectedSearchUseWeb`=0 | Y | Y | Y | Y | **4** | - | E | | same |
| S3 | same key `AllowSearchToUseLocation`=0 | Y | Y | Y | Y | **4** | - | E | P/10 also set HKCU `…\CurrentVersion\Search` `AllowSearchToUseLocation`=0. | same |
| S4 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search` `BingSearchEnabled`=0 | Y | Y | Y | Y | **4** | - | E* | | same |
| S5 | `HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer` `DisableSearchBoxSuggestions`=1 | Y | Y | Y | Y | **4** | - | E | The main switch that kills Bing in Start on 11. Also hides recent search entries in Explorer. | same; P/components.yml |
| S6 | same Search policy key `ConnectedSearchUseWebOverMeteredConnections`=0 | - | Y | Y | Y | **3** | - | E | | R/…; P/…; M/… |
| S7 | `HKCU\…\CurrentVersion\Search` `CortanaConsent`=0 | - | Y | Y | Y | **3** | - | E* | | same |
| S8 | `HKLM\SOFTWARE\Microsoft\Speech_OneCore\Preferences` `VoiceActivationEnableAboveLockscreen`=0 | - | Y | Y | Y | **3** | - | E* | | same |
| S9 | `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings` `SafeSearchMode`=0 | Y | - | Y | Y | **3** | - | E* | Turns SafeSearch **off** (not a privacy gain; avoids web filtering). | A/…; P/…; M/… |
| S10 | Search policy key `AllowCortana` | - | X (=1) | Y (=0) | Y (=0) | 2 | - | E | **Conflict:** R's comment says "Disabled" but it writes 1. | R/…; P/…; M/… |
| S11 | Search policy key `AllowCloudSearch` | - | ~ (=2) | Y (=0) | Y (=0) | **3** | - | E | 0 = blocks MSA/AAD cloud content in search. R picks 2. | same |
| S12 | Search policy key `AllowCortanaAboveLock`=0, `AllowCortanaInAAD`=0, `AllowCortanaInAADPathOOBE`=0, `ConnectedSearchPrivacy`=3, `PreventIndexOnBattery`=1 | - | Y | - | - | 1 | - | E | | R/… |
| S13 | `HKCU\…\SearchSettings` `IsAADCloudSearchEnabled`=0, `IsMSACloudSearchEnabled`=0, `IsDeviceSearchHistoryEnabled`=0 | Y | - | - | - | 1 | - | E* | User-level equivalent of S11. | A/… |
| S14 | Search highlights: Search policy key `EnableDynamicContentInWSB`=0; HKCU `…\SearchSettings` `IsDynamicSearchBoxEnabled`=0 | Y | - | - | - | 1 | - | E | | A/…; AD/3. General Configuration/Web Search (includes Search Highlights)/Disable Web Search (default).cmd |
| S15 | HKCU `…\CurrentVersion\Search` `CortanaInAmbientMode`=0, `HistoryViewEnabled`=0, `HasAboveLockTips`=0 | - | - | Y | Y | 2 | - | E* | | P/…; M/… |
| S16 | Search policy key `AllowIndexingEncryptedStoresOrItems`=0, `AlwaysUseAutoLangDetection`=0 | - | - | Y | Y | 2 | - | E | | P/…; M/… |
| S17 | Remove `Microsoft.BingSearch` appx (P/10: `*Bing*`) | Y | Y | Y | Y | **4** | - | H (Store) | A removes it both in appx.yml and in the Web Search default script. | A/atlas/appx.yml; R/packages/appx.yml; P/appx.yml |
| S18 | Remove the Cortana appx `Microsoft.549981C3F5F10` | Y | Y | Y | Y | **4** | - | H (Store) | | same |
| S19 | Store results in search: `HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\WinStore.Tasks.WindowsSearchTask` `ActivationType`=4294967295, `Server`=`''` | - | Y | - | - | 1 | - | E* (TI) | Comment says 25H2. | R/… |
| S20 | `HKLM\SYSTEM\ControlSet001\Policies\Microsoft\FeatureManagement\Overrides` `1694661260`=0 (stops SearchHost spawning WebView2) | - | Y | - | - | 1 | - | E | Feature ID is build-specific. | R/… |
| S21 | Firewall-block `SearchApp.exe` / `SearchHost.exe` | see FW3/FW4 | | | | | | | | |
| S22 | Hide the `search-permissions` Settings page | Y | - | Y | - | 2 | - | E | | AD/…/Disable Web Search (default).cmd; P/regedits.yml |
| S23 | Opposite direction: `HKLM\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex` `EnableFindMyFiles`=1 (enhanced indexing) | - | - | Y | Y | - | - | E* | Local only. Listed because it raises the amount of local indexing. | P/regedits.yml |

## 15. Input, inking, speech

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| I1 | `HKCU\SOFTWARE\Microsoft\InputPersonalization` `RestrictImplicitInkCollection`=1, `RestrictImplicitTextCollection`=1 | Y | ~ (via `revitool tweaks personalization input-personalization disable`, opaque) | Y | Y | **4** | - | E* | | A/tweaks/privacy/telemetry/disable-input-telemetry.yml; R/registry/explorer/win-settings.yml; P/regedits.yml; M/regedits.yml |
| I2 | `HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore` `HarvestContacts`=0 | Y | ~ | Y | Y | **4** | - | E* | P/10 also set `TrainedDataStore` `AcceptedPrivacyPolicy`=0. | same |
| I3 | `HKCU\SOFTWARE\Microsoft\Personalization\Settings` `AcceptedPrivacyPolicy`=0 | Y | ~ | Y | Y | **4** | - | E* | | same |
| I4 | `HKCU\SOFTWARE\Microsoft\Input\Settings` `InsightsEnabled`=0 (R also HKLM) | Y | Y | Y | - | 3* | - | E* | Typing insights. | A/…; R/…; P/components.yml |
| I5 | `HKCU\SOFTWARE\Microsoft\Input\TIPC` `Enabled`=0 and `HKLM\SOFTWARE\Microsoft\Input\TIPC` `Enabled`=0 | Y | Y | - | - | 2 | - | E* | "Improve inking and typing". | A/…; R/… |
| I6 | `HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\TextInput` `AllowLinguisticDataCollection`=0 | - | Y | - | - | 1 | - | E | | R/… |
| I7 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC` `PreventHandwritingDataSharing`=1 (R also HKCU) | Y | Y | - | - | 2 | - | E | | A/…; R/registry/privacy/privacy.yml |
| I8 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports` `PreventHandwritingErrorReports`=1 (R also HKCU) | Y | Y | - | - | 2 | - | E | | same |
| I9 | `HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy` `HasAccepted`=0 | Y | Y | - | - | 2 | - | E* | Online speech recognition and voice typing stop. | A/tweaks/privacy/disable-online-speech-recognition.yml; R/… |
| I10 | Speech model updates: A `HKLM\SOFTWARE\Policies\Microsoft\Speech` `AllowSpeechModelUpdate`=0; P/10 `HKLM\SOFTWARE\Microsoft\Speech_OneCore\Preferences` `ModelDownloadAllowed`=0 (R has it commented out) | Y | - | ~ | ~ | **3** | - | E | | A/tweaks/privacy/disable-speech-auto-updates.yml; P/regedits.yml |
| I11 | `HKLM\SOFTWARE\Microsoft\Speech_OneCore\Preferences` `VoiceActivationDefaultOn`=0 | - | - | Y | Y | 2 | - | E* | P also sets `HKCU\…\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps` `AgentActivationEnabled`=1 etc. (**the opposite**, as part of its permissions reset). | P/regedits.yml |
| I12 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE` `DisableVoice`=1 (R also the policy key, plus `EnableCortanaVoice`=0) | - | Y | Y | Y | **3** | - | E | | R/registry/system/oobe.yml; P/regedits.yml |
| I13 | `HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization` `AllowInputPersonalization`=0 | - | - | - | - | 0 | - | E | **A comments it out on purpose ("allow user to enable it").** | A/…/disable-online-speech-recognition.yml |
| I14 | Touch keyboard and hardware keyboard prediction off (`HKCU\SOFTWARE\Microsoft\TabletTip\1.7` `EnableAutocorrection`/`EnableSpellchecking`/`EnableTextPrediction`/`EnablePredictionSpaceInsertion`/`EnableDoubleTapSpace`=0; R also `HKCU\…\Input\Settings` `EnableHwkbTextPrediction`/`EnableHwkbAutocorrection`/`MultilingualEnabled`=0) | Y | Y | - | - | 2 | - | E* | QoL. Local only, little privacy value. | A/tweaks/qol/disable-spell-checking.yml; R/… |
| I15 | Remove the `Ink.Handwriting.Main.Store.en-US1.0` appx | Y | - | - | - | 1 | - | H | | A/atlas/appx.yml |

## 16. Location, Maps, Find My Device

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| L1 | `lfsvc` and `MapsBroker` off | see SV12, SV13 | | | | **3** | | | | |
| L2 | `HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice` `AllowFindMyDevice`=0, `LocationSyncEnabled`=0 | Y | - | - | - | 1 | - | E | | AD/3. General Configuration/Location/Disable Location (default).cmd |
| L3 | `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location` `ShowGlobalPrompts`=0 | Y | - | - | - | 1 | - | E* | | same |
| L4 | `…\ConsentStore\location` `Value`=`Deny` (A HKLM, R HKCU) | Y | Y | X (Allow) | X (Allow) | 2 | - | E* | See §17 on P's Allow reset. | A/tweaks/privacy/config-app-permissions.yml; R/…/win-settings.yml |
| L5 | `HKLM\SYSTEM\Maps` `AutoUpdateEnabled`=0, `UpdateOnlyOnWifi`=1 | - | Y | - | - | 1 | - | E* | | R/… |
| L6 | Remove the `Microsoft.WindowsMaps` appx | Y | Y | Y | Y | **4** | - | H (Store) | | A/atlas/appx.yml; R/packages/appx.yml; P/appx.yml |
| L7 | Maps tasks | see ST14 | | | | | | | | |
| L8 | Hide the `privacy-location`, `findmydevice` Settings pages | Y | - | Y | - | 2 | - | E | | AD/…; P/regedits.yml |
| L9 | OOBE `ProtectYourPC`=3 (HKLM `…\CurrentVersion\OOBE` and the policy key) | - | Y | - | - | 1 | - | E | Opts out of location, ads, speech and problem reports at OOBE. Applies to new users and ISO use. | R/registry/system/oobe.yml |

Gap: no reference sets `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors` `DisableLocation`. That value is **unknown**; check it before use.

## 17. App permissions (CapabilityAccessManager ConsentStore)

Path `HK{LM,CU}\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\<cap>`, value `Value` (REG_SZ) `Allow` or `Deny`. Rev E*.
**There is no consensus.** P and 10 deliberately reset every capability to `Allow` in HKLM and HKCU. They also set the legacy
`HKCU\…\DeviceAccess\Global\{GUID}` `Value`=`Allow`, because their `SettingsPageVisibility` hides all `privacy-*` pages
and users would otherwise have no way to change them. A and R deny selectively.

| Capability | A | R | P / 10 | Notes |
|---|---|---|---|---|
| `appDiagnostics` | Deny (HKLM) | Deny (HKCU+HKLM) | Allow | |
| `location` | Deny (HKLM) | Deny (HKCU) | Allow | |
| `userAccountInformation` | Deny (HKLM) | Deny (both) | Allow | |
| `webcam`, `microphone` | - | **Allow** (both) | Allow | R forces Allow explicitly. |
| `activity` (motion) | - | Deny | Allow | |
| `appointments` | - | Deny | Allow | |
| `contacts`, `phoneCallHistory`, `email` | - | commented out ("needed for Mail & Calendar") | Allow | |
| `userDataTasks`, `chat`, `radios`, `bluetoothSync` | - | Deny | Allow | `radios` Deny prevents apps from toggling Bluetooth or Wi-Fi. |
| `documentsLibrary`, `picturesLibrary`, `videosLibrary`, `broadFileSystemAccess` | - | Deny | Allow | **Store apps lose library and file access (Photos, Media Player).** |
| `userNotificationListener` | - | commented out | Allow | |
| `generativeAI` | - | - | Deny (P, HKLM) | See AI9. |
| `phoneCall`, `cellularData`, `gazeInput`, `graphicsCaptureProgrammatic` (+`\NonPackaged`), `graphicsCaptureWithoutBorder` (+`\NonPackaged`), `musicLibrary`, `downloadsFolder` | - | - | Allow | |

Sources: A/tweaks/privacy/config-app-permissions.yml; R/registry/explorer/win-settings.yml; P/regedits.yml; M/regedits.yml.

Background apps: A sets `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications` `GlobalUserDisabled`=1 and
`HKCU\…\Search` `BackgroundAppGlobalToggle`=0 (A/tweaks/performance/disable-background-apps.yml, also the default script). R comments out
`HKLM\Software\Policies\Microsoft\Windows\AppPrivacy` `LetAppsRunInBackground`=2 because it "causes KGL versions mismatch in Xbox Game Bar".
**Risk: background toasts and alarms from Store apps stop.**

## 18. Widgets, News, Chat, Meet Now, Teams

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| WG1 | `HKLM\SOFTWARE\Policies\Microsoft\Dsh` `AllowNewsAndInterests`=0 | Y | Y | Y | Y | **4** | - | E | | A/tweaks/qol/taskbar/disable-news-and-interests.yml; R/registry/explorer/taskbar.yml; P/regedits.yml; M/regedits.yml |
| WG2 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds` `EnableFeeds`=0 | Y | Y | Y | Y | **4** | - | E | | same |
| WG3 | `HKCU\…\Explorer\Advanced` `TaskbarDa`=0 | - | Y | Y | Y | **3** | 10: opt:ui | E* | On 24H2+ writing TaskbarDa can fail (UCPD-protected). R uses `errorAction: Ignore`. | R/…; P/…; M/… |
| WG4 | `HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests` `value`=0 | - | - | Y | Y | 2 | - | E* | | P/…; M/… |
| WG5 | `HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds` `ShellFeedsTaskbarViewMode`=2 | - | Y | - | - | 1 | - | E* | Win10. | R/… |
| WG6 | Remove the `MicrosoftWindows.Client.WebExperience` appx (R also `Microsoft.WidgetsPlatformRuntime`) | - | Y | Y | Y | **3** | - | H (Store) | R comment: since 22621.1343, Windows reinstalls it even when deprovisioned, so WG1 is also needed. | R/packages/appx.yml; P/appx.yml |
| WG7 | `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat` `ChatIcon`=3 | Y | Y | Y | Y | **4** | A b>=22000 | E | | A/tweaks/qol/taskbar/disable-windows-chat.yml; R/…; P/…; M/… |
| WG8 | `HKCU\…\Explorer\Advanced` `TaskbarMn`=0 | Y | Y | Y | Y | **4** | A b>=22000 | E* | | same |
| WG9 | `…\Policies\Explorer` `HideSCAMeetNow`=1 (A HKLM; R HKCU+HKLM; P/10 HKCU) | Y | Y | Y | Y | **4** | - | E | | A/tweaks/qol/taskbar/hide-meet-now.yml; R/…; P/… |
| WG10 | Remove Teams (`MSTeams*`, `MicrosoftTeams*`; R also MSI `{A7AB73A3-CB10-4AA5-9D38-6AEFFBDE4C91}`) | Y | Y | Y | Y | **4** | R opt:remove-teams | H | | A/atlas/appx.yml; R/packages/app-win32.yml; P/appx.yml |
| WG11 | `HKCU\Software\Policies\Microsoft\Windows\Explorer` `HidePeopleBar`=1 | - | Y | - | - | 1 | - | E | Win10. | R/… |

## 19. Third-party and app telemetry (Office, NVIDIA, .NET, PowerShell, Media Player, Delivery Optimization, misc.)

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| O1 | Office: `HKCU\Software\Policies\Microsoft\office\16.0\common` `sendcustomerdata`=0, `qmenable`=0; `HKCU\Software\Policies\Microsoft\office\common\clienttelemetry` `sendtelemetry`=3 | Y | - | - | - | 1 | - | E | Harmless if Office is absent. | A/tweaks/privacy/apps/disable-office-telemetry.yml |
| O2 | Office: disable every `\Microsoft\Office\*` task | - | Y | - | - | 1 | - | M | See ST18 (also stops Office updates). | R/final.yml |
| O3 | Office C2R: `HKLM\SOFTWARE\Microsoft\ClickToRun\OverRide` `DisableLogManagement`=1; `HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration` `TimerInterval` (REG_SZ)=`900000` | - | Y | - | - | 1 | - | E* | | R/registry/misc/disable-logging.yml |
| O4 | NVIDIA: `HKCU\Software\NVIDIA Corporation\NVControlPanel2\Client` `OptInOrOutPreference`=0 | Y | Y | - | - | 2 | - | E* | | A/tweaks/privacy/apps/disable-nvidia-telemetry.yml; R/registry/privacy/privacy.yml |
| O5 | .NET CLI: `DOTNET_CLI_TELEMETRY_OPTOUT=1` via `setx` | Y | Y | - | - | 2 | - | E | **Both use `setx` without `/M`, which sets the variable only for the account running the action (Admin or TI context).** For machine-wide effect, write `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` `DOTNET_CLI_TELEMETRY_OPTOUT` (REG_SZ)=`1`. | A/tweaks/privacy/telemetry/disable-dotnet-cli-telemetry.yml; R/final.yml; RX/FINALIZE.cmd |
| O6 | PowerShell 7: `POWERSHELL_TELEMETRY_OPTOUT=1` (`setx`) | - | Y | - | - | 1 | - | E | Same `setx` caveat. | R/final.yml; RX/FINALIZE.cmd |
| O7 | Windows Media Player: `HKLM\SOFTWARE\Policies\Microsoft\WMDRM` `DisableOnline`=1; `HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences` `UsageTracking`=0, `AcceptedPrivacyStatement`=1 | Y | - | ~ (WMP files removed) | ~ | **3** | - | E | | A/tweaks/privacy/config-windows-media-player.yml; P/files.yml |
| O8 | Intel `Telemetry` service | see SV11 | | | | | | | | |
| O9 | VS/VSCode and Brave telemetry hosts | see §5 | | | | | | | | |
| DO1 | Delivery Optimization: A/R `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization` `DODownloadMode`=0; P/10 `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config` `DownloadMode`=0 (+ delete DoSvc, SV14) | Y | Y | ~ | ~ | **4** | - | E (policy) | 0 = HTTP only, no peer-to-peer. Safe. Prefer the policy key. | A/tweaks/qol/windows-update/disable-delivery-optimization.yml; AD/3. General Configuration/Delivery Optimization/…; R/registry/updates/updates.yml; P/regedits.yml |
| MS1 | Wi-Fi Sense: `HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting` `value`=0, `…\AllowAutoConnectToWiFiSenseHotspots` `value`=0 | - | Y | Y | Y | **3** | - | E* | | R/registry/explorer/win-settings.yml; P/regedits.yml; M/regedits.yml |
| MS2 | Wi-Fi Sense: `HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config` `AutoConnectAllowedOEM`=0; `…\features` `PaidWifi`=0, `WiFiSenseOpen`=0 | - | Y | - | - | 1 | - | E* | | R/… |
| MS3 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata` `PreventDeviceMetadataFromNetwork`=1 | - | - | Y | Y | 2 | - | E* | Stops DsmSvc fetching device icons and info (dspg.akamaiedge.net). | P/regedits.yml; M/regedits.yml |
| MS4 | Restrict Internet Communication (R). HKCU and HKLM `…\Policies\Explorer`: `NoPublishingWizard`=1, `NoWebServices`=1, `NoOnlinePrintsWizard`=1, `NoInternetOpenWith`=1. `…\Policies\Microsoft\Windows NT\Printers` `DisableHTTPPrinting`=1, `DisableWebPnPDownload`=1. HKCU `…\Policies\Microsoft\Assistance\Client\1.0` `NoOnlineAssist`/`NoExplicitFeedback`/`NoImplicitFeedback`=1. `…\Policies\Microsoft\WindowsMovieMaker` `WebHelp`/`CodecDownload`/`WebPublish`=1. HKLM `…\Policies\Microsoft\PCHealth\HelpSvc` `Headlines`=0, `MicrosoftKBSearch`=0. `…\Policies\Microsoft\Windows\Internet Connection Wizard` `ExitOnMSICW`=1. `…\Policies\Microsoft\EventViewer` `MicrosoftEventVwrDisableLinks`=1. `…\Policies\Microsoft\Windows\Registration Wizard Control` `NoRegistration`=1. `…\Policies\Microsoft\SearchCompanion` `DisableContentFileUpdates`=1 | ~ (`NoInternetOpenWith` only, HKLM) | Y | - | - | 2 | - | E | `DisableWebPnPDownload` can block driver downloads for network printers. | R/registry/privacy/privacy.yml; A/tweaks/qol/explorer/no-internet-open-with.yml |
| MS5 | OOBE privacy page: `HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE` `DisablePrivacyExperience`=1 (R also the non-policy `…\CurrentVersion\OOBE`) | Y | Y | Y | Y | **4** | - | E | Stops feature updates from re-prompting the privacy settings. | A/tweaks/privacy/disable-privacy-experience.yml; R/registry/system/oobe.yml; P/regedits.yml; M/regedits.yml |
| MS6 | Smart App Control off: `HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy` `VerifiedAndReputablePolicyState`=0 | Y | - | - | - | 1 | - | **H** | Atlas: "sends data to Microsoft". **Once SAC is off, Windows will not turn it back on without a reset or reinstall.** Security loss. | A/atlas/components.yml |
| MS7 | SmartScreen off (sends URLs and file hashes to MS). P/10: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer` `SmartScreenEnabled` (REG_SZ)=`Off`; HKCU `…\AppHost` `EnableWebContentEvaluation`=0 (R too) and `ContentEvaluation`=0; delete `smartscreen.exe`/`smartscreenps.dll`. R: `HKLM\Software\Policies\Microsoft\Windows Defender\SmartScreen` `ConfigureAppInstallControlEnabled`=1, `ConfigureAppInstallControl` (REG_SZ)=`Anywhere`; `HKLM\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter` `EnabledV9`=0 | - | ~ | Y | Y | **3** | - | E / H | **Security tradeoff. Phase 3 stance (Defender).** P deletes the binaries (H). | P/regedits.yml; P/components.yml; R/registry/security/security.yml |
| MS8 | Remote Assistance off: `HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance` `fAllowToGetHelp`=0, `fAllowFullControl`=0 (+ FW9) | Y | - | ~ (deletes `msra.exe`) | ~ | **3** | - | E | | A/tweaks/security/disable-remote-assistance.yml; P/files.yml |
| MS9 | Time servers: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers` ``=`1`, `1`=`pool.ntp.org`, `2`=`time.windows.com`, `3`=`time.nist.gov`; `w32tm /config /manualpeerlist:pool.ntp.org /syncfromflags:manual /update` | - | - | Y | Y | 2 | - | E* | Moves NTP away from Microsoft. Minor privacy gain. | P/regedits.yml; P/config.yml |
| MS10 | Remove the `Microsoft.WindowsFeedbackHub` appx | Y | Y | Y | Y | **4** | - | H (Store) | | A/atlas/appx.yml; R/packages/appx.yml; P/appx.yml |
| MS11 | Feedback frequency: `HKCU\SOFTWARE\Microsoft\Siuf\Rules` `NumberOfSIUFInPeriod`=0, delete `PeriodInNanoSeconds` | Y | Y | - | - | 2 | - | E* | | A/tweaks/qol/disable-windows-feedback.yml; R/registry/explorer/win-settings.yml |
| MS12 | `DoNotShowFeedbackNotifications`=1 (A under `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection`; R under `HKLM\Software\Policies\Microsoft\Windows\DataCollection`) | Y | Y | - | - | 2 | - | E | Different keys. The policy key (R) is the documented one. | same; R/registry/privacy/telemetry.yml |
| MS13 | Hide privacy Settings pages via `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` `SettingsPageVisibility` (REG_SZ). P: `hide:` list with every `privacy-*` page, `sync`, `findmydevice`, `crossdevice`, `aicomponents`, `search-permissions`, `cortana*` and others. 10: a `showonly:` list. R: `revitool registry hide-page --value "cortana,privacy-feedback,windowsinsider,home"` | ~ | ~ | Y | Y | **4** (different lists) | - | E | **Hiding pages makes the user's own privacy choices unreachable.** That is why P resets permissions to Allow (§17). Not recommended for us: rule 5 requires changes to stay reversible. | P/regedits.yml; M/regedits.yml; R/registry/explorer/win-settings.yml; AD scripts call `settingsPages.cmd` |
| MS14 | Lock-screen camera: `HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization` `NoLockScreenCamera`=1 | Y | - | - | - | 1 | - | E | | A/tweaks/privacy/disable-lockscreen-camera.yml |
| MS15 | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` `MSAOptional`=1 | - | Y | - | - | 1 | - | E | Lets apps be used without an MSA. Softer alternative to CS8. | R/registry/privacy/privacy.yml |
| MS16 | NCSI active probing (`HKLM\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet` `EnableActiveProbing`=0 / `…\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator` `NoActiveProbe`=1) | - | - (commented) | - (commented) | - (commented) | 0 | - | E | **Every reference leaves it on.** It breaks "No Internet" detection, captive portals and Store connectivity checks. | R/…/privacy.yml; P/regedits.yml |

## 20. Edge

| # | Change | A | R | P | 10 | Cnt | Gate | Rev | Notes / risk | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| E1 | Uninstall Edge | Y | Y | Y | Y | **4** | A opt:uninstall-edge (unchecked); R opt:remove-edge (checked); P/10 always | H | A `AX/AtlasModules/Scripts/ScriptWrappers/RemoveEdge.ps1 -UninstallEdge -RemoveEdgeData -KeepAppX -NonInteractive`, then `!appx` family `Microsoft.MicrosoftEdge_8wekyb3d8bbwe` and Deprovisioned keys `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe` and `…\Microsoft.MicrosoftEdge_8wekyb3d8bbwe`. R `RX/EDGE.ps1 -Mode EdgeBrowser` and appx `Microsoft.MicrosoftEdge`, `Microsoft.MicrosoftEdgeDevToolsClient`, `Microsoft.Edge.GameAssist`. P/10 `PX/EDGE.bat`, delete services `edgeupdate`/`edgeupdatem`, `HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate`, `%ProgramFiles(x86)%\Microsoft\EdgeUpdate`, appx `*MicrosoftEdge*`. **WebView2 must stay** (A `-KeepAppX`; R keeps WebView). A ships a reinstall script (`AD/1. Software/Install or Remove Edge.cmd`). Phase 3 stance item. | A/atlas/components.yml; R/packages/app-win32.yml; P/components.yml |
| E2 | EdgeUpdate policies: `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate` `InstallDefault`=0, `Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}`=0 (Edge Stable), `Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}`=1 (WebView2 runtime), `DoNotUpdateToEdgeWithChromium`=1; also `HKLM\SOFTWARE\Microsoft\EdgeUpdate` `DoNotUpdateToEdgeWithChromium`=1 | - | Y | - | - | 1 | - | E | Blocks Edge reinstall while still allowing WebView2. | R/registry/misc/fixes.yml; R/registry/misc/deprovisioned-apps.yml |
| E3 | Edge AI policies under `HKLM\SOFTWARE\Policies\Microsoft\Edge`: `CopilotCDPPageContext`=0, `CopilotPageContext`=0, `HubsSidebarEnabled`=0, `EdgeEntraCopilotPageContext`=0, `Microsoft365CopilotChatIconEnabled`=0, `EdgeHistoryAISearchEnabled`=0, `ComposeInlineEnabled`=0, `GenAILocalFoundationalModelSettings`=1 | - | - | Y | - | 1 | - | E | Useful when Edge is kept. | P/components.yml |
| E4 | `HKLM\Software\Policies\Microsoft\Windows\DataCollection` `MicrosoftEdgeDataOptIn`=0 | - | Y | - | - | 1 | - | E | Desktop Analytics browsing data. | R/registry/privacy/telemetry.yml |
| E5 | Legacy Edge SmartScreen `EnabledV9`=0 | see MS7 | | | | | | | | |
| E6 | `browser.pipe.aria.microsoft.com` in hosts | see §5 | | | | | | | | |

Gap: no reference sets the standard Edge telemetry policies (`DiagnosticData`, `PersonalizationReportingEnabled`,
`UserFeedbackAllowed`, `EdgeShoppingAssistantEnabled`, `ShowRecommendationsEnabled`, and so on). Those value names are **not cited in
`docs/`**. If we keep Edge, source them from Microsoft's Edge policy docs first (CLAUDE.md rule 3).

---

## 21. Consensus baseline (3+ playbooks, or 3/3 of the Win11 playbooks)

These are the safest candidates for an ungated `privacy.yml` / `telemetry.yml`. All are registry policy or user values (Rev E/E*)
unless marked otherwise. Items marked **(gate)** are consensus in intent, but we should still put them behind an option because they
remove software or break features.

| Theme | Items |
|---|---|
| Telemetry policy | T1, T2, T3 (`AllowTelemetry`=0 ×3), T13 (DiagTrack autologger, check the key name), T14 (SQMLogger), T16 (ETL cleanup), T23 (`NoGenTicket`) |
| Services | SV1 `DiagTrack`=4, SV2 `diagnosticshub.standardcollector.service`=4, SV7 `TrkWks`=4 (optional), SV9 `wisvc`=4, SV12/SV13 `lfsvc`/`MapsBroker`=4 **(gate: location)**, SV8 `OneSyncSvc` **(gate: breaks Mail/Calendar sync)**, SV24 `edgeupdate`=3 |
| Tasks | ST1 Consolidator, ST2 UsbCeip, ST3 KernelCeipTask, ST4 Compatibility Appraiser, ST13 Siuf DmClient. All via `!scheduledTask … operation: disable` (more reversible than delete) |
| Telemetry binaries | CR4 IFEO block of `CompatTelRunner.exe`/`DeviceCensus.exe` (reversible stand-in for file deletion), CR5 Update Health Tools removal |
| WER | W1 (`Disabled`=1, policy and non-policy), W2 (`DontSendAdditionalData`=1), W13 MSRT `DontReportInfectionInformation`=**1** |
| Ads / suggestions | AD1, AD2 (advertising ID), AD6 (`HttpAcceptLanguageOptOut`), AD7/AD8 (`Start_IrisRecommendations`/`Start_AccountNotifications`=0), AD15 (value banner), CD1, CD2, CD3 (CDM), CC1 (`DisableCloudOptimizedContent`), CC5 (Spotlight desktop icon) |
| Activity | AH1 (`EnableActivityFeed`=0), AH6 (recent docs, **gate: QoL cost**) |
| Cloud sync | CS1 (`DisableSettingSync`=2 + UserOverride=1), CS6 OneDrive removal **(gate)**, CS11 Phone Link **(gate)** |
| AI (Win11) | AI1 (`TurnOffWindowsCopilot` HKCU), AI3 (`ShowCopilotButton`=0), AI4 Copilot appx **(gate)**, AI5 (`DisableAIDataAnalysis`=1) |
| Search | S1–S5 (web search off, Bing off, location off, suggestions off), S6, S7, S8, S9 (SafeSearch, cosmetic), S11 (`AllowCloudSearch`=0), S17/S18 Bing/Cortana appx **(gate)** |
| Input / speech | I1, I2, I3 (implicit ink/text collection, contacts harvest), I4 (`InsightsEnabled`=0), I10 (speech model updates), I12 (OOBE voice) |
| Location | L6 Maps appx **(gate)** |
| Widgets / chat | WG1, WG2 (News and Interests off), WG3 (`TaskbarDa`=0), WG6 WebExperience appx **(gate)**, WG7, WG8 (Chat), WG9 (Meet Now), WG10 Teams **(gate)** |
| Misc | DO1 (`DODownloadMode`=0), MS1 (Wi-Fi Sense reporting), MS5 (`DisablePrivacyExperience`=1), MS8 (Remote Assistance), MS10 Feedback Hub appx **(gate)**, O7 (WMP privacy), E1 Edge removal **(gate, Phase 3 stance)** |

Excluded despite 3+ votes: MS7 SmartScreen (security, belongs to the Defender stance), MS13 hiding Settings pages
(blocks reversibility), CR3 binary deletion (2 votes and H). SV25/FW5 CryptSvc rehosting (2 votes) is excluded too.

## 22. Build-specific notes

| Item | Builds | Evidence |
|---|---|---|
| Copilot policy, Chat icon, Recall script, `Start_IrisRecommendations`, value banner | A gates them with `builds: [ '>=22000' ]` | A/tweaks/qol/taskbar/disable-copilot.yml, disable-windows-chat.yml, tweaks/privacy/disable-recall-snap.yml, tweaks/qol/shell/no-recommendations-start-menu.yml, tweaks/qol/disable-win11-settings-banner.yml |
| Recall `DisableAIDataAnalysis`, Spotlight desktop icon | 24H2 (26100+). Comments in R | R/registry/explorer/win-settings.yml, explorer.yml |
| `WindowsAI` tasks, `WSAIFabricSvc`, AIX/CoreAI appx, Click to Do, Settings agent, Paint/Notepad AI | 24H2/25H2 (26100/26200). P targets them; harmless if absent | P/components.yml |
| Store results in search (`WinStore.Tasks.WindowsSearchTask`) | "25H2" (26200) per R comment | R/registry/explorer/search.yml |
| FeatureManagement override IDs `1694661260` (SearchHost WebView2) and `1387020943` (cross-device resume) | Build-specific feature IDs. They may change between CUs | R/…/search.yml, win-settings.yml |
| `EnableAccountNotifications` | "Found in 22631.3527" (R comment) | R/…/win-settings.yml |
| WebExperience reinstall despite deprovisioning | Since 22621.1343 (R comment). Needs both WG1 and WG6 | R/registry/explorer/taskbar.yml |
| `TaskbarDa` / `TaskbarMn` writes | On recent 24H2 CUs these values may be UCPD-protected. R uses `errorAction: Ignore`. Prove in VM | R/registry/explorer/taskbar.yml |
| CPSS keys (T7) | 22H2+ | R/registry/privacy/telemetry.yml |
| Win10-only (ignore for us) | `ShellFeedsTaskbarViewMode`, `HidePeopleBar`, SearchApp firewall rule, Cortana CDM IDs, AME10 in general | |
| `AllowTelemetry`=0 effect | Edition-specific: only Enterprise, Education and Server honour 0 | MS documentation (not in `docs/`; verify) |

## 23. Conflicts and probable bugs in the references (do not copy)

| Ref | Issue |
|---|---|
| R/registry/updates/updates.yml | MRT `DontReportInfectionInformation`=**0** under the comment "Disable … – Enabled". Should be 1 (A uses 1). |
| R/registry/explorer/search.yml | `AllowCortana`=**1** under the comment "Allow Cortana – Disabled". |
| R/registry/explorer/win-settings.yml | `EnableAccountNotifications`=**1** under the comment "Show me notifications in the Settings app – Off". |
| R/registry/privacy/app-compat.yml | `SbEnable`=1 labelled "Turn off SwitchBack – Enabled". The ADMX Enabled state is 0. |
| R/registry/privacy/privacy.yml | `Block-Windows-Error-Reporting` (Parameters copy) has `Name=Block-Unified-Telemetry-Client`. |
| RX/FINALIZE.cmd | `wevtutil sl … /q:false` instead of `/e:false`. |
| A/tweaks/qol/disable-windows-spotlight.yml | Key typo `NewStartPanelt`. |
| T13 | The DiagTrack autologger key name differs: `Diagtrack-Listener` (A, R) vs `AutoLogger-Diagtrack-Listener` (P, 10). |
| A/…/disable-dotnet-cli-telemetry.yml, R/final.yml | `setx` without `/M` sets only the running account's environment. |
| P/regedits.yml | Resets every ConsentStore capability and voice activation to **Allow**/1. That is intentional for P (pages hidden), but the opposite of A and R. |
| A YAML in general | Uses `!writeStatus` and `ignoreErrors`. Our rule 4 says `!status` and `errorAction`. Translate when porting. |

## 24. Riskiest items (breakage or reversibility)

| Rank | Item | Why |
|---|---|---|
| 1 | SV25 + FW5: CryptSvc (and lfsvc) rehosted to firewall-blocked `amehost.exe` (P, 10) | Blocks certificate revocation and root-store updates. Silent TLS and code-signing failures. Hard to diagnose. |
| 2 | CR3: deleting telemetry/WU/DO binaries plus the SFC mitigation (P, 10) | Not reversible without repair. Breaks servicing, cumulative updates, Store downloads (DoSvc) and in-place upgrades. |
| 3 | CR1/CR2/AI16: CBS/WinSxS component removal (A NoTelemetry package; R opaque Revision Tool packages) | Needs our own package build. R's contents are unknown. The A package needs its uninstall script to revert. |
| 4 | MS6: Smart App Control off (A) | Cannot be re-enabled without a reset. |
| 5 | CS8: `NoConnectedUser`=1 (A) | Blocks MSA sign-in. Store, Xbox and OneDrive accounts are affected. |
| 6 | AI13, CS15, CD12: removing system appx (AIX/CoreAI, CloudExperienceHost, ContentDeliveryManager) (P) | Breaks OOBE/MSA flows, Spotlight and Click to Do. Risk to CBS servicing. |
| 7 | FW7/FW8: firewall-blocking SystemSettings.exe and explorer.exe (P, 10) | Breaks Settings account flows, Explorer Home and online help. |
| 8 | SV10: WdiServiceHost/WdiSystemHost disabled (R) | Breaks troubleshooters and diagnostics. |
| 9 | SV14: DoSvc deleted (P, 10) | Store and Windows Update downloads fail. |
| 10 | AC5: AppCompat `DisableEngine`=1 (A, R) | Legacy apps and games that need shims break. |
| 11 | CC7: `NoCloudApplicationNotification`=1 (R) | No cloud push toasts (Teams, Mail, Store apps). |
| 12 | §17 library/file-system Deny (R); SV22 WbioSrvc stop (P) | Store apps lose file access. Windows Hello breaks until reboot. |
| 13 | ST16 Clip License Validation deleted, ST18 Office tasks disabled | Store licences go stale. Office stops updating. |

---

## Summary

- **Tweaks catalogued: 270 numbered rows.** Many rows hold several values, so the inventory covers roughly 330
  distinct registry values, services, tasks, rules or files. There are also 54 hosts entries and 8 firewall rules.
- **Consensus baseline: 74 rows** (§21), each done by 3+ playbooks or by all three Win11 playbooks.
  About 60 are pure registry policy or user values and can ship ungated and reversible. About 14 remove apps
  or disable services and should sit behind options.
- **Riskiest items:** CryptSvc rehosting behind a firewall block (P/10). Binary deletion plus the SFC
  mitigation (P/10). Opaque or custom CBS component removal (R/A). Smart App Control off (A, irreversible).
  `NoConnectedUser` (A). Removing CloudExperienceHost/CDM/AI system appx (P). Firewall-blocking
  `explorer.exe` and `SystemSettings.exe` (P/10). Disabling WdiServiceHost (R) and DoSvc (P/10).
- **Bugs to avoid when porting:** see §23. The main ones are R's MRT=0, `AllowCortana`=1 and
  `EnableAccountNotifications`=1, the DiagTrack autologger key-name split (check in VM), and `setx` without `/M`.
