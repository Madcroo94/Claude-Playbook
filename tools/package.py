#!/usr/bin/env python3
"""Package playbook/ into dist/<Name>-<Version>.apbx.

An .apbx is a 7z archive of the *contents* of the playbook folder (no wrapping
folder), encrypted with the password 'malte' so browsers and antivirus do not
scan embedded executables. Runs tools/validate.py first and refuses to package
on errors.

Usage: python3 tools/package.py [playbook_dir]
Needs py7zr and PyYAML (pip install py7zr pyyaml). On Windows, tools/package.ps1
does the same with 7-Zip.
"""
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

import py7zr

PASSWORD = "malte"


def main():
    repo = Path(__file__).resolve().parent.parent
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else repo / "playbook"
    check = subprocess.run([sys.executable, str(repo / "tools" / "validate.py"), str(root)])
    if check.returncode != 0:
        sys.exit("validation failed; not packaging")

    conf = ET.parse(root / "playbook.conf").getroot()
    name = conf.findtext("Name").strip().replace(" ", "-")
    version = conf.findtext("Version").strip()
    out = repo / "dist" / f"{name}-{version}.apbx"
    out.parent.mkdir(exist_ok=True)
    out.unlink(missing_ok=True)

    with py7zr.SevenZipFile(out, "w", password=PASSWORD) as z:
        z.set_encrypted_header(True)
        for f in sorted(root.rglob("*")):
            if f.is_file() and f.name != ".gitkeep":
                z.write(f, f.relative_to(root).as_posix())
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
