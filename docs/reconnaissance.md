# Reconnaissance — AME Beta Playbook Developer Notes

All information fetched live from https://docs.amelabs.net/ on 2026-10-08.
Sources cited inline. This brief is meant to let a later session write YAML
without re-fetching the site. If a live page disagrees with this file, the live
page wins — record the conflict in §15.

---

## 1. Repository layout (Claude-Playbook)

```text
CLAUDE.md                      # standing orders for Claude Code sessions
docs/                          # this file, action-catalog.md, playbook.conf.reference.xml
playbook/                      # the playbook source tree (packaged into .apbx)
tools/                         # validate.py, package.py, package.ps1
dist/                          # build output, gitignored
```

---

## 2. Playbook structure

Source: https://docs.amelabs.net/creating_playbooks.html
Also: https://docs.amelabs.net/developers/iso.html (Images/)
Also: https://docs.amelabs.net/developers/verification.html (`playbook.png`)
Also: https://docs.amelabs.net/developers/features/pages/radioimagepage.html

```text
Playbook/                      # root folder name is arbitrary
├── playbook.conf              # XML identity, required
├── playbook.png               # optional 256px icon; recommended for verification
├── Configuration/
│   ├── main.yml               # YAML entrypoint, required
│   └── Tasks/
│       ├── registry.yml
│       └── appx.yml
├── Executables/               # scripts and binaries called by YAML
└── Images/                    # optional; OOBE Software icons + RadioImageOption art
```

Creating Playbooks shows only `playbook.conf`, `Configuration/`, `Tasks/`, and
`Executables/`. `playbook.png` and `Images/` are required by other pages when
those features are used.

`playbook.conf`: metadata (name, version) in XML.
`Configuration`: YAML, starting with `main.yml`.
`Tasks`: action-specific YAML.
`Executables`: scripts or binaries the playbook calls.
`Images`: `Icon` on `<Package>` and `FileName` on `RadioImageOption` point here.
  RadioImagePage notes that `playbook.png` can also live in `Images/`.

Packaged as `.apbx`: 7z archive of the contents above, password **`malte`**.
Encryption exists so browsers and AV do not scan embedded executables.

Packaging steps (7-Zip), source creating_playbooks.html:

1. Select all files and folders **inside** the Playbook root folder.
2. Right-click → 7-Zip → Add to archive…
3. Name with `.apbx` extension, format: 7z.
4. Password: `malte`.

7-Zip download cited by the docs: https://7-zip.org/download.html

---

## 3. playbook.conf — Configuration

Source: https://docs.amelabs.net/developers/configuration.html

XML. Must open with `<?xml version="1.0" encoding="utf-8"?>`. Root element
`<Playbook>`.

UUID generator cited by creating_playbooks: https://tools.namlabs.com/uuidV4/

### Required fields (configuration.html)

| Field | Type | Description |
|-------|------|-------------|
| `Name` | string | Name of the Playbook. |
| `Username` | string | Creator username, displayed in various locations. |
| `UniqueId` | GUID | Unique UUIDv4 (GUID). Fresh for every new playbook. |
| `ShortDescription` | string | Playbooks sidebar. |
| `Title` | string | Primary pages. |
| `Description` | string | First introductory page. Use `&#xD;&#xA;` for newlines. |
| `Details` | string | Updates window description box. |
| `Version` | string | One, two or three dot-separated numbers (`1`, `0.1`, `0.0.1`; so `1.2.16` is fine). |

### Optional fields on configuration.html

| Field | Type | Description |
|-------|------|-------------|
| `SupportedBuilds` | integer array of `<string>` | Windows build numbers (example: `22000`, `22621`). |
| `FeaturePages` | FeaturePage array | See §8. |
| `Requirements` | requirement array | See §4. |
| `ProductCode` | integer | Verification with AME Wizard. Assigned by AME. |
| `ProgressText` | string | Progress window. |
| `Git` | string | Update fetch URL and Source Code button. |
| `Website` | string | Verification dropdown, if verified. |
| `DonateLink` | string | Donate button in updates window. |
| `InstallGuide` | string | Custom docs URL used with `FreshInstall`. |
| `PasswordReplace` | string | Password after converting Microsoft accounts to local. |
| `ISO` | ISO object | See §9. |
| `OOBE` | OOBE object | See §9. |
| `Software` | Package array | OOBE visualization. See §9. |
| `UseKernelDriver` | bool | Kernel driver for higher privileges. Unnecessary in most cases. |

