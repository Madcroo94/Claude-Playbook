# Action Catalog — AME Beta Playbook Cheat Sheet

Parameters fetched live from https://docs.amelabs.net/developers/actions/ on 2026-10-08.
Shared parameters: https://docs.amelabs.net/developers/actions.html

Quick rules:
- Use **single quotes** for strings, especially registry paths.
- YAML tags are camelCase.
- Canonical status tag is **`!status`** (see reconnaissance.md §15).
- `!file` is documented at File.html but omitted from the actions index.

---

## Shared parameters (every action)

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `weight` | integer | 2–5 for most | Progress-bar increment. **Not supported on `!status`.** |
| `status` | string | None | Inline status; alternative to a separate `!status` action. |
| `errorAction` | enum | varies | `Ignore` / `Log` / `Notify` / `Halt`. Replaces deprecated `ignoreErrors`. |
| `option` | string | None | Run only if named option selected. Prefix `!` to invert. |
| `options` | string[] | None | Run if any listed option selected (OR). |
| `builds` | string[] | None | `'22621'`, `'>=22621'`, `'!>22625'`, UBR `'22621.1265'`. |
| `cpuArch` | string | None | .NET `Architecture` enum. Docs example `"X64"`. yaml.html example `"x64"`. Prefer `X64`. |
| `onUpgrade` | bool | false | Run during version upgrade. |
| `onUpgradeVersions` | string[] | None | Previous versions that trigger `onUpgrade`. Same comparison syntax. |
| `previousOption` | string | None | Old option name when renaming. `ignore` = always run on upgrade. |
| `iso` | enum | false | `true` / `false` / `only`. |
| `oobe` | enum? | null | `null` / `true` / `false` / `only`. `null` = run at OOBE unless `iso: true/only`. |

---

## handleExitCodes (`!run`, `!cmd`, `!powerShell`)

Documented handlers:

| Handler | Meaning |
|---------|---------|
| `log` | Create a log entry |
| `error` | Throw an error |
| `halt` | Halt the Playbook |
| `retry` | Re-run the action (`!run`: up to 5 times; `!cmd`/`!powerShell`: “re-run the action”) |
| `retryError` | Re-run up to 5 times, then throw if the exit code never changes |

Example: `handleExitCodes: {1: log, 2: error, 3: halt, -1: retry}`

Comparisons: `handleExitCodes: {'!0': log, '>=1': show}` — **`show` is not in the handler list.** Do not use it until a VM confirms it.

---

## !run

Runs an executable or file.
Source: https://docs.amelabs.net/developers/actions/Run.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `exe` | YES | string | — | Filename, optionally with full path. |
| `path` | no | string | None | Directory for the executable. |
| `args` | no | string | None | Command-line arguments. |
| `baseDir` | no | bool | false | Working dir = amelioration directory. |
| `exeDir` | no | bool | false | Working dir = Playbook Executables folder. |
| `runas` | no | enum | `trustedInstaller` | `currentUser` / `currentUserElevated` / `system` / `trustedInstaller` |
| `timeout` | no | integer | None | Kill + error if reached. **Unit not documented.** |
| `wait` | no | bool | true | Wait for process exit. |
| `handleExitCodes` | no | dict | None | See table above. |
| `showOutput` | no | bool | true | Forward stdout to the log. |
| `showError` | no | bool | true | Forward stderr to the log. |

```yaml
- !run:
  exe: 'DISM'
  args: '/Online /Disable-Feature /FeatureName:"SmbDirect" /NoRestart'
  weight: 30
- !run: {exe: 'EXAMPLE.bat', exeDir: true}
- !run: {exe: 'winget', args: 'install M2Team.NanaZip', runas: currentUserElevated}
```

Dynamic (`!run` / `!cmd` / `!powerShell`) is **not allowed during ISO injection**.

---

## !registryKey

