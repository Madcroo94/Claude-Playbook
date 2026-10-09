# CLAUDE.md — Standing orders for Claude Playbook

This repo builds an AME Beta playbook (`.apbx`) for Windows 11, in the spirit of
AtlasOS and ReviOS. Read this file first, then `docs/` as needed.

Format knowledge was fetched live from https://docs.amelabs.net/ on 2026-10-08
and spot-checked 2026-10-09. If a live page disagrees with `docs/`, the live
page wins: fix the doc and record the conflict in `docs/reconnaissance.md` §15.

## Layout

```text
CLAUDE.md                        # this file
docs/
  reconnaissance.md              # sourced notes on every AME developer page
  action-catalog.md              # parameter tables for every YAML action
  playbook.conf.reference.xml    # every known playbook.conf field, annotated
playbook/                        # playbook source; its *contents* become the .apbx
  playbook.conf                  # XML identity, version, UniqueId, requirements
  Configuration/main.yml         # entrypoint: !status + !task calls
  Configuration/Tasks/*.yml      # one domain per file
  Executables/                   # scripts/binaries YAML calls (exeDir: true)
  Images/                        # optional: OOBE software icons, RadioImagePage art
tools/
  validate.py                    # static checks; run before every commit
  package.py                     # validate + build dist/<Name>-<Version>.apbx
  package.ps1                    # same build on Windows with 7-Zip
dist/                            # build output, gitignored
```

## Commands

```sh
pip install pyyaml py7zr
python3 tools/validate.py        # must report 0 errors before committing
python3 tools/package.py         # writes dist/Claude-Playbook-<Version>.apbx
```

On Windows: `powershell -File tools\package.ps1`.

## Hard rules

1. **Never apply the playbook to a real machine.** VM only, snapshot before every
   apply, revert on failure. Logs: `C:\ProgramData\AME\Logs` (`Output.txt`, `Log.yml`).
2. **UniqueId is fixed** (`fe1958c3-ae31-4c09-891e-7118420623ce`). Never change
   it, and never copy another playbook's UniqueId or ProductCode. Code copied
   from ReviOS/AtlasOS must not bring their identity fields along.
3. **Do not invent action names or conf fields.** Only what `docs/` cites. If
   something is not documented, mark it unknown and prove it in a VM.
   `validate.py` rejects unknown action tags; extend its table only from a doc page.
4. **Use `!status`**, not `!writeStatus`. Single-quote strings and registry paths.
   Forward slashes in `!task` paths. `errorAction` instead of `ignoreErrors`.
   `!cmd` and `!powerShell` default to `wait: false`; set `wait: true` when order matters.
5. **Every change must be reversible or opt-in.** Destructive removals
   (Defender, Windows Update, Store, Edge) go behind a feature-page option and
   need a documented way back before they ship.
6. **Bump `Version` for every release.** The Git release tag must equal it and the
   release must carry exactly one `.apbx`. Mark actions that must re-run on
   upgrade with `onUpgrade` / `onUpgradeVersions`.
7. No secrets, credentials or host-identifying data in the repo.

## YAML conventions

- `main.yml` only orchestrates: `!status` then `!task: {path: 'Tasks/x.yml'}`.
- One domain per task file: `registry.yml`, `services.yml`, `scheduled-tasks.yml`,
  `appx.yml`, `components.yml`, `software.yml`, `performance.yml`, …
- Gate optional work with `option: 'name'` (invert with `'!name'`); every option
  must exist on a `<FeaturePages>` page in `playbook.conf`.
- Comment each non-obvious tweak with what it does and where it came from
  (e.g. `# AtlasOS: Configuration/tweaks/…`).
- ISO: dynamic actions (`!run`, `!cmd`, `!powerShell`) cannot run during injection.

## Phase plan

- **Phase 1 — done.** AME docs scraped into `docs/`.
- **Phase 2 — done.** Loadable skeleton: `main.yml` writes one status, no changes.
  Remaining check: load `dist/*.apbx` in AME Wizard in a VM and confirm it is
  accepted with no conf/YAML errors.
- **Phase 3 — design.** Study the public AtlasOS (`Atlas-OS/Atlas`) and ReviOS
  (`meetrevision/playbook`) sources. Decide: target builds (23H2 22631, 24H2
  26100, 25H2 26200), Requirements, feature pages, ISO yes/no, and the stance on
  Windows Update, Defender, Store, Edge, OneDrive, Copilot/Recall, UCPD.
- **Phase 4 — tweaks.** Approved tweak list written as YAML, one domain per file,
  with revert scripts in `Executables/`.
- **Phase 5 — package** with `tools/package.py`; GitHub release tagged `Version`.
- **Phase 6 — prove** on a snapshotted VM per build; read the logs; iterate.

## Key URLs

- Creating Playbooks: https://docs.amelabs.net/creating_playbooks.html
- Configuration: https://docs.amelabs.net/developers/configuration.html
- Actions: https://docs.amelabs.net/developers/actions.html
- Feature pages: https://docs.amelabs.net/developers/features.html
- ISO: https://docs.amelabs.net/developers/iso.html
- Upgrades: https://docs.amelabs.net/developers/upgrades.html
- AtlasOS source: https://github.com/Atlas-OS/Atlas
- ReviOS source: https://github.com/meetrevision/playbook