### Fields documented only on other pages

Rechecked 2026-10-09: configuration.html's optional table now also lists
`InstallGuide`, `PasswordReplace`, `ISO`, `OOBE`, `Software` and
`UseKernelDriver`. The three below are still only on iso.html / upgrades.html.

| Field | Source | Description |
|-------|--------|-------------|
| `SupportsISO` | https://docs.amelabs.net/developers/iso.html | `true` enables ISO injection. |
| `UpgradableFrom` | https://docs.amelabs.net/developers/upgrades.html | Previous version, range, `any`, or list of `<string>`. |
| `AllowUnsupportedUpgrades` | https://docs.amelabs.net/developers/upgrades.html | `False` blocks upgrades from versions not in `UpgradableFrom`. |

Example skeleton from configuration.html (UniqueId shown as placeholder text
`UNIQUE ID` in the docs):

```xml
<?xml version="1.0" encoding="utf-8"?>
<Playbook>
    <Name>Example PB</Name>
    <Username>Testing Inc.</Username>
    <ShortDescription>Official Example Playbook for Windows 11</ShortDescription>
    <Title>Windows 11 Example Playbook</Title>
    <Description>This Playbook will test your installation&#xD;&#xA;&#xD;&#xA;The testing process makes heavy alterations to your installation.</Description>
    <Details>Official Example Playbook for Windows 11. Testing your system.</Details>
    <Version>0.1</Version>
    <UniqueId>UNIQUE ID</UniqueId>
    <SupportedBuilds>
        <string>22000</string>
        <string>22621</string>
    </SupportedBuilds>
    <Requirements>
        <Requirement>Internet</Requirement>
        <Requirement>NoPendingUpdates</Requirement>
        <Requirement>DefenderDisabled</Requirement>
        <Requirement>NoAntivirus</Requirement>
    </Requirements>
    <ProgressText>Reticulating splines, improving the user interface experience, installing replacement apps, and testing the system.</ProgressText>
    <Git>https://git.example.com/TestingInc/Example-PB</Git>
</Playbook>
```

---

## 4. Requirements

Source: https://docs.amelabs.net/developers/requirements.html

Declared in `playbook.conf`:

```xml
<Requirements>
    <Requirement>Internet</Requirement>
    <Requirement>NoPendingUpdates</Requirement>
    <Requirement>DefenderToggled</Requirement>
    <Requirement>NoAntivirus</Requirement>
</Requirements>
```

| Requirement | What it checks |
|-------------|----------------|
| `Internet` | Active internet connection required. |
| `NoInternet` | Must not be connected to the internet. |
| `Activation` | Windows must be activated. |
| `FreshInstall` | Installation no more than 40 hours old. Easily bypassable in the UI. Pair with `InstallGuide` for a custom install-docs URL. |
| `DefenderToggled` | User must toggle the primary four Windows Security toggles. |
| `DefenderDisabled` | User must neutralize Defender via the **Prepare System** step. Also causes Defender removal during ISO injection. |
| `UCPDDisabled` | User must disable the UCPD driver via the **Prepare System** step. |
| `NoAntivirus` | WMI class `AntivirusProduct` in `root/SecurityCenter2`. Blocks if a non-Defender entry is found. |
| `NoPendingUpdates` | Blocks until pending or downloading Windows updates are installed. |
| `PasswordSet` | User must set the active account password; converts Microsoft accounts to local. |
| `AdministratorPasswordSet` | User must set the Administrator account password. |
| `PluggedIn` | Device must be plugged in, if it is battery-powered. |

