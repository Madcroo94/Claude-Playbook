# Format gaps: what shipped playbooks do that `docs/` does not say

Compiled 2026-10-09 by reading five real playbooks. Nothing in them was executed.
Treat every "observed only" item as **unproven for us** until a VM run confirms
it (CLAUDE.md hard rule 3). Shipped playbooks still prove one thing: AME Wizard
loaded them without a conf or YAML parse error.

| Short name | Path under `refs/` | What it is | Licence |
|------------|-------------------|------------|---------|
| Atlas | `atlas/src/playbook` | AtlasOS v0.5.0 git source (Win11 24H2/25H2) | GPLv3 |
| Revi | `revi/src` | ReviOS git source (conf says `1.0`) | CC BY-SA 4.0 |
| Revi-apbx | `revi-apbx` | ReviOS 26.04 release build, extracted | CC BY-SA 4.0 |
| P+ | `privacyplus` | AME Privacy+ 0.8.2 (Win11), by Ameliorated | — |
| AME10 | `ame10` | AME 10 0.8 (Win10), by Ameliorated | — |

`refs/` is `/tmp/claude-0/.../scratchpad/refs/` from the research session and is
not in the repo. Line numbers below are from that snapshot. Revi-apbx matches
Revi apart from CRLF line endings and a few tweaks; when only Revi is cited,
Revi-apbx has the same line. AME10 is a near copy of P+ (same task files, Win10
builds, no ISO/Software blocks).

P+ and AME10 are made by the authors of AME Wizard. Where they disagree with the
docs, they are the strongest evidence of what the engine accepts.

---

## 1. Summary of the important gaps

1. **`!writeStatus` works.** Atlas (36 uses) and Revi (32) ship it in
   current releases. P+ and AME10 use only `!status`. Both tags are accepted;
   we keep `!status`.
2. **Task files have undocumented top-level keys.** All 313 task files carry
   `description:`. Most Revi/P+ files carry `privilege: TrustedInstaller` or
   `privilege: Admin`. Atlas and Revi use file-level `onUpgrade:`. tasks.html
   documents only `title`, `option`, `options` and `builds`.
3. **`!task` paths with backslashes are the norm.** All four playbooks use them
   (`'Tasks\start.yml'`, `'tasks\regedits.yml'`, `'tweaks\qol\x.yml'`). The path
   is relative to `Configuration/`, and the sub-folder name can be anything
   (Atlas has no `Tasks/` folder).
4. **Atlas still ships `Configuration/custom.yml` as its entrypoint and has no
   `main.yml`.** The 2024-06-12 changelog calls `custom.yml` deprecated.
5. **Undocumented conf fields and requirements:** `<Overhaul>`,
   `<EstimatedMinutes>`, `<Package DefaultWebBrowser="true">`, and the
   `NoTweakware` and `LocalAccounts` requirements.
6. **Undocumented action parameters and values:** `!run hideWindow`,
   `scope: defaultUser` (docs: `defaultUsers`), `!service startup: 1`,
   lowercase `cpuArch: "x64"`, `!registryValue` with no `value` (targets the
   default value), and wildcards in `!service` names and `!file` paths.
7. **Default-user hive tricks:** Atlas loads the Default user hive itself as
   `HKU\AME_UserHive_Default`. Revi writes `HKU\.DEFAULT` and `HKU\S-1-5-18`
   alongside `HKCU`. During ISO injection Atlas writes to the offline hive
   `HKLM\OfflineSys\...`.
8. **Packaging:** Atlas builds its `.apbx` as a **ZIP** with password `malte`
   (`-tzip`). Our docs and `tools/package.py` say 7z. Both evidently load.

---

## 2. YAML action tags and parameters

### 2.1 Tags in use

Counts are live (uncommented) actions found by parsing each file.

| Tag | Atlas | Revi | P+ | AME10 | In our docs? |
|-----|------:|-----:|---:|------:|--------------|
| `!registryValue` | 386 | 737 | 506 | 464 | yes |
| `!registryKey` | 35 | 103 | 347 | 344 | yes |
| `!file` | 1 | 2 | 322 | 321 | yes (File.html, not on the index) |
| `!task` | 181 | 52 | 7 | 7 | yes |
| `!appx` | 41 | 5 | 82 | 73 | yes |
| `!service` | 13 | 21 | 53 | 50 | yes |
| `!run` | 29 | 37 | 31 | 27 | yes |
| `!taskKill` | 7 | 18 | 37 | 29 | yes |
| `!powerShell` | 53 | 24 | 0 | 1 | yes |
| `!writeStatus` | 36 | 32 | 0 | 0 | **docs say avoid** |
| `!status` | 0 | 3 | 38 | 37 | yes |
| `!scheduledTask` | 8 | 0 | 23 | 20 | yes |
| `!cmd` | 22 | 7 | 0 | 0 | yes |
| `!software` | 0 | 1 | 15 | 15 | yes |
| `!download` | 0 | 4 | 2 | 2 | yes |
| `!systemPackage` | 0 | 0 | 1 | 1 | yes |

