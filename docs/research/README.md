# Phase 3 research — what we learned and what we propose

Sources compared (read only, nothing executed), 2026-10-09:

| Playbook | Version | Target | License |
|---|---|---|---|
| AtlasOS (`Atlas-OS/Atlas`, git `1ed9630`) | 0.5.x | Win11 24H2 / 25H2 | GPL-3.0 |
| ReviOS (`meetrevision/playbook`, git `f907fde`, plus the 26.04 `.apbx`) | 26.04 | Win10 + Win11 | CC BY-SA 4.0 |
| AME Privacy+ (`.apbx`) | 0.8.2 | Win11 | none published, do not copy |
| AME 10 (`.apbx`) | 0.8 | Win10 | none published, do not copy |

## Files

| File | What it holds |
|---|---|
| [format-gaps.md](format-gaps.md) | Playbook-format features the real playbooks use that `docs/` missed or got wrong |
| [architecture.md](architecture.md) | `playbook.conf`, feature pages, `main.yml` order, revert, toolbox, CI, licensing, and **§10 recommendations** |
| [privacy.md](privacy.md) | ~330 privacy/telemetry changes in 270 rows; **§21 consensus baseline** (74 rows) |
| [debloat.md](debloat.md) | Apps, components, services, scheduled tasks, Edge/OneDrive/Store/Update/Defender handling |
| [performance-qol.md](performance-qol.md) | 53 performance and 51 UI rows, UCPD, security trade-offs |

Every row cites its source as a path under the reference trees, so Phase 4 can
check the exact original before writing our own YAML.

## Headline findings

1. **Three philosophies.** Atlas: reversible, toggle scripts for every change,
   Defender kept by default. ReviOS: does most work through its own
   `revitool.exe`, downloaded from GitHub "latest" at apply time, so a lot of what
   it does is not visible in the repo. Privacy+ / AME 10: hard deletion of
   Windows Update, Store, Defender, Edge and ~320 files; undo needs an ISO.
2. **Shared core.** All four remove the same ~30 consumer apps and disable
   DiagTrack, the CEIP tasks and the Compatibility Appraiser. That core, plus 74
   privacy rows that 3+ playbooks agree on, is a safe ungated baseline for us.
3. **Our format docs had real errors.** `!writeStatus` works (Atlas and ReviOS
   use it 30+ times); `!FileAction` does not exist; task files carry
   undocumented `description` / `privilege` / `onUpgrade` keys; conf has
   undocumented `Overhaul`, `EstimatedMinutes`, `DefaultWebBrowser`, and the
   requirements `NoTweakware` and `LocalAccounts`. `tools/validate.py` now knows
   all of these and passes all five reference trees with 0 errors.
4. **Bugs in the references we must not copy:** ReviOS sets `AllowCortana=1`,
   `SbEnable=1` and MRT reporting `=0` under comments saying the opposite;
   Privacy+ misspells `*XboxIdenitity*`; `*Microsoft.Calculator*` never matches;
   Atlas's feature-update pin overwrites its own value; Atlas checkboxes omit
   `IsChecked`, so Edge removal and Core Isolation off are on by default.
5. **Dangerous items to avoid:** CryptSvc firewalled (breaks certificate
   revocation), deleting Update/DO binaries and replacing `sfc.exe`, Smart App
   Control off (cannot come back without a reset), `NoConnectedUser=1` (blocks
   Microsoft accounts), downloading unpinned binaries at apply time.

## Proposed design for Claude Playbook v0.2 (needs your OK)

- **Model:** Atlas-style. Every change reversible or opt-in. No file deletion, no
  service deletion, no removal CABs, no unpinned downloads.
- **Builds:** 24H2 (26100) and 25H2 (26200) only.
- **Requirements:** Internet, NoPendingUpdates, NoAntivirus, PluggedIn,
  DefenderToggled (not DefenderDisabled).
- **Feature pages** (defaults in brackets):
  1. Defender: keep [default] / disable by policy (reversible)
  2. Windows Update: Windows default [default] / notify only, no auto-reboot
  3. Remove apps: consumer apps [on], Copilot + Recall [on], OneDrive [on],
     Edge [off], Xbox [off], Phone Link [off]
  4. Interface: classic context menu [on], no Start recommendations [on], show
     file extensions [on], dark mode [off], taskbar left [off]
  5. Power: disable hibernation [off], high-performance plan [off], Core Isolation off [off]
  6. Extras: install the toolbox folder [on], install a browser [off]
  7. Browser picker (Firefox / Brave / LibreWolf / none), shown only if chosen
- **Ungated baseline:** the privacy §21 consensus rows that are pure registry
  policy, the shared app list, scheduled tasks disabled (not deleted), services
  set to manual/disabled (not deleted).
- **Way back:** a toolbox folder copied to `%windir%\ClaudePlaybook` with paired
  Enable/Disable scripts per setting, plus `.reg` snapshots of every key and
  service start value we touch, and a "Restore Windows defaults" script.
- **No ISO support in v1.**

## Decisions only you can make

1. **License.** If we copy any Atlas code, the whole playbook must be GPL-3.0.
   Recommended: adopt GPL-3.0 now. ReviOS material can then be used with
   attribution. Privacy+ / AME code must not be copied either way.
2. **Defender and Windows Update defaults** — keep Windows behaviour by default
   (recommended), or follow ReviOS and turn them off by default.
3. **Edge** — keep by default (recommended; WebView2 apps depend on it) or remove.