Operator-facing apply flow (https://docs.amelabs.net/installing_playbooks/playbook_apply.html):
install updates and reboot until none pending; remove AV / tweaking tools / OneDrive;
install drivers; back up data; complete **Disable Security** / Prepare System when
the playbook requires it; agree to license; pick features and credentials; wait
for reboot. Failures show a yellow error; logs folder can be zipped for
https://ameliorated.info/support.

---

## 5. YAML formatting rules

Source: https://docs.amelabs.net/developers/yaml.html

Single-line and multi-line are both valid and function the same. Single-line is
preferred when there are many similar actions. Multi-line is preferred when an
action has many properties (`option`, `weight`, `cpuArch`, …).

```yaml
# Multi-line
- !registryValue:
  path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
  value: 'dontdisplaylastusername'
  type: REG_DWORD
  data: '1'

# Single-line
- !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', value: 'dontdisplaylastusername', type: REG_DWORD, data: '1'}
```

**Quoting: use single quotes.**
- Single quotes: text is literal. Backslashes in registry paths need no escaping.
- Double quotes: backslashes must be escaped (`\\`).
- A literal single quote inside a single-quoted string is doubled: `''`.

Actions are camelCase YAML tags (`appx`, `scheduledTask`).
Source: https://docs.amelabs.net/developers/actions.html

---

## 6. Tasks

Source: https://docs.amelabs.net/developers/tasks.html

A task file is a list of actions, or a list of other task files to include
(via `!task`).

### Required

| Param | Type | Description |
|-------|------|-------------|
| `title` | string | Title for the task. |

### Optional

| Param | Type | Description |
|-------|------|-------------|
| `option` | string | Run this task only if the named feature option was selected. |
| `options` | string[] | Run if any listed option was selected. |
| `builds` | string[] | Windows builds. Exact (`'22621'`), comparisons (`'>=22621'`), negatives (`'! >22625'` written as `'!>22625'`), UBR (`'22621.1265'`). |

`main.yml` example from creating_playbooks.html uses `!writeStatus` — see §15.
Canonical pattern from the `!status` page and features-in-yaml:

```yaml
title: Main
actions:
  - !status: {status: 'Modifying registry'}
  - !task: {path: 'Tasks/registry.yml'}
  - !status: {status: 'Removing APPX packages'}
  - !task: {path: 'Tasks/appx.yml'}
```

An older page (https://docs.amelabs.net/developers/getting-started/writing-yaml.html)
uses backslash paths (`Tasks\registry.yml`). Current creating_playbooks and
`!task` examples use forward slashes. Prefer forward slashes.

Changelog 2024-06-12: `custom.yml` was renamed to `main.yml`; sub-tasks are now
`!task` actions so `option` can apply to a whole file. `custom.yml` is
deprecated.

---

## 7. Actions — shared parameters

Source: https://docs.amelabs.net/developers/actions.html

Every action supports:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `weight` | integer | 2–5 for most actions | Progress-bar impact when the action completes. `!status` does **not** support `weight`. |
| `status` | string | None | Inline status string; alternative to the `!status` action. |
| `errorAction` | enum | varies | `Ignore` / `Log` / `Notify` / `Halt`. Replaces deprecated `ignoreErrors` (changelog 2024-06-12). |
| `option` | string | None | Run only if that feature option was selected. Prefix `!` to invert. |
| `options` | string[] | None | Run if any listed option was selected (OR). |
| `builds` | string[] | None | Same comparison syntax as Tasks. |
| `cpuArch` | string | None | Must match a .NET `Architecture` enum value (example given: `"X64"`). See §15. |
| `onUpgrade` | bool | false | Whether to run during an upgrade. |
| `onUpgradeVersions` | string[] | None | Which previous versions trigger `onUpgrade`. Same comparison syntax as `builds`. |
| `previousOption` | string | None | Previous option name for upgrade matching. `ignore` = always run. |
| `iso` | enum | false | `true` / `false` / `only` — ISO injection. |
| `oobe` | enum? | null | `null` / `true` / `false` / `only`. `null` = run during OOBE unless `iso: true/only`. |

Per-action parameters: `action-catalog.md`.

Actions linked from the index:

| YAML tag | Index blurb | Page |
|----------|-------------|------|
| `!run` | runs a specified executable or file | actions/Run.html |
| `!registryKey` | adds or deletes a specified registry key | actions/RegistryKey.html |
| `!registryValue` | modifies a specified registry value | actions/RegistryValue.html |
| `!appx` | removes, or clears the cache of a given APPX component | actions/Appx.html |
| `!service` | index says “executes a specified cmd command” — **wrong; see Service.html** | actions/Service.html |
| `!scheduledTask` | deletes a task folder, or modifies a specific task | actions/ScheduledTask.html |
| `!taskKill` | terminates a specified process | actions/TaskKill.html |
| `!systemPackage` | removes a specified Windows component | actions/SystemPackage.html |
| `!cmd` | executes a specified cmd command | actions/Cmd.html |
| `!powerShell` | executes a specified PowerShell command | actions/PowerShell.html |
| `!download` | downloads a file from a URL or git repository | actions/Download.html |
| `!software` | installs software from sources like chocolatey | actions/Software.html |
| `!status` | writes a status message for AME Wizard | actions/WriteStatus.html |
| `!task` | runs a YAML task file | actions/Task.html |

Documented but **missing from the actions index**:

| YAML tag | Page |
|----------|------|
| `!file` | https://docs.amelabs.net/developers/actions/File.html |

Creating Playbooks' action bullet list uses C# class names (`RunAction`,
`WriteStatus`, …) and omits `!download`, `!software`, `!task`, `!file`.

---

## 8. Custom Features (feature pages)

Index: https://docs.amelabs.net/developers/features.html
Pages: https://docs.amelabs.net/developers/features/pages.html
YAML: https://docs.amelabs.net/developers/features/features-in-yaml.html
Checkbox: https://docs.amelabs.net/developers/features/pages/checkboxpage.html
Radio: https://docs.amelabs.net/developers/features/pages/radiopage.html
RadioImage: https://docs.amelabs.net/developers/features/pages/radioimagepage.html

`https://docs.amelabs.net/developers/custom_features.html` is **404** (nginx/1.29.1).
Creating Playbooks' "Next Steps" card still links that 404 URL. The live page is
`/developers/features.html`.

Feature pages are wizard choice screens defined in `playbook.conf` inside
`<FeaturePages>`. Every option has a `Name`; that name is what YAML `option:`
references.

### Shared page attributes (pages.html)

- `Description` — shown at top; length should be **50–85 characters**.
- `DependsOn` — `Name` of an option on a **previous** page. Page is shown only
  if that option was selected.
- `IsRequired` — `true` forces the user to select before proceeding.
- `TopLine` / `BottomLine` — `Text`, optional `Link`.

### CheckboxPage

Independent checkboxes. Options are `CheckboxOption` with `Text` and `Name`.
`IsChecked` controls the default. **Default is `true`** if omitted.

```xml
<CheckboxPage Description="Please select which features you would like to include or exclude with this Playbook.">
    <TopLine Text="Example TopLine"/>
    <Options>
        <CheckboxOption IsChecked="false">
            <Text>Remove Defender</Text>
            <Name>defender</Name>
        </CheckboxOption>
        <CheckboxOption>
            <Text>Reticulate Splines</Text>
            <Name>splines</Name>
        </CheckboxOption>
    </Options>
    <BottomLine Text="Example BottomLine with Hyperlink" Link="https://google.com"/>
</CheckboxPage>
```

### RadioPage

Mutually exclusive radios. `DefaultOption` should match an option `Name`.
Options are `RadioOption` with `Text` and `Name`.

```xml
<RadioPage DefaultOption="choice-1" Description="Please a select a choice. This is important.">
    <TopLine Text="We strongly recommend choice 1!"/>
    <Options>
        <RadioOption>
            <Text>Choice 1 (recommended)</Text>
            <Name>choice-1</Name>
        </RadioOption>
        <RadioOption>
            <Text>Choice 2</Text>
            <Name>choice-2</Name>
        </RadioOption>
    </Options>
    <BottomLine Text="Learn more" Link="https://example.com"/>
</RadioPage>
```

(Description text above is copied verbatim, including the grammar.)

### RadioImagePage

Sideways radio buttons with icons and a background gradient.

Page attributes:

- `CheckDefaultBrowser="true"` — allow skip if a non-Edge browser is already installed.
- `DefaultOption` — option `Name` checked by default.
- `DependsOn` — as on other pages.

Option (`RadioImageOption`):

- `Text` — label under the button.
- `Name` — YAML option name.
- `FileName` — refers to a `.png` in the playbook root `Images/` folder
  (no extension in the example values: `firefox`, `chromium`, …).
  Images should be **128px height**.
- `GradientTopColor` / `GradientBottomColor` — hex colors.
- `None="true"` — a dedicated “None” option (`<RadioImageOption None="true"/>`).

### Using options in YAML

```yaml
- !status: {status: 'Configuring user interface', option: "ui"}
- !run:
  exeDir: true
  exe: "UI.bat"
  option: "ui"

# Inverse: run only if the option was NOT selected
- !run:
  exe: "Example.exe"
  option: "!example-option"

# Multiple options (OR), from the shared `options` parameter
- !run: {exe: 'setup.bat', exeDir: true, options: ['opt-a', 'opt-b']}
```

---

## 9. ISO Compatibility

Developer: https://docs.amelabs.net/developers/iso.html
Operator: https://docs.amelabs.net/iso_injection.html
ISO writing (USB): https://docs.amelabs.net/iso_writing.html

### Two phases

**Injection** (offline, on the machine creating the ISO):

1. Removes uncommon Windows editions.
2. Removes Windows Defender if the playbook has the `DefenderDisabled` requirement.
3. Runs YAML actions with `iso: true/only`. `!download` runs here by default.
   `!software` downloads and caches Chocolatey packages here.
   **Dynamic actions (scripts, commands) are NOT allowed during injection.**
4. Injects the AME OOBE process plus the playbook files.

**OOBE** (target machine after first boot from the injected ISO):

- All actions run by default except `!download` (already ran at injection).
- `!software` installs from the cached package (no internet required).
- Set `oobe: true` on `!download` to also attempt a newer download at OOBE.
- Future: user will configure credentials, software, and features here.

### Enabling ISO support in playbook.conf

```xml
<SupportsISO>true</SupportsISO>
<OOBE>
  <BulletPoints>
    <BulletPoint Icon="Lock" Title="Reliable"
      Description="Through thorough testing, we've done our best to ensure that this is a reliable deployment process."/>
    <BulletPoint Icon="Privacy" Title="Enhanced privacy"
      Description="The process will enhance your privacy using various methods, such as removing privacy infringing services."/>
    <BulletPoint Icon="Rocket" Title="Optimized"
      Description="New default apps, performance optimizations, and refined UI changes will all be implemented."/>
  </BulletPoints>
  <!-- <Internet>Request</Internet>  warning if disconnected -->
  <!-- <Internet>Force</Internet>    must connect -->
</OOBE>
<ISO>
  <DisableBitLocker>true</DisableBitLocker>
  <DisableHardwareRequirements>true</DisableHardwareRequirements>
</ISO>
```

Notes from iso.html:

- OOBE bullet icons: **`Lock`, `Privacy`, `Rocket` only**.
- `BulletPoint` Description and Title lengths must roughly match the examples.
- `Software` packages visualize installs in OOBE. `Icon` is a file in `Images/`.
  `Name` should match the `package` property on a `!software` / `!download`
  action (future: user-toggleable during OOBE).

```xml
<Software>
  <Package Option="browser-firefox">
    <Name>firefox</Name>
    <Title>Firefox</Title>
    <Description>Fully featured web browser, configured for optimal usability and privacy.</Description>
    <Icon>firefox.png</Icon>
  </Package>
</Software>
```

### Per-action iso / oobe

```yaml
# Injection + live apply; skipped at OOBE (default oobe=null when iso true)
- !service: {name: 'wuauserv', operation: delete, iso: true}

# Injection only
- !service: {name: 'wuauserv', operation: delete, iso: only}

# Injection and OOBE
- !service: {name: 'wuauserv', operation: delete, iso: true, oobe: true}

# OOBE only, not live apply
- !run: {exe: 'setup.bat', exeDir: true, oobe: only}
```

Recommendation: cache internet-bound work (`!software` / `!download`) during
injection so first boot does not need the network.

---

## 10. Updates and Upgrades

Updates: https://docs.amelabs.net/developers/updates.html
Upgrades: https://docs.amelabs.net/developers/upgrades.html

### Updates (new Git release)

- AME Wizard fetches from a Git **releases** page.
- Platforms: GitHub, Gitea, GitLab.
- Release **Tag** must match `Version` in `playbook.conf`.
- Each release must contain **exactly one** `.apbx`.
- Add `<Git>https://github.com/YourOrg/YourPlaybook</Git>`
  (docs example: `https://git.ameliorated.info/Styris/AME-11`).

### Upgrades (in-place version bump)

```xml
<Version>2.0</Version>
<UpgradableFrom>1.0</UpgradableFrom>
<!-- range: 1.0.0-1.5.0 -->
<!-- any previous: any -->
<!-- list:
<UpgradableFrom>
  <string>1.0.0</string>
  <string>1.5.0</string>
</UpgradableFrom>
-->
<AllowUnsupportedUpgrades>False</AllowUnsupportedUpgrades>
```

YAML:

```yaml
- !run: {exe: 'restoreFiles.bat', exeDir: true, onUpgrade: true}
- !run: {exe: 'copyFiles.bat', exeDir: true, onUpgrade: false}
- !run: {exe: '1.0-fix.bat', exeDir: true, onUpgrade: true, onUpgradeVersions: ['1.0']}
# comparisons: onUpgradeVersions: ['>=1.0', '!1.2']
```

Option matching on upgrade (only if the old playbook had a `UniqueId`):

- If the user did not select an option in the old version, `onUpgrade` will not
  fire for actions gated on that option.
- If the option did not exist in the old version, `onUpgrade` still fires.
- Renamed option: `previousOption: 'old-name'`.
- Always run regardless of old options: `previousOption: ignore`.

### Re-application of the same version

Quoted from upgrades.html (the two sentences conflict — see §15):

> If the same version of a Playbook is re-run, only `onUpgrade: false` will be triggered.
>
> For example, actions with `onUpgrade: false` will not be run on subsequent runs
> of the same Playbook version. However, actions with `onUpgrade: true` will not
> be run like on a normal upgrade.

Override: specify the current version in `onUpgradeVersions`.

---

## 11. Verification

Source: https://docs.amelabs.net/developers/verification.html

- Granted only to well-known playbooks with a good reputation.
- Contact `@styris_ame` or `@actrons` on Discord or Telegram.
- Put the assigned integer in `<ProductCode>`.
- Submit the playbook to AME. Re-verify after any change.
- Recommended icon: `playbook.png`, **256px** wide, based on the AME
  frame-screen style, in the playbook root.

---

## 12. Reference playbooks

### PrivacyCore (starter, not our playbook)

- https://download.ameliorated.io/PrivacyCore.apbx
- 7-Zip password `malte`
- Based on Privacy+. Cited as a solid foundation after extraction.
- Do not download/explode on the host unless the operator asks.

### Privacy+

- https://docs.amelabs.net/privacy_plus.html
- Hard-removes components and files (not disable-in-place).
- Removes Windows Update, Windows Security services, Xbox, OneDrive, Defender,
  built-in apps; optional Unix-like admin password; disables SMBv1 and BitLocker
  on the system drive; replaces Start menu.
- Claims ~2GB disk savings and 103 packets vs 2688 on stock (Wireshark VM test;
  methodology PDF: https://download.ameliorated.io/Privacy%2B%20Testing%20Methodology.pdf).
- Ships Privacy+ Settings CLI and App Fetch Experimental.
- Install methods: in-place apply, or ISO injection.
- Removal is playbook-specific (no universal uninstall yet). Privacy+ Settings
  → Uninstall, then supply a current Windows 11 ISO to restore services.
  Source: https://docs.amelabs.net/remove_upgrade.html
- Universal reversibility is “under heavy development” for before AME 1.0.

### ReviOS

- https://www.revi.cc/revios/download/
- Creating Playbooks: uses a **reversible deletion** method.
- Has a ProductCode — **strip it before forking** or AME rejects the playbook.
- Amelabs is working on integrating/curating third-party options before 1.0.

### Other names on the download guide

https://docs.amelabs.net/installing_playbooks/playbook_download.html also lists
**AtlasOS** alongside ReviOS and Privacy+ as popular third-party playbooks.

User load path: drag `.apbx` onto the AME Beta sidebar drop zone, or click the
slot → “use existing” / “Browse Playbooks”.

---

## 13. Testing protocol

Source: https://docs.amelabs.net/creating_playbooks.html#testing-your-playbook

1. Enable CPU virtualization in BIOS.
2. Install VMware Workstation Pro (free via Broadcom Support Portal).
3. Windows ISO via AME Beta (`C:\ProgramData\AME\Images`) or Microsoft.
4. VM: 256GB dynamic disk (single file), ≥ 4 CPU cores.
5. Snapshot before every apply.
6. Run the playbook in the VM. Logs: `C:\ProgramData\AME\Logs`.
7. Revert and iterate.

Changelog 2024-06-12 names two log files: `Output.txt` (formatted action output)
and `Log.yml` (errors / diagnostics).

**Never apply a playbook to the host machine.**

---

## 14. NTLite migration (only if an NTLite preset is in play)

Source: https://docs.amelabs.net/developers/ntlite.html

Advanced. Contact `@styris_ame` on Telegram if stuck. Docs require a properly
licensed NTLite.

Component capture (summary): load image + preset; uncheck Servicing Stack
compatibility; Procmon filter on NTLite `SetDispositionInformationEx` under
WinSxS manifests; NTLite Apply → Stop before saving; export CSV; turn it into a
copy `.bat`; unload without saving; reload; run the bat; drop
https://download.ameliorated.io/ManifestConverter.exe into `Manifests/` and run
it. Result: converted manifests plus a `packages.yml`. Test in a snapshotted VM
and remove actions until failures are isolated.

Feature vs capability: inspect the NTLite preset `<Features>` array, then on a
matching Windows install:

```text
DISM /Online /Get-Features
DISM /Online /Get-Capabilities
```

YAML:

```yaml
- !cmd: {command: 'DISM /Online /Disable-Feature /FeatureName:"<Feature Name>" /NoRestart', weight: 30}
- !cmd: {command: 'DISM /Online /Enable-Feature /FeatureName:"<Feature Name>" /NoRestart', weight: 30}
- !cmd: {command: 'DISM /Online /Remove-Capability /CapabilityName:"<Capability Name>" /NoRestart', weight: 30}
- !cmd: {command: 'DISM /Online /Add-Capability /CapabilityName:"<Capability Name>" /NoRestart', weight: 30}
```

---

## 15. Doc disagreements and unknowns

Recorded from live fetches on 2026-10-08. Do not silently pick a side in YAML
without noting it.

| Topic | Conflict | Standing choice for this HQ |
|-------|----------|-----------------------------|
| Status action tag | creating_playbooks.html `main.yml` example uses `!writeStatus`. Action page title, actions index, features-in-yaml, and older writing-yaml.html use `!status`. Creating Playbooks' bullet list uses the class name `WriteStatus`. | Both are accepted: Atlas and ReviOS releases use `!writeStatus` 30+ times (docs/research/format-gaps.md). We standardize on **`!status`**. |
| Version format | Not a real conflict: configuration.html allows one to three dot-separated numbers, and `1.2.16` is three. | Start at `0.1`; any `x.y.z` is fine. Git release tag must match. |
| `cpuArch` case | yaml.html example: `cpuArch: "x64"`. actions.html: must match .NET Architecture, example `"X64"`. | Prefer **`X64`** (enum). Unknown whether lowercase is accepted. |
| `!software` source case | Enum listed as `Chocolatey`; example uses `chocolatey`. | Copy the example (`chocolatey`) and keep an eye on parse errors. |
| `!service` index blurb | actions.html: “executes a specified cmd command.” Service.html: “Modifies a specified service.” | Service.html is correct. |
| `!file` visibility | File.html exists (`path` required). Actions index does not list it. | Treat as official; cite File.html. |
| `custom_features.html` | Linked from Creating Playbooks Next Steps. **404.** | Use `/developers/features.html`. |
| Task paths | writing-yaml.html: `Tasks\registry.yml`. creating_playbooks / Task.html: `Tasks/registry.yml`. | Forward slashes. |
| `SupportsISO` et al. | `SupportsISO`, `UpgradableFrom`, `AllowUnsupportedUpgrades` are not in the configuration.html table (rechecked 2026-10-09; ISO/OOBE/Software now are). | Fields are real; they live on iso.html and upgrades.html. |
| Timeout units | `timeout` on `!run` / `!cmd` / `!powerShell` is integer. Docs never say ms vs seconds. | **Unknown.** Confirm in VM before setting tight timeouts. |
| `handleExitCodes` `show` | Listed handlers: `log`, `error`, `halt`, `retry`, `retryError`. Conditional example uses `'>=1': show`. | Do not use `show` until confirmed. |
| Same-version re-run | upgrades.html says both “only `onUpgrade: false` will be triggered” and “actions with `onUpgrade: false` will not be run on subsequent runs.” | Ambiguous. Design first-run vs upgrade with explicit `onUpgrade` / `onUpgradeVersions`; prove re-apply in VM. |
| ScheduledTask example quoting | Docs example: `path: '\Microsoft\Windows\Windows Defender"` (mixed quotes). | Use matching single quotes. |
| Folder contract | creating_playbooks omits `Images/` and `playbook.png`. Other pages require them for icons / RadioImage / verification. | Include them when those features are used. |
| UniqueId required? | configuration.html lists UniqueId as required. Changelog 2024-06-12 said it “will be required in a future release.” | Treat as required now. |

`developers/` directory listing returns **403**. There is no public index crawl;
coverage is the Creating Playbooks next-steps list plus every page those pages
link, plus File.html (discovered via prior catalog) and operator ISO/install
pages.

- **Feature page option limit (undocumented, seen 2026-10-10).** AME Wizard
  refused v0.2.0 with "CheckboxPage with a TopLine and BottomLine must not have
  more than 2 options". The pages docs give no limit. Shipped playbooks fit 4
  options with no TopLine/BottomLine and 3 with one (ReviOS 26.04, AtlasOS), so
  `validate.py` now allows 4 minus one per line on CheckboxPage and RadioPage.
  The RadioPage limit is inferred, not seen.

---

## 16. Pages fetched this pass

Developer:

- https://docs.amelabs.net/creating_playbooks.html
- https://docs.amelabs.net/developers/configuration.html
- https://docs.amelabs.net/developers/requirements.html
- https://docs.amelabs.net/developers/yaml.html
- https://docs.amelabs.net/developers/tasks.html
- https://docs.amelabs.net/developers/actions.html
- https://docs.amelabs.net/developers/actions/Run.html
- https://docs.amelabs.net/developers/actions/RegistryKey.html
- https://docs.amelabs.net/developers/actions/RegistryValue.html
- https://docs.amelabs.net/developers/actions/Appx.html
- https://docs.amelabs.net/developers/actions/Service.html
- https://docs.amelabs.net/developers/actions/ScheduledTask.html
- https://docs.amelabs.net/developers/actions/TaskKill.html
- https://docs.amelabs.net/developers/actions/SystemPackage.html
- https://docs.amelabs.net/developers/actions/Cmd.html
- https://docs.amelabs.net/developers/actions/PowerShell.html
- https://docs.amelabs.net/developers/actions/Download.html
- https://docs.amelabs.net/developers/actions/Software.html
- https://docs.amelabs.net/developers/actions/WriteStatus.html
- https://docs.amelabs.net/developers/actions/Task.html
- https://docs.amelabs.net/developers/actions/File.html
- https://docs.amelabs.net/developers/custom_features.html (404)
- https://docs.amelabs.net/developers/features.html
- https://docs.amelabs.net/developers/features/features-in-yaml.html
- https://docs.amelabs.net/developers/features/pages.html
- https://docs.amelabs.net/developers/features/pages/checkboxpage.html
- https://docs.amelabs.net/developers/features/pages/radiopage.html
- https://docs.amelabs.net/developers/features/pages/radioimagepage.html
- https://docs.amelabs.net/developers/iso.html
- https://docs.amelabs.net/developers/updates.html
- https://docs.amelabs.net/developers/upgrades.html
- https://docs.amelabs.net/developers/verification.html
- https://docs.amelabs.net/developers/ntlite.html
- https://docs.amelabs.net/developers/getting-started/writing-yaml.html (via search; older)

Operator / product:

- https://docs.amelabs.net/
- https://docs.amelabs.net/privacy_plus.html
- https://docs.amelabs.net/installing_playbooks.html
- https://docs.amelabs.net/installing_playbooks/playbook_download.html
- https://docs.amelabs.net/installing_playbooks/playbook_apply.html
- https://docs.amelabs.net/iso_injection.html
- https://docs.amelabs.net/iso_writing.html
- https://docs.amelabs.net/remove_upgrade.html
- https://docs.amelabs.net/changelog/2024-06-12.html (via search)