Adds or deletes a registry key.
Source: https://docs.amelabs.net/developers/actions/RegistryKey.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `path` | YES | string | — | Full registry path. |
| `operation` | no | enum | `delete` | `delete` / `add` |
| `scope` | no | enum | `allUsers` | HKCU only: `allUsers` / `currentUser` / `activeUsers` / `defaultUsers` |

```yaml
- !registryKey: {path: 'HKLM\SOFTWARE\Example\Key', operation: delete}
- !registryKey: {path: 'HKCU\SOFTWARE\Example\Key', operation: add, scope: allUsers}
```

---

## !registryValue

Modifies a registry value. HKCU applies to all user hives by default.
Source: https://docs.amelabs.net/developers/actions/RegistryValue.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `path` | YES | string | — | Path to the key. |
| `value` | YES | string | — | Value name. |
| `type` | YES* | enum | — | *Not required when deleting. `REG_SZ` / `REG_MULTI_SZ` / `REG_EXPAND_SZ` / `REG_DWORD` / `REG_QWORD` / `REG_BINARY` / `REG_NONE` / `REG_UNKNOWN` |
| `data` | YES* | any | — | *Not required when deleting. |
| `operation` | no | enum | `add` | `add` / `delete` / `set` |
| `scope` | no | enum | `allUsers` | HKCU: `allUsers` / `currentUser` / `activeUsers` / `defaultUsers` |

```yaml
- !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting', value: 'Disabled', type: REG_DWORD, data: '1'}
- !registryValue: {path: 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced', value: 'Hidden', type: REG_DWORD, data: '1'}
- !registryValue: {path: 'HKLM\SOFTWARE\Example', value: 'OldValue', operation: delete}
```

---

## !appx

Removes an APPX family/package/app, or clears its cache.
Source: https://docs.amelabs.net/developers/actions/Appx.html

If unsure, leave `type` at default **family**.

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `name` | YES | string | — | Supports `*` on either side or both. |
| `operation` | no | enum | `remove` | `remove` / `clearCache` |
| `type` | no | enum | `family` | `family` / `package` / `app` |
| `verboseOutput` | no | bool | false | Verbose log output. |
| `unregister` | no | bool | false | If true, program files are not deleted. |

After bulk removals, docs recommend clearing start/search cache:

```yaml
- !appx: {name: '*disney*', type: family}
- !appx: {name: '*PowerAutomate*', type: family}
- !appx: {name: '*MicrosoftTeams*', type: family}
- !appx: {operation: clearCache, name: '*Client.CBS*'}
- !appx: {operation: clearCache, name: '*StartMenuExperienceHost*'}
- !appx: {operation: clearCache, name: '*Windows.Search*'}
```

---

## !file

Deletes a file or directory. Stops non-critical processes locking the target.
Source: https://docs.amelabs.net/developers/actions/File.html

**Not listed on the actions index.** Dedicated page exists; treat as official.

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `path` | YES | string | — | File or directory path. |

No optional parameters on the page.

```yaml
- !file: {path: 'C:\Windows\System32\example.exe'}
```

---

## !service

Modifies a Windows service. (Actions index blurb is a copy-paste of `!cmd`. Ignore it.)
Source: https://docs.amelabs.net/developers/actions/Service.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `name` | YES | string | — | Service name. |
| `startup` | YES* | int | — | *Required only for `operation: change`. 2=Automatic, 3=Manual, 4=Disabled. |
| `operation` | no | enum | `delete` | `stop` / `continue` / `start` / `pause` / `delete` / `change` |
| `deleteStop` | no | bool | true | Wait for stop before delete. |
| `device` | no | bool | false | Target is a device driver. |
| `deleteUsingRegistry` | no | bool | false | Delete via registry (permission bypass). |
| `scope` | no | enum | `allUsers` | Documented even though this is not an HKCU hive edit. |

```yaml
- !service: {name: 'DiagTrack', operation: delete}
- !service: {name: 'wuauserv', operation: change, startup: 4}
- !service: {name: 'wuauserv', operation: delete, iso: true}
```

---

## !scheduledTask