**`!FileAction`** appears only **commented out**, in
`privacyplus/Configuration/tasks/files.yml:198,200` (`#- !FileAction:`) and
`ame10/Configuration/tasks/files.yml:190,192`. That is the C# class-name style
(like `WriteStatus`), not a live tag. Do not use it: `!file` is the tag. No
other tag outside our table appears in any reference.

`!writeStatus` examples:
- `atlas/src/playbook/Configuration/custom.yml:10` — `- !writeStatus: { status: "Deleting old AtlasOS folders" }`
- `revi/src/Configuration/Tasks/packages/app-win32.yml:8` — `- !writeStatus: {status: "Removing MS Edge", option: "remove-edge"}`

Both releases are current (Atlas 0.5.0 targets 26100/26200; Revi 26.04).
`!writeStatus` takes the same parameters as `!status`, including `option`.

### 2.2 Shared parameters as used

| Param | Used by | Example (file:line) | Docs say | Gap |
|-------|---------|---------------------|----------|-----|
| `option` / `!option` | all | `revi/src/Configuration/Tasks/final.yml:128` `option: "!configure-darkmode"` | documented | none |
| `options` with `option` on the **same** action | Revi | `revi/src/Configuration/Tasks/final.yml:106-107` `option: "!configure-wallpaper"` + `options: ["configure-darkmode"]` | `options` = OR list | **How `option` and `options` combine is undocumented.** Revi's intent is AND (dark mode on, wallpaper off). Prove it in a VM before copying. |
| `errorAction` | Revi | `Ignore` (`revi/src/Configuration/main.yml:21`), `Halt` (`revi/src/Configuration/Tasks/start.yml:50`), `Log` (`start.yml:46`, on `!download`) | `Ignore/Log/Notify/Halt` | none; `Notify` is unused |
| `ignoreErrors: true` | Atlas, Revi, P+, AME10 | `atlas/src/playbook/Configuration/tweaks/debloat/disable-scheduled-tasks.yml:6`, `revi/src/Configuration/Tasks/start.yml:19`, `privacyplus/Configuration/tasks/services.yml:62` | deprecated | Still accepted; even AME's own P+ 0.8.2 uses it. Keep using `errorAction`. |
| `cpuArch` | Atlas, Revi, P+ | `X64`, `Arm64` (`revi/src/Configuration/Tasks/software.yml:21,35`); `'Arm64'` on `!file` (`atlas/.../tweaks/performance/disable-fth.yml:11`); **lowercase `"x64"`** (`privacyplus/Configuration/tasks/software.yml:6,12`) | .NET `Architecture`, example `"X64"`; case unknown (recon §15) | AME's own playbook uses `x64`, so the parse is very likely case-insensitive. Keep `X64`/`Arm64`. |
| `builds` on actions | Atlas, P+ | `['>=22000']` (`atlas/.../qol/disable-win11-settings-banner.yml:10`); `['<22000']` on REG_NONE values (`atlas/.../qol/shell/set-unpinned-notification-items.yml`); UBR compare `['<22621.2428']` (`privacyplus/Configuration/tasks/software.yml:42`) | documented | `<` and UBR comparisons confirmed in the wild |
| `iso: only` | Atlas, P+ | `atlas/.../atlas/components.yml:38-42` (`!registryKey` on `HKLM\OfflineSys\...`); `privacyplus/.../software.yml:82` (`!download`) | documented | none (see §6.3 for `OfflineSys`) |
| `iso: false` + `oobe: false` | Revi, P+ | `revi/src/Configuration/Tasks/packages/app-win32.yml:49`; on `!status` too: `privacyplus/.../software.yml:152` | documented | Shows `!status` takes `iso`/`oobe`/`cpuArch` like any action |
| `oobe: true` / `only` / `false` | Atlas, Revi | `atlas/.../custom.yml:8` (`oobe: false` around `reg load`); `atlas/.../qol/shell/restore-old-context-menu.yml:16` (`oobe: only` fallback); `revi/src/Configuration/Tasks/final.yml:136` (`oobe: only` RunOnce) | documented | Atlas comments that HKCU writes "seem not to work" at OOBE and adds a `reg add` fallback with `oobe: only` |
| `onUpgrade` | Atlas, Revi | action level `atlas/.../atlas/start.yml:36`; file level, see §4 | documented on actions only | file-level use is undocumented |
| `status` inline | P+ | `privacyplus/.../software.yml:76,85` on `!download` / `!run` | documented | none |
| `weight` | all | up to 250 (`privacyplus/.../software.yml`) | 2–5 typical | big weights (100–250) are normal for installs |
| `previousOption`, `onUpgradeVersions` | — | not used anywhere | documented | no real-world sample |

### 2.3 Per-action parameters and values

