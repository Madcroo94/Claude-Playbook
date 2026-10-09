# Claude-Playbook
My first request ever with the Claude API was to scourge the AtlasOS and cie advance documentation I found out about linked on their Discord. Then I've made it build the best Playbook possible an AI can do.

## Status

Phase 2: a loadable skeleton. The playbook only writes a status message and
makes no changes to Windows yet. Never apply it outside a virtual machine.

## Build

```sh
pip install pyyaml py7zr
python3 tools/validate.py     # static checks
python3 tools/package.py      # writes dist/Claude-Playbook-<Version>.apbx
```

On Windows with 7-Zip installed: `powershell -File tools\package.ps1`.

Load the `.apbx` into AME Wizard inside a VM snapshot. See `CLAUDE.md` for the
rules and phase plan, and `docs/` for the AME format reference.
