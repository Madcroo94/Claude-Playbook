#!/usr/bin/env python3
"""Static checks for the playbook source tree before packaging.

Catches the mistakes AME Wizard would reject or silently mishandle: missing
playbook.conf fields, a placeholder UniqueId, unknown action tags, missing
required action parameters, !task paths that do not exist, and options used in
YAML that no feature page defines.

This does not prove the playbook works. Only a VM run does (see CLAUDE.md).

Usage: python3 tools/validate.py [playbook_dir]   (default: playbook/)
Needs PyYAML (pip install pyyaml).
"""
import re
import sys
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

import yaml

REQUIRED_CONF = ["Name", "Username", "UniqueId", "ShortDescription", "Title",
                 "Description", "Details", "Version"]

# Required parameters per action, from docs/action-catalog.md.
# A tuple means "at least one of these".
ACTIONS = {
    "run": ["exe"],
    "registryKey": ["path"],
    "registryValue": ["path", "value"],
    "appx": ["name"],
    "file": ["path"],
    "service": ["name"],
    "scheduledTask": ["path"],
    "taskKill": ["name"],
    "systemPackage": ["name"],
    "cmd": ["command"],
    "powerShell": ["command"],
    "download": ["destination", ("url", "git")],
    "software": ["source", "name"],
    "status": ["status"],
    "task": ["path"],
}

errors, warnings = [], []


class TaggedAction:
    def __init__(self, tag, params, line):
        self.tag, self.params, self.line = tag, params, line


class Loader(yaml.SafeLoader):
    pass


def _tagged(loader, suffix, node):
    # `- !status: {...}` parses as tag "!status:" on the parameter mapping.
    name = suffix.rstrip(":")
    if isinstance(node, yaml.MappingNode):
        params = loader.construct_mapping(node, deep=True)
    else:
        params = {}
    return TaggedAction(name, params, node.start_mark.line + 1)


Loader.add_multi_constructor("!", _tagged)


def check_conf(root):
    conf = root / "playbook.conf"
    if not conf.is_file():
        errors.append("playbook.conf: missing")
        return set()
    try:
        tree = ET.parse(conf).getroot()
    except ET.ParseError as e:
        errors.append(f"playbook.conf: XML parse error: {e}")
        return set()
    if tree.tag != "Playbook":
        errors.append("playbook.conf: root element must be <Playbook>")
    for field in REQUIRED_CONF:
        el = tree.find(field)
        if el is None or not (el.text or "").strip():
            errors.append(f"playbook.conf: required field <{field}> missing or empty")

    uid = (tree.findtext("UniqueId") or "").strip()
    try:
        if uuid.UUID(uid).version != 4:
            errors.append("playbook.conf: UniqueId is not a UUIDv4")
    except ValueError:
        errors.append(f"playbook.conf: UniqueId '{uid}' is not a valid UUID")

    version = (tree.findtext("Version") or "").strip()
    if version and not re.fullmatch(r"\d+(\.\d+){0,2}", version):
        errors.append(f"playbook.conf: Version '{version}' must be 1 to 3 dot-separated numbers")

    if tree.find("ProductCode") is not None:
        warnings.append("playbook.conf: <ProductCode> present; only use one AME assigned to this playbook")

    options = {n.text.strip() for n in tree.iter("Name")
               if n.text and n is not tree.find("Name")}
    return options


def walk_actions(actions, file, root, options):
    if not isinstance(actions, list):
        errors.append(f"{file}: 'actions' must be a list")
        return
    for item in actions:
        if not isinstance(item, TaggedAction):
            errors.append(f"{file}: action without a !tag: {item!r}")
            continue
        where = f"{file}:{item.line}"
        if item.tag not in ACTIONS:
            errors.append(f"{where}: unknown action !{item.tag}")
            continue
        for req in ACTIONS[item.tag]:
            alts = req if isinstance(req, tuple) else (req,)
            if not any(a in item.params for a in alts):
                errors.append(f"{where}: !{item.tag} needs '{' or '.join(alts)}'")
        if item.tag == "registryValue" and item.params.get("operation") != "delete":
            for p in ("type", "data"):
                if p not in item.params:
                    errors.append(f"{where}: !registryValue needs '{p}' unless operation is delete")
        if item.tag == "status" and "weight" in item.params:
            errors.append(f"{where}: !status does not support weight")
        if "ignoreErrors" in item.params:
            warnings.append(f"{where}: ignoreErrors is deprecated, use errorAction")
        if item.tag == "task":
            target = root / "Configuration" / str(item.params.get("path", ""))
            if "\\" in str(item.params.get("path", "")):
                warnings.append(f"{where}: use forward slashes in !task paths")
            if not target.is_file():
                errors.append(f"{where}: !task path {item.params.get('path')} not found")
        opts = list(item.params.get("options") or [])
        if item.params.get("option"):
            opts.append(item.params["option"])
        for o in opts:
            name = str(o).lstrip("!")
            if name not in options:
                warnings.append(f"{where}: option '{name}' is not defined on any feature page")


def check_yaml(root, options):
    conf_dir = root / "Configuration"
    if not (conf_dir / "main.yml").is_file():
        errors.append("Configuration/main.yml: missing")
    for f in sorted(conf_dir.rglob("*.yml")):
        rel = f.relative_to(root)
        try:
            doc = yaml.load(f.read_text(encoding="utf-8"), Loader=Loader)
        except yaml.YAMLError as e:
            errors.append(f"{rel}: YAML error: {e}")
            continue
        if not isinstance(doc, dict) or "title" not in doc or "actions" not in doc:
            errors.append(f"{rel}: needs top-level 'title' and 'actions'")
            continue
        walk_actions(doc["actions"] or [], rel, root, options)


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "playbook")
    options = check_conf(root)
    check_yaml(root, options)
    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