| Action.param | Used by | Example | Docs say | Gap |
|--------------|---------|---------|----------|-----|
| `!run hideWindow: true` | P+, AME10 | `privacyplus/Configuration/tasks/software.yml:84-90` (`exe: "UGC\\UGC.bat"`, `hideWindow: true`) | not on Run.html | **Undocumented parameter.** Presumably hides the console window. |
| `!run path:` with env vars | Revi | `revi/src/Configuration/Tasks/start.yml:71` `path: "%ProgramFiles%\\Revision Tool"` | `path` = directory | Shows env vars expand in `path` |
| `!run exe:` subfolder of Executables | P+ | `privacyplus/.../software.yml:87` `exe: "UGC\\UGC.bat"` with `exeDir: true` | not stated | Sub-folders under `Executables/` work |
| `!run exe: 'PowerShell'` + `-File x.ps1` | Revi | `revi/src/Configuration/Tasks/start.yml:63-67` | — | Alternative to `!powerShell` that waits by default (`!run` defaults to `wait: true`) |
| `!run runas: currentUser, wait: false` | Atlas | `atlas/.../custom.yml:54` (restart `explorer.exe`) | documented | none |
| `!run showOutput/showError: false` | Revi | `revi/src/Configuration/Tasks/revert.yml:21` | documented | none |
| `!powerShell handleExitCodes: {"!0": halt}` | Atlas | `atlas/.../custom.yml:44` | comparisons documented | Confirms the `'!0'` key form. No playbook uses `show`. |
| `!powerShell`/`!cmd` `wait: true` | Atlas (69 of 75), Revi | `atlas/.../atlas/appx.yml:18` | default `false` | Matches CLAUDE.md: set `wait: true` when order matters |
| `!registryValue` **without `value`** | Atlas | `atlas/.../qol/show-all-tasks-control-panel.yml:5,19,23,27` | `value` required | Writes the key's (Default) value. Revi spells it `value: ''` (`revi/.../explorer/context-menu.yml:8`). Prefer `value: ''`. |
| `!registryValue scope: defaultUser` | P+, AME10 | `privacyplus/Configuration/tasks/regedits.yml:336` | `defaultUsers` (RegistryValue.html, rechecked live 2026-10-09) | **Spelling conflict.** Either AME parses both, or this line silently fails. Use `defaultUsers` and test. |
| `!registryValue data:` unquoted int | P+ | `privacyplus/.../software.yml:32` `data: 0` | examples quote `'1'` | Both forms accepted |
| `REG_MULTI_SZ` data | P+, Revi | `privacyplus/.../regedits.yml:25` `data: 'bowser\0mrxsmb20\0nsi'` | type listed, format not | Items separated by a literal `\0` in a single-quoted string |
| `REG_BINARY` data | Atlas, Revi | `atlas/.../qol/visual-effects.yml:13` `data: '9012038010000000'` | type listed, format not | Plain hex string, no separators |
| `REG_NONE` with `data: ''` | Atlas | `atlas/.../qol/shell/set-unpinned-notification-items.yml:12` | type listed | works with empty data |
| `!registryKey` without `operation` | P+, Revi | `privacyplus/.../services.yml:11-12` | default `delete` | Bare `!registryKey: {path: ...}` **deletes**. Be careful when copying. |
| `!service startup: 1` | Revi | `revi/src/Configuration/Tasks/revert.yml:33,40` (`bam`, `Beep`) | valid values 2/3/4 (Service.html, rechecked live) | **Undocumented value** (1 = System start for drivers). |
| `!service` wildcard name | P+ | `privacyplus/.../services.yml:60` `name: "webthreatdefusersvc*"`; `privacyplus/.../config.yml:19` `"WpnUserService*"` | not mentioned | Catches per-user service instances (`*_xxxxx`) |
| `!service device: true` | P+ | `privacyplus/.../services.yml:7-10` (`applockerfltr`, `operation: stop`) | documented | none |
| `!service deleteUsingRegistry: true` | P+ | `privacyplus/.../services.yml:63-66` | documented | none |
| `!service` with no `operation` | P+ | `privacyplus/.../services.yml:29-30` (`UsoSvc`) | default `delete` | Bare `!service` **deletes**. |
| `!file` wildcard path | P+ | `privacyplus/.../files.yml:555` `...\DeletedAllUserPackages\Microsoft.WindowsMaps*` | not mentioned | Wildcards in `!file` look supported |
| `!taskKill name: 'x.exe'` | P+ | `privacyplus/.../components.yml:424-425` (`'ai.exe'`, `'Copilot.exe'`) | "without `.exe`" | **Contradicts docs.** AME may strip it, or these lines may do nothing. Follow the docs. |
| `!taskKill` wildcard + `pathContains` | Revi | `revi/src/Configuration/Tasks/packages/app-win32.yml:11-12` (`"MicrosoftEdge*"`, `pathContains: "\\Edge"`) | documented | none |
| `!scheduledTask operation: enable/disable` without `data` | Atlas | `atlas/.../debloat/disable-scheduled-tasks.yml:6`, `atlas/.../debloat/config-storage-sense.yml:25` | `data` optional | Plain enable/disable needs no XML |
| `!appx type: app` | P+ | `privacyplus/Configuration/tasks/appx.yml:55` (`'*WebExperienceHost*'`) | documented | none |
| `!download cpuArch`, `package`, `overwrite` | Revi | `revi/src/Configuration/Tasks/software.yml:17-22` | documented | none |
| `!download git` + `regex` + `iso: only` | P+ | `privacyplus/.../software.yml:75-82` | documented | none |
| `!software source: chocolatey` | Revi, P+ | `privacyplus/.../software.yml:53` | enum `Chocolatey`, example lowercase | lowercase is what ships |
| `!software iso: false, oobe: false` | P+ | `privacyplus/.../software.yml:153-156` ("Doesn't work in OOBE, investigate") | default overrides both to `true` | Explicit values override the `!software` defaults |
| `!systemPackage arch/language` | P+ | `privacyplus/.../components.yml:150` | documented | none |