Deletes a task or folder; can also enable/disable (and create via XML).
Source: https://docs.amelabs.net/developers/actions/ScheduledTask.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `path` | YES | string | — | Must start with `\` (task scheduler root). |
| `operation` | no | enum | `delete` | `delete` / `deleteFolder` / `enable` / `disable` |
| `data` | no | string | None | Raw task XML. Only for `enable` / `disable`. |

```yaml
- !scheduledTask: {path: '\Microsoft\Windows\Windows Defender', operation: deleteFolder}
- !scheduledTask: {path: '\Microsoft\Windows\XblGameSave\XblGameSaveTask', operation: delete}
```

The official `deleteFolder` example mixes quotes (`'..."`). Use matching single quotes.

---

## !taskKill

Terminates a process.
Source: https://docs.amelabs.net/developers/actions/TaskKill.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `name` | YES | string | — | Process name **without** `.exe`. `*` wildcard on either/both sides. |
| `pathContains` | no | string | None | Path must contain this string (disambiguates `setup`). |

```yaml
- !taskKill: {name: 'OneDrive'}
- !taskKill: {name: 'setup', pathContains: 'OneDrive'}
```

---

## !systemPackage

Removes a Windows component by manifest name, plus dependents.
Source: https://docs.amelabs.net/developers/actions/SystemPackage.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `name` | YES | string | — | Component name. |
| `arch` | no | enum | `all` | `amd64` / `wow64` / `x86` / `msil` / `all` |
| `language` | no | string | `*` | Any language. Examples often use `neutral`. |
| `regexExcludeFiles` | no | string[] | None | Regex of files to keep. |
| `excludeDependents` | no | string[] | None | Dependent component names to spare. |

```yaml
- !systemPackage: {name: 'Microsoft-Windows-CoreSystem-Bluetooth-Telemetry', arch: amd64, language: 'neutral', regexExcludeFiles: ['.*\\BthTelemetry.dll']}
- !systemPackage: {name: 'Microsoft-Windows-SenseClient-Deployment', arch: amd64, language: 'neutral', excludeDependents: ['Windows-SECDriver']}
```

---

## !cmd

Runs `cmd /c "<command>"`.
Source: https://docs.amelabs.net/developers/actions/Cmd.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `command` | YES | string | — | Command string. |
| `exeDir` | no | bool | false | Working dir = Executables folder. |
| `runas` | no | enum | `trustedInstaller` | `currentUser` / `currentUserElevated` / `system` / `trustedInstaller` |
| `timeout` | no | integer | None | Unit not documented. |
| `wait` | no | bool | **false** | Default does **not** wait. Set `true` if you need the result. |
| `handleExitCodes` | no | dict | None | See handleExitCodes. |

```yaml
- !cmd: {command: 'DISM /Online /Disable-Feature /FeatureName:"SmbDirect" /NoRestart', weight: 30}
- !cmd: {command: 'bcdedit /set hypervisorlaunchtype off', wait: true}
```

---

## !powerShell

Equivalent to `PowerShell -NoP -ExecutionPolicy Bypass -NonInteractive -C "<command>"`.
Source: https://docs.amelabs.net/developers/actions/PowerShell.html

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `command` | YES | string | — | Command string. |
| `exeDir` | no | bool | false | Working dir = Executables folder. |
| `runas` | no | enum | `trustedInstaller` | same enum as `!run` |
| `timeout` | no | integer | None | Unit not documented. |
| `wait` | no | bool | **false** | Default does **not** wait. |
| `handleExitCodes` | no | dict | None | See handleExitCodes. |

```yaml
- !powerShell: {command: 'Set-ItemProperty -Path "HKCU:\..." -Name "..." -Value 0', wait: true}
```

---

## !download

Downloads from a URL or git release.
Source: https://docs.amelabs.net/developers/actions/Download.html