---

## 3. playbook.conf

### 3.1 Elements

| Element | Atlas | Revi | P+ | AME10 | Docs | Notes |
|---------|:-----:|:----:|:--:|:-----:|------|-------|
| `<?xml ...?>` declaration | **no** | yes | yes | yes | shown in every example | Atlas `playbook.conf:1` starts with `<Playbook>`; it loads anyway |
| CDATA in `Description` / `ProgressText` | yes | — | — | — | not mentioned | `atlas/src/playbook/playbook.conf:6,13`; Unicode box-drawing works |
| `<Overhaul>true</Overhaul>` | yes | — | yes | yes | **undocumented** | `atlas/.../playbook.conf:32`, `privacyplus/playbook.conf:11`. Meaning unknown; probably marks a playbook that heavily rewrites Windows. |
| `<EstimatedMinutes>15</EstimatedMinutes>` | yes | — | — | — | **undocumented** | `atlas/.../playbook.conf:36`. Probably shown in the wizard. |
| `<UseKernelDriver>false` | yes | yes | — | — | documented | |
| `<UpgradableFrom>` | `0.4.1` | `any` | `0.6-0.7` | — | `1.0`, `1.0.0-1.5.0`, `any`, list | P+ shows two-part-version ranges (`privacyplus/playbook.conf:36`) |
| `<AllowUnsupportedUpgrades>false` | yes | — | — | — | documented (`False`) | lowercase `false` ships |
| `<InstallGuide>` without `FreshInstall` | yes | — | — | — | "used with FreshInstall" | `atlas/.../playbook.conf:31` |
| `<ProductCode>` | 64 | 32 | 117 | yes | documented | Strip from anything forked (CLAUDE.md rule 2) |
| `<SupportedBuilds>` | 26100, 26200 | 19044, 19045, 22631, 26100, 26200 (+28000, 26300 in git) | 22000, 22621, 22631, 22635, 26100, 26200 | 19044, 19045 | documented | Our three target builds are all shipped by Revi and P+ |
| `<Version>` | `0.5.0` | `26.04` | `0.8.2` | `0.8` | 1–3 numbers | CalVer `26.04` is fine |
| Element order | free | free | free | free | not stated | Atlas puts `UniqueId` after `Requirements` |
| `<Requirements>` present | yes | yes | yes | yes | optional | Atlas `dependencies/local-build.ps1:112`: "0.6.5 has a bug where it will crash without the 'Requirements' field". Always include it, even empty. |

UniqueId note: Atlas uses `00000000-0000-4000-6174-6c6173203a33`
(`atlas/src/playbook/playbook.conf:30`, hex for "atlas :3"). Its version nibble is
4 but the variant nibble is not RFC 4122, so it is not a random UUIDv4 and
AME does not check one. Ours stays a real random v4 and never changes.

### 3.2 Requirements

| Requirement | Used by | Documented? |
|-------------|---------|-------------|
| `Internet` | all | yes |
| `NoPendingUpdates` | all | yes |
| `NoAntivirus` | all | yes |
| `DefenderToggled` | Atlas, Revi | yes |
| `DefenderDisabled` | P+, AME10 | yes |
| `UCPDDisabled` | Atlas, P+ | yes |
| `PluggedIn` | Atlas, Revi, P+, AME10 | yes |
| `Activation` | P+, AME10 | yes |
| `AdministratorPasswordSet` | P+, AME10 | yes |
| **`NoTweakware`** | P+, AME10 (`privacyplus/playbook.conf:23`) | **no** (not on requirements.html, rechecked live 2026-10-09) |
| **`LocalAccounts`** | P+, AME10 (`privacyplus/playbook.conf:28`) | **no** |

`NoTweakware` probably blocks when other tweaking tools are detected (the
apply guide tells users to remove "tweaking tools"). `LocalAccounts` probably
requires local (not Microsoft) accounts. Both are guesses until tested in a VM.

### 3.3 FeaturePages

| Construct | Example | Docs | Gap |
|-----------|---------|------|-----|
| `IsRequired="true"` on **RadioPage** and **RadioImagePage** | `atlas/.../playbook.conf:57`; `revi-apbx/playbook.conf:59-60` | pages.html lists `IsRequired` as shared | none; widely used |
| `DependsOn="software"` where no option is called `software` | `revi-apbx/playbook.conf:59` | must name an option on a previous page | **Revi copies the docs example literally.** Either AME ignores an unknown `DependsOn`, or Revi's browser page never shows. Unknown. |
| `DependsOn` on a checkbox option | `atlas/.../playbook.conf:141` (`install-another-browser`); `privacyplus/playbook.conf:180,214,235,263` (`software`) | documented | none |
| Several CheckboxPages in a row | Atlas (3), Revi (3) | — | fine |
| `CheckboxOption` with no `IsChecked` | Atlas, P+ | default `true` | confirmed usage |
| `BottomLine` with `Text` only, emoji | `revi-apbx/playbook.conf:105` | `Link` optional | fine |
| `&amp;` in `<Text>` | `revi-apbx/playbook.conf:118` | — | normal XML escaping |
| Stray text after `</Text>` | `revi-apbx/playbook.conf:122` (`</Text>s`) | — | a typo that shipped; shows the XML reader tolerates mixed content |
| Short `Description` ("General configuration options", 29 chars) | `revi-apbx/playbook.conf:147` | 50–85 characters | the length is advice, not enforced |

### 3.4 Software / OOBE / ISO

| Construct | Example | Docs | Gap |
|-----------|---------|------|-----|
| `<Package ... DefaultWebBrowser="true">` | `privacyplus/playbook.conf:51,57,63,69`; `revi-apbx/playbook.conf:45,51` | **undocumented attribute** | Marks a browser package; probably sets it as the default browser at OOBE |
| `Package Option` set to a **CheckboxOption** (`software`, `ame-tools`) | `privacyplus/playbook.conf:123,129,135,141` | example uses a radio option | Any option name works; several packages can share one |
| `Package <Name>` with no `package:` action | P+ `settings`, `appfetch`, `nomacs` | "should match a `package` property" | Visual only; no matching action needed |
| `<OOBE><Internet>Force</Internet>` | `atlas/.../playbook.conf:50` | documented | |
| `<OOBE><Internet>Request</Internet>` | `revi-apbx/playbook.conf:42` | documented | |
| No `<Internet>` (commented out) | `privacyplus/playbook.conf:43` | optional | |
| BulletPoint text far longer than the examples | `atlas/.../playbook.conf:43-48` | "must roughly match" | not enforced at load |
| `<ISO>` block identical in all three ISO playbooks | `DisableBitLocker`, `DisableHardwareRequirements` = `true` | documented | none |

### 3.5 Images and icon

- Atlas and Revi: `playbook.png` at the root, `Images/` holds RadioImage/Package art.
- P+ and AME10: **no root `playbook.png`**; `Images/playbook.png` instead
  (`privacyplus/Images/playbook.png`). The RadioImagePage page allows this
  (recon §2). Root placement also works.
- `Images/*.png` names match `FileName` (no extension) and `Icon` (with
  extension), as documented.

---

## 4. Task-file top-level keys

tasks.html (rechecked live 2026-10-09) documents `title` (required), `option`,
`options` and `builds`.

| Key | Used by | Example | Documented? |
|-----|---------|---------|-------------|
| `title` | all 313 files | — | yes |
| `actions` | all | — | implied |
| **`description`** | all 313 files | `revi/src/Configuration/Tasks/start.yml:3` `description: Copies Revision folders/files, ...` | **no** |
| **`privilege`** | Revi (53/53 files), P+/AME10 (8/8), Atlas (1/191) | `TrustedInstaller`: `revi/src/Configuration/Tasks/start.yml:4`, `atlas/.../atlas/revert.yml:3`; `Admin`: `revi/src/Configuration/main.yml:4`, `privacyplus/Configuration/main.yml:4` | **no** |
| **`onUpgrade`** (file level) | Atlas (6), Revi (1) | `atlas/.../atlas/components.yml:3` `onUpgrade: false`; `revi/src/Configuration/Tasks/revert.yml:5` `onUpgrade: true` | **no** (actions only) |
| `option` (file level) | Atlas, Revi | `atlas/.../scripts/script-core-isolation.yml:3`; `revi/.../system/disable-automatic-maintenance.yml:5` (unquoted) | yes |
| `builds` (file level) | Atlas (12) | `atlas/.../qol/shell/restore-old-context-menu.yml:4` `builds: [ '>=22000' ]` | yes |
| YAML `---` start marker | all | line 1 of every file | harmless |

`privilege` reading: the entry file says `Admin` and each task file says
`TrustedInstaller`, so it probably sets the default privilege for actions in that
file. Our docs give `trustedInstaller` as the default `runas`, so `privilege:
TrustedInstaller` would be a no-op. **Unknown; do not rely on it.** Set `runas`
on each action that needs another level.