**Default ISO behavior:** overrides `iso` to `true` (runs at injection, skipped at OOBE). Set `oobe: true` to also try a newer download at OOBE.

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `destination` | YES | string | — | File name or path. No root → Executables directory. |
| `url` | YES* | string | — | *Required unless `git` is set. |
| `git` | YES* | string | — | *Required unless `url` is set. |
| `regex` | YES** | string | — | **Required with `git`. Use `'.*'` for the first release file. |
| `overwrite` | no | bool | false | Overwrite existing destination. |
| `package` | no | string | None | Match a `Package` `Name` in `playbook.conf`. |

```yaml
- !download:
  option: 'browser-brave'
  url: 'https://github.com/brave/brave-browser/releases/latest/download/BraveBrowserStandaloneSetup.exe'
  destination: 'BraveBrowserStandaloneSetup.exe'
- !run:
  exeDir: true
  exe: 'BraveBrowserStandaloneSetup.exe'
  args: '/silent /install'
  weight: 70

- !download:
  git: 'https://github.com/macchrome/winchrome'
  regex: 'chromium-.*_Win64\.7z'
  destination: 'ugc.7z'
```

---

## !software

Downloads and installs from Chocolatey. More sources / fallbacks are planned.
Source: https://docs.amelabs.net/developers/actions/Software.html

**Default ISO/OOBE:** overrides `iso` and `oobe` to `true` — cache at injection, install at OOBE.

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `source` | YES | enum | — | Listed as `Chocolatey`. Example uses `chocolatey`. |
| `name` | YES | string | — | Package name on that source. |
| `upgrade` | no | bool | true | Upgrade if already installed. |
| `package` | no | string | None | Match a `Package` in `playbook.conf`. |

```yaml
- !software: {name: '7zip', source: chocolatey}
- !software:
  name: 'firefox'
  source: chocolatey
  option: 'browser-firefox'
  package: 'firefox'
  weight: 150
```

---

## !status

Writes a short status on top of the progress bar.
Source: https://docs.amelabs.net/developers/actions/WriteStatus.html

Page title is `!status`. creating_playbooks.html's `main.yml` example uses
`!writeStatus`. Use **`!status`**. Keep messages short.

Does **not** support `weight`.

| Param | Required | Type | Notes |
|-------|----------|------|-------|
| `status` | YES | string | Status text. |

```yaml
- !status: {status: 'Configuring services'}
- !status: {status: 'Removing APPX packages'}
- !status: {status: 'Modifying registry'}
- !status: {status: 'Installing Chocolatey'}
- !status: {status: 'Installing .NET 3.5'}
- !status: {status: 'Configuring features'}
```

---

## !task

Runs another YAML task file.
Source: https://docs.amelabs.net/developers/actions/Task.html

| Param | Required | Type | Notes |
|-------|----------|------|-------|
| `path` | YES | string | Relative path to the task YAML. Prefer `Tasks/file.yml` (forward slashes). |

No optional parameters on the page (shared action parameters still apply).

```yaml
- !task: {path: 'Tasks/registry.yml'}
- !task: {path: 'Tasks/appx.yml'}
- !task: {path: 'Tasks/services.yml', option: 'advanced'}
```

---

## Quick reference: main.yml pattern

```yaml
title: Main
actions:
  - !status: {status: 'Configuring registry'}
  - !task: {path: 'Tasks/registry.yml'}
  - !status: {status: 'Removing APPX packages'}
  - !task: {path: 'Tasks/appx.yml'}
  - !status: {status: 'Configuring services'}
  - !task: {path: 'Tasks/services.yml'}
  - !status: {status: 'Removing scheduled tasks'}
  - !task: {path: 'Tasks/scheduled-tasks.yml'}
  - !status: {status: 'Installing software'}
  - !task: {path: 'Tasks/software.yml'}
```

## Quick reference: domain task file pattern

```yaml
title: Registry Edits
actions:
  - !registryValue: {path: 'HKLM\SOFTWARE\Example', value: 'MyVal', type: REG_DWORD, data: '1'}
  - !registryValue:
    path: 'HKCU\SOFTWARE\Example'
    value: 'AnotherVal'
    type: REG_DWORD
    data: '0'
    option: 'advanced-tweaks'
```