---

## 5. Entrypoint and `!task` paths

| Playbook | Entrypoint | `!task` style | Task folder |
|----------|-----------|---------------|-------------|
| Atlas | `Configuration/custom.yml` (no `main.yml`) | `'tweaks\qol\x.yml'`, `'atlas\start.yml'` | `atlas/`, `tweaks/` |
| Revi | `Configuration/main.yml` (`title: Custom`) | `'Tasks\registry\os-info\edition.yml'` | `Tasks/` with sub-folders |
| P+ / AME10 | `Configuration/main.yml` (`title: Custom`) | `'tasks\regedits.yml'` | `tasks/` (lowercase) |

- Paths resolve relative to `Configuration/`, never relative to the calling
  task file (Revi's nested `Tasks/registry.yml` still calls `'Tasks\registry\...'`).
- Backslashes are universal. Forward slashes (our convention, per Task.html)
  are the documented form; both are fine on Windows.
- `custom.yml` still loads in AME Wizard as of Atlas 0.5.0, despite the 2024
  deprecation. We stay on `main.yml`.

---

## 6. Conventions

### 6.1 Quoting and escaping

- Registry paths are single-quoted almost everywhere (`'HKLM\SOFTWARE\...'`), as
  in our docs.
- P+ often double-quotes with escaped backslashes:
  `path: "%windir%\\System32\\wuaueng.dll"` (`privacyplus/Configuration/tasks/files.yml:152`),
  `path: "HKLM\\System\\CurrentControlSet\\Services\\WdNisDrv"` (`services.yml:12`).
  It means the same thing in YAML. Single quotes are simpler.
- **PowerShell inner double quotes are written `"""`.** AME wraps the command as
  `-C "<command>"`, so Atlas triples literal quotes:
  `'& """.\AtlasModules\Scripts\ScriptWrappers\RemoveEdge.ps1""" -UninstallEdge'`
  (`atlas/.../atlas/components.yml:19`, `atlas/.../custom.yml:39-40`). Our docs
  do not mention this. Use single quotes inside PowerShell where you can.
- Multi-line commands use `|` (Atlas, `custom.yml:18`) or `>-` (Revi,
  `start.yml`). With `>-`, statements need `;` because newlines fold to spaces
  (Revi ends lines with `;`).

### 6.2 Environment variables

Expanded in `!file path`, `!run path/exe/args`, `!cmd command` and registry
`data` strings. Counts across Atlas, Revi and P+:

| Variable | Uses | Example |
|----------|-----:|---------|
| `%windir%` / `%WINDIR%` | 257 | `privacyplus/.../files.yml:301` |
| `%SystemDrive%` / `%SYSTEMDRIVE%` | 70 | `privacyplus/.../components.yml:152` |
| `%ProgramFiles%` | 45 | `revi/.../start.yml:71` |
| `%SystemRoot%` | 38 | `revi/.../final.yml:137` |
| `%ProgramW6432%` | 14 | `privacyplus/.../files.yml:555` |
| `%ProgramFiles(x86)%` | 9 | `privacyplus/.../components.yml:31` |
| `%ProgramData%` | 6 | `revi/.../app-win32.yml:51` |
| `%APPDATA%`, `%USERPROFILE%`, `%localappdata%` | few | `privacyplus/.../files.yml:639`; `revi/.../software.yml:48` |

Caveats:
- `%APPDATA%`/`%USERPROFILE%`/`%LOCALAPPDATA%` resolve for the account the action
  runs as. Under the default `trustedInstaller` that is the system profile, not
  the user's. P+ uses `%APPDATA%` in `!file` (`files.yml:639`); Revi uses
  `%localappdata%` in a `!cmd` with no `runas` (`software.yml:48`). Do not rely on
  either for user data.
- P+ writes `%USERPROFILE%\Desktop` as **REG_SZ** into `User Shell Folders`
  (`privacyplus/.../components.yml:175`). Windows expects REG_EXPAND_SZ there.
  Don't copy it.
- In `!powerShell`, use `$env:SystemRoot` or `[Environment]::GetFolderPath('Windows')`
  (Atlas `custom.yml:19`; Revi `final.yml`).

### 6.3 Registry hives and HKCU scope

| Pattern | Used by | Example | Notes |
|---------|---------|---------|-------|
| `HKCU\...` | all | everywhere | docs: applied to all user hives (scope `allUsers`) |
| `HKU\.DEFAULT\...` mirroring HKCU writes | Revi (127 writes) | `revi/src/Configuration/Tasks/registry/explorer/explorer.yml:60` | `.DEFAULT` is the LocalSystem profile (logon screen), **not** the template for new users. Revi writes it for logon-screen consistency. |
| `HKU\S-1-5-18\...` | Revi (13) | `revi/src/Configuration/Tasks/registry/misc/classic-photo-viewer.yml:67` | the same hive as `.DEFAULT`, by SID |
| `HKU\AME_UserHive_Default\...` | Atlas | `atlas/.../qol/appearance/atlas-theme.yml:59`, `atlas/.../misc/add-newUser-script.yml:6` | Atlas loads it itself: `reg load HKU\AME_UserHive_Default C:\Users\Default\NTUSER.DAT` (`custom.yml:7`, `oobe: false`), copies HKCU tweaks across with `Executables/APPLYDUHIVE.ps1`, then unloads (`custom.yml:101`). The name suggests it matches AME's own mount name for the default hive. **Unproven.** The documented route is `scope: defaultUsers`. |
| `HKLM\OfflineSys\...` with `iso: only` | Atlas | `atlas/.../atlas/components.yml:38-42` (`HKLM\OfflineSys\ControlSet001\Services\WdBoot`, delete) | **Undocumented.** Implies AME mounts the offline image's SYSTEM hive at `HKLM\OfflineSys` during injection. Probably other offline hives too (names unknown). |
| `HKEY_CLASSES_ROOT\...` long form | P+ | `privacyplus/.../regedits.yml:109` | long names accepted alongside `HKCR` |
| `HKCR\...` | all | `revi/.../explorer/context-menu.yml:12` | fine |
| Hard-coded user SID | P+, AME10 | `privacyplus/.../components.yml:113` (`HKU\S-1-5-21-3476428458-...-1002\...`) | an author's machine SID that shipped by mistake; a no-op elsewhere. **Never do this** (CLAUDE.md rule 7). |

### 6.4 How Executables are called

| Pattern | Example |
|---------|---------|
| `!run` + `exeDir: true` + bare file name | `revi/src/Configuration/Tasks/final.yml:57` `{exeDir: true, exe: "FINALIZE.cmd", weight: 200}` |
| `!run` sub-folder | `privacyplus/.../software.yml:87` `exe: "UGC\\UGC.bat"` |
| `!powerShell` + `exeDir: true` + `.\SCRIPT.ps1` | `atlas/.../custom.yml:12` `command: '.\STOPFOLDERPROC.ps1'` |
| `!cmd` + `exeDir: true` + bare name | `atlas/.../custom.yml:48` `command: "DISABLENOTIFS.cmd"` |
| `!cmd` + `exeDir: true` copying a folder out | `revi/src/Configuration/Tasks/start.yml:16-19` `robocopy "Licenses" "%SystemDrive%\Licenses" /E ...` with `ignoreErrors: true` (robocopy returns 1 on success) |
| `!run exe: "PowerShell"` + `args: '-NoP -ExecutionPolicy Bypass -File x.ps1'` | `revi/src/Configuration/Tasks/start.yml:63-67` |
| Copy a payload folder into `%windir%` and run scripts from there | Atlas `custom.yml:28-44` (AtlasModules / AtlasDesktop) |
| `!download` with no root path → lands in Executables, then `!run exeDir` | `revi/src/Configuration/Tasks/software.yml:17-27` |

P+ ships an `Executables/ISO/` folder whose calls are all commented out
(`privacyplus/.../services.yml:166`, `regedits.yml:16-20`). That suggests separate
OOBE variants of scripts were tried and dropped.

### 6.5 Other runtime facts

- **Logs:** Atlas's live-log helper tails
  `%ProgramData%\AME\Logs\<newest sub-folder>\OutputBuffer.txt`
  (`atlas/src/dependencies/local-build.ps1:129-132`). So logs are written to a
  **per-run sub-folder**, and `OutputBuffer.txt` is a third file besides
  `Output.txt` and `Log.yml` (recon §13).
- **Packaging:** `atlas/src/dependencies/local-build.ps1:208-209`:
  `7z a -spf -y -mx1 -pmalte -tzip <name>.apbx`, a **ZIP** with the `malte`
  password. creating_playbooks.html says 7z. So AME accepts both containers.
  Our `tools/package.py` writes 7z with `set_encrypted_header(True)`. ReviOS's
  release workflow does the same (`revi/.github/workflows/main.yml:59`:
  `7z a -pmalte -mhe=on`), and the ReviOS 26.04 `.apbx` hides its file list
  without the password, so header encryption is proven to load. Privacy+ 0.8.2
  does not encrypt names, so both work.
- Atlas's build strips `<ProductCode>`, `<Requirement>` and `<SupportedBuilds>`
  lines for local test builds (`local-build.ps1:111-116`). That is a useful
  pattern for VM testing on unsupported builds.

---

## 7. Where our docs disagree with shipped playbooks

| Our docs say | Shipped playbooks show | Verdict |
|--------------|------------------------|---------|
| Use `!status`; `!writeStatus` is an unconfirmed alias (recon §15, action-catalog) | Atlas 0.5.0 and ReviOS 26.04 use `!writeStatus` 36/32 times | `!writeStatus` **is** accepted. Keep `!status` by convention. |
| Forward slashes in `!task` paths | Every reference uses backslashes | Both work. Keep forward slashes. |
| `custom.yml` is deprecated | Atlas 0.5.0's only entrypoint is `custom.yml` | Still loads. Keep `main.yml`. |
| Task files: `title`, `option`, `options`, `builds` | Also `description`, `privilege`, `onUpgrade` | Undocumented keys are accepted. Meaning of `privilege` is unproven. |
| `!registryValue` `value` is required | Atlas omits it for the default value | Optional in practice. Prefer `value: ''`. |
| `scope` enum has `defaultUsers` | P+ ships `defaultUser` | Unresolved; follow the docs and test. |
| `!service startup` valid values 2/3/4 | Revi ships `startup: 1` | Undocumented value; treat as unproven. |
| `!taskKill name` without `.exe` | P+ ships `'ai.exe'`, `'Copilot.exe'` | Follow the docs. |
| `cpuArch`: prefer `X64`, case unknown | P+ ships `"x64"` | Probably case-insensitive. Keep `X64`. |
| `ignoreErrors` deprecated | Atlas, Revi and P+ 0.8.2 still use it | Still parsed. Keep `errorAction`. |
| `.apbx` is a 7z archive | Atlas builds a password-protected ZIP | Both load. |
| playbook.conf starts with `<?xml ...?>` | Atlas has none | Optional. Keep it. |
| `DependsOn` must name an option on a previous page | Revi uses `DependsOn="software"` with no such option | Unknown effect. Never copy it. |
| Requirements list (12 values) | `NoTweakware`, `LocalAccounts` also ship | Undocumented values exist. |
| conf fields listed in recon §3 | `Overhaul`, `EstimatedMinutes`, `Package@DefaultWebBrowser` also ship | Undocumented fields exist. |
| Logs at `C:\ProgramData\AME\Logs` (`Output.txt`, `Log.yml`) | Logs sit in per-run sub-folders, plus `OutputBuffer.txt` | Refine recon §13 after the first VM run. |

Rechecked live on 2026-10-09: RegistryValue.html (`defaultUsers`),
Service.html (startup 2/3/4), requirements.html (no `NoTweakware` or
`LocalAccounts`) and tasks.html (`title`, `option`, `options`, `builds` only).
None of these live pages has changed, so recon §15 needs no conflict entry.
These are gaps between the docs and real-world use, not doc-vs-doc conflicts.

---

## 8. Validator changes (`tools/validate.py`)

Accepted because shipped playbooks use them (each prints a **warning**, not an error):

- `!writeStatus` (alias of `!status`, same parameters).
- Backslash `!task` paths (the path still has to exist).
- `Configuration/custom.yml` as entrypoint when `main.yml` is absent.
- `!registryValue` with no `value`.
- Task-file keys `description`, `privilege` (`TrustedInstaller`/`Admin`) and
  `onUpgrade`; these are accepted silently.
- `!run hideWindow`, `scope: defaultUser`, `!service startup: 0/1`,
  non-canonical `cpuArch` case.
- conf `<Overhaul>`, `<EstimatedMinutes>`; requirements `NoTweakware`,
  `LocalAccounts`; a UniqueId with version 4 but a non-RFC variant (Atlas).

New checks (**errors**), to catch real typos:

- Unknown parameters on any action (shared plus per-action table).
- Bad enum values: `errorAction`, `runas`, `iso`, `oobe`, `scope`, `cpuArch`,
  registry `type`/`operation`, `!appx`/`!service`/`!scheduledTask`/`!systemPackage`
  enums, `handleExitCodes` handlers (`show` is a warning).
- Unknown task-file top-level keys and `privilege` values.
- Unknown playbook.conf top-level elements and requirement values.
- `!service operation: change` without `startup`; `!download git` without `regex`.
- List-typed params (`builds`, `options`, …) given as scalars.

New warnings: missing `<?xml ?>` declaration; missing `<Requirements>` (Atlas notes
AME Wizard 0.6.5 crashed without it); `DependsOn` or `Package Option` naming no
option. Option names now come only from `<FeaturePages>`; before, `<Software>`
package names counted as options too.

Results (`python3 tools/validate.py <dir>`):

| Tree | Before | After |
|------|--------|-------|
| `playbook/` (ours) | 0 errors, 0 warnings | 0 errors, 1 warning (no `<Requirements>`) |
| Atlas | 222 errors | **0 errors**, 239 warnings |
| Revi | 84 errors | **0 errors**, 95 warnings |
| Revi-apbx | 83 errors | **0 errors**, 94 warnings |
| P+ | 7 errors | **0 errors**, 24 warnings |
| AME10 | 7 errors | **0 errors**, 22 warnings |

Before, the errors were all `!writeStatus`, backslash `!task` paths (the
validator joined `Tasks\x.yml` as one Linux file name), Atlas's missing
`main.yml`, the four value-less `!registryValue`s and Atlas's UniqueId variant.
Most remaining warnings are style (`!writeStatus`, backslashes, `ignoreErrors`).
