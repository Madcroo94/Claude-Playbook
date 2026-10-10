#!/usr/bin/env python3
"""Static checks for the playbook source tree before packaging.

Catches the mistakes AME Wizard would reject or silently mishandle: missing
playbook.conf fields, a placeholder UniqueId, unknown action tags, unknown or
misspelled action parameters and enum values, missing required action
parameters, !task paths that do not exist, and options used in YAML that no
feature page defines.

Every accepted tag, parameter and value comes either from docs/ (the AME
developer pages) or from docs/research/format-gaps.md (real, shipped
playbooks: AtlasOS, ReviOS, Privacy+, AME 10). Things only seen in real
playbooks are accepted with a warning so we notice before relying on them.

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

# Top-level playbook.conf elements. Documented: configuration.html, iso.html,
# upgrades.html. Observed only: format-gaps.md §3.1.
CONF_DOCUMENTED = set(REQUIRED_CONF) | {
    "SupportedBuilds", "FeaturePages", "Requirements", "ProductCode",
    "ProgressText", "Git", "Website", "DonateLink", "InstallGuide",
    "PasswordReplace", "ISO", "OOBE", "Software", "UseKernelDriver",
    "SupportsISO", "UpgradableFrom", "AllowUnsupportedUpgrades"}
CONF_OBSERVED = {"Overhaul", "EstimatedMinutes"}  # Atlas, Privacy+, AME 10

# AME Wizard rejects a playbook whose Name is too long ("Playbook Name is too
# long" for a 15-character name, 2026-10-10) and documents no limits. Until a
# VM proves more, every text stays within the longest that ReviOS 26.04 and
# AtlasOS 0.5 ship.
TEXT_LIMITS = {"Name": 7, "Username": 8, "Title": 15, "ShortDescription": 31,
               "Description": 291, "Details": 125, "ProgressText": 162}
PAGE_TEXT_LIMITS = {"Description": 93, "Option text": 42, "TopLine/BottomLine": 50}

# requirements.html; plus two seen only in Privacy+ / AME 10.
REQUIREMENTS_DOCUMENTED = {
    "Internet", "NoInternet", "Activation", "FreshInstall", "DefenderToggled",
    "DefenderDisabled", "UCPDDisabled", "NoAntivirus", "NoPendingUpdates",
    "PasswordSet", "AdministratorPasswordSet", "PluggedIn"}
REQUIREMENTS_OBSERVED = {"NoTweakware", "LocalAccounts"}

# Shared action parameters (actions.html). ignoreErrors is deprecated but
# still shipped by Atlas, ReviOS and Privacy+.
SHARED = {"weight", "status", "errorAction", "ignoreErrors", "option",
          "options", "builds", "cpuArch", "onUpgrade", "onUpgradeVersions",
          "previousOption", "iso", "oobe"}

# Required parameters per action, from docs/action-catalog.md.
# A tuple means "at least one of these".
ACTIONS = {
    "run": ["exe"],
    "registryKey": ["path"],
    "registryValue": ["path"],      # 'value' omitted = (Default); see below
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
    "writeStatus": ["status"],      # alias; see TAG_ALIASES
    "task": ["path"],
}

# Tags AME accepts that docs/ tells us not to use. Accepted with a warning.
TAG_ALIASES = {
    "writeStatus": "use !status (CLAUDE.md); !writeStatus is the older name, "
                   "still used by AtlasOS and ReviOS",
}

# Per-action parameters on top of SHARED. Documented: action-catalog.md.
PARAMS = {
    "run": {"exe", "path", "args", "baseDir", "exeDir", "runas", "timeout",
            "wait", "handleExitCodes", "showOutput", "showError"},
    "registryKey": {"path", "operation", "scope"},
    "registryValue": {"path", "value", "type", "data", "operation", "scope"},
    "appx": {"name", "operation", "type", "verboseOutput", "unregister"},
    "file": {"path"},
    "service": {"name", "startup", "operation", "deleteStop", "device",
                "deleteUsingRegistry", "scope"},
    "scheduledTask": {"path", "operation", "data"},
    "taskKill": {"name", "pathContains"},
    "systemPackage": {"name", "arch", "language", "regexExcludeFiles",
                      "excludeDependents"},
    "cmd": {"command", "exeDir", "runas", "timeout", "wait", "handleExitCodes"},
    "powerShell": {"command", "exeDir", "runas", "timeout", "wait",
                   "handleExitCodes"},
    "download": {"destination", "url", "git", "regex", "overwrite", "package"},
    "software": {"source", "name", "upgrade", "package"},
    "status": {"status"},
    "writeStatus": {"status"},
    "task": {"path"},
}
# Undocumented parameters seen in shipped playbooks (format-gaps.md §2.3).
PARAMS_OBSERVED = {
    "run": {"hideWindow"},  # Privacy+ / AME 10 software.yml
}

RUNAS = {"currentUser", "currentUserElevated", "system", "trustedInstaller"}
ENUMS = {
    "errorAction": {"Ignore", "Log", "Notify", "Halt"},
    "iso": {True, False, "only"},
    "oobe": {True, False, "only", None},
}
ACTION_ENUMS = {
    ("run", "runas"): RUNAS,
    ("cmd", "runas"): RUNAS,
    ("powerShell", "runas"): RUNAS,
    ("registryKey", "operation"): {"add", "delete"},
    ("registryValue", "operation"): {"add", "delete", "set"},
    ("registryValue", "type"): {"REG_SZ", "REG_MULTI_SZ", "REG_EXPAND_SZ",
                                "REG_DWORD", "REG_QWORD", "REG_BINARY",
                                "REG_NONE", "REG_UNKNOWN"},
    ("appx", "operation"): {"remove", "clearCache"},
    ("appx", "type"): {"family", "package", "app"},
    ("service", "operation"): {"stop", "continue", "start", "pause", "delete",
                               "change"},
    ("scheduledTask", "operation"): {"delete", "deleteFolder", "enable",
                                     "disable"},
    ("systemPackage", "arch"): {"amd64", "wow64", "x86", "msil", "all"},
}
SCOPES = {"allUsers", "currentUser", "activeUsers", "defaultUsers"}
SCOPES_OBSERVED = {"defaultUser"}  # Privacy+ / AME 10; docs say defaultUsers
# .NET System.Runtime.InteropServices.Architecture
CPU_ARCH = {"X86", "X64", "Arm", "Arm64", "Wasm", "S390x", "LoongArch64",
            "Armv6", "Ppc64le", "RiscV64"}
EXIT_HANDLERS = {"log", "error", "halt", "retry", "retryError"}

# Task-file top-level keys. Documented (tasks.html): title, option, options,
# builds. Observed in every reference playbook: description, privilege,
# onUpgrade (format-gaps.md §4).
TASK_KEYS_DOCUMENTED = {"title", "actions", "option", "options", "builds"}
TASK_KEYS_OBSERVED = {"description", "privilege", "onUpgrade"}
PRIVILEGES = {"TrustedInstaller", "Admin"}

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
    if not conf.read_bytes().lstrip(b"\xef\xbb\xbf").lstrip().startswith(b"<?xml"):
        warnings.append("playbook.conf: no <?xml ...?> declaration (configuration.html shows one)")
    for field in REQUIRED_CONF:
        el = tree.find(field)
        if el is None or not (el.text or "").strip():
            errors.append(f"playbook.conf: required field <{field}> missing or empty")
    for el in tree:
        if el.tag in CONF_OBSERVED:
            warnings.append(f"playbook.conf: <{el.tag}> is undocumented (seen in shipped playbooks)")
        elif el.tag not in CONF_DOCUMENTED:
            errors.append(f"playbook.conf: unknown element <{el.tag}>")

    for field, limit in TEXT_LIMITS.items():
        text = (tree.findtext(field) or "").strip()
        if len(text) > limit:
            errors.append(f"playbook.conf: <{field}> is {len(text)} characters; keep it to {limit} (AME rejects long names)")
    for page in tree.iterfind("FeaturePages/*"):
        texts = [("Description", page.get("Description", ""))]
        texts += [("Option text", (o.findtext("Text") or "").strip()) for o in page.iterfind("Options/*")]
        texts += [("TopLine/BottomLine", l.get("Text", "")) for l in page if l.tag in ("TopLine", "BottomLine")]
        for kind, text in texts:
            if len(text) > PAGE_TEXT_LIMITS[kind]:
                errors.append(f"playbook.conf: <{page.tag}> {kind} '{text}' is {len(text)} characters; "
                              f"keep it to {PAGE_TEXT_LIMITS[kind]}")

    uid = (tree.findtext("UniqueId") or "").strip()
    try:
        u = uuid.UUID(uid)
        if (u.int >> 76) & 0xF != 4:
            errors.append("playbook.conf: UniqueId is not a UUIDv4")
        elif u.variant != uuid.RFC_4122:
            warnings.append("playbook.conf: UniqueId has version 4 but a non-RFC 4122 variant")
    except ValueError:
        errors.append(f"playbook.conf: UniqueId '{uid}' is not a valid UUID")

    version = (tree.findtext("Version") or "").strip()
    if version and not re.fullmatch(r"\d+(\.\d+){0,2}", version):
        errors.append(f"playbook.conf: Version '{version}' must be 1 to 3 dot-separated numbers")

    if tree.find("ProductCode") is not None:
        warnings.append("playbook.conf: <ProductCode> present; only use one AME assigned to this playbook")
    if tree.find("Requirements") is None:
        warnings.append("playbook.conf: no <Requirements>; Atlas notes AME Wizard 0.6.5 crashed without it")
    for req in tree.iterfind("Requirements/Requirement"):
        r = (req.text or "").strip()
        if r in REQUIREMENTS_OBSERVED:
            warnings.append(f"playbook.conf: requirement '{r}' is undocumented (seen in Privacy+)")
        elif r not in REQUIREMENTS_DOCUMENTED:
            errors.append(f"playbook.conf: unknown requirement '{r}'")

    # Option names live on feature pages only; <Software><Package><Name> is a
    # package id, not an option.
    options = {n.text.strip() for n in tree.iterfind("FeaturePages/*/Options/*/Name")
               if n.text and n.text.strip()}
    for page in tree.iterfind("FeaturePages/*"):
        # AME Wizard refuses to load "CheckboxPage with a TopLine and
        # BottomLine must not have more than 2 options" (seen 2026-10-10).
        # Shipped playbooks fit 4 options with no lines and 3 with one line
        # (ReviOS 26.04, AtlasOS), so treat each line as taking one of 4 slots.
        if page.tag in ("CheckboxPage", "RadioPage"):
            lines = sum(page.find(t) is not None for t in ("TopLine", "BottomLine"))
            n = len(list(page.iterfind("Options/*")))
            if n > 4 - lines:
                top = page.findtext("TopLine") or (page.find("TopLine").get("Text") if page.find("TopLine") is not None else page.get("Description", ""))
                errors.append(f"playbook.conf: <{page.tag}> '{top}' has {n} options; "
                              f"AME allows {4 - lines} with {lines} of TopLine/BottomLine")
        dep = page.get("DependsOn")
        if dep and dep not in options:
            warnings.append(f"playbook.conf: <{page.tag}> DependsOn '{dep}' is not an option on any page")
    for pkg in tree.iterfind("Software/Package"):
        opt = pkg.get("Option")
        if opt and opt not in options:
            warnings.append(f"playbook.conf: <Package> Option '{opt}' is not an option on any page")
    return options


def check_option_refs(where, params, options):
    opts = params.get("options") or []
    if isinstance(opts, str):
        opts = [opts]
    opts = list(opts)
    if params.get("option"):
        opts.append(params["option"])
    for o in opts:
        name = str(o).lstrip("!")
        if name not in options:
            warnings.append(f"{where}: option '{name}' is not defined on any feature page")


def check_enum(where, label, value, allowed):
    if value not in allowed:
        errors.append(f"{where}: {label} '{value}' is not one of {sorted(map(str, allowed))}")


def resolve_task(root, path):
    # AME resolves !task paths relative to Configuration/. Atlas, ReviOS and
    # Privacy+ all ship backslash paths, so accept either separator.
    return root / "Configuration" / Path(*re.split(r"[\\/]", path))


def walk_actions(actions, file, root, options):
    if not isinstance(actions, list):
        errors.append(f"{file}: 'actions' must be a list")
        return
    for item in actions:
        if not isinstance(item, TaggedAction):
            errors.append(f"{file}: action without a !tag: {item!r}")
            continue
        where = f"{file}:{item.line}"
        tag, p = item.tag, item.params
        if tag not in ACTIONS:
            errors.append(f"{where}: unknown action !{tag}")
            continue
        if tag in TAG_ALIASES:
            warnings.append(f"{where}: !{tag}: {TAG_ALIASES[tag]}")
        for req in ACTIONS[tag]:
            alts = req if isinstance(req, tuple) else (req,)
            if not any(a in p for a in alts):
                errors.append(f"{where}: !{tag} needs '{' or '.join(alts)}'")

        for k in p:
            if k in SHARED or k in PARAMS[tag]:
                continue
            if k in PARAMS_OBSERVED.get(tag, ()):
                warnings.append(f"{where}: !{tag} '{k}' is undocumented (seen in shipped playbooks)")
            else:
                errors.append(f"{where}: !{tag} has unknown parameter '{k}'")

        for k, allowed in ENUMS.items():
            if k in p:
                check_enum(where, k, p[k], allowed)
        for (t, k), allowed in ACTION_ENUMS.items():
            if t == tag and k in p:
                check_enum(where, k, p[k], allowed)
        if "scope" in p:
            if p["scope"] in SCOPES_OBSERVED:
                warnings.append(f"{where}: scope '{p['scope']}' is undocumented; docs say 'defaultUsers'")
            else:
                check_enum(where, "scope", p["scope"], SCOPES)
        if "cpuArch" in p:
            arch = str(p["cpuArch"])
            canon = {a.lower(): a for a in CPU_ARCH}.get(arch.lower())
            if canon is None:
                errors.append(f"{where}: cpuArch '{arch}' is not a .NET Architecture value")
            elif canon != arch:
                warnings.append(f"{where}: cpuArch '{arch}': prefer '{canon}' (Privacy+ ships lowercase)")
        if "handleExitCodes" in p:
            hec = p["handleExitCodes"]
            if not isinstance(hec, dict):
                errors.append(f"{where}: handleExitCodes must be a mapping")
            else:
                for code, h in hec.items():
                    if h == "show":
                        warnings.append(f"{where}: handleExitCodes '{code}: show' is not a listed handler")
                    elif h not in EXIT_HANDLERS:
                        errors.append(f"{where}: handleExitCodes handler '{h}' is not one of {sorted(EXIT_HANDLERS)}")
        for k in ("builds", "onUpgradeVersions", "options", "regexExcludeFiles",
                  "excludeDependents"):
            if k in p and not isinstance(p[k], list):
                errors.append(f"{where}: '{k}' must be a list")

        if tag == "registryValue":
            if "value" not in p:
                warnings.append(f"{where}: !registryValue without 'value' targets the (Default) value; prefer value: ''")
            if p.get("operation") != "delete":
                for k in ("type", "data"):
                    if k not in p:
                        errors.append(f"{where}: !registryValue needs '{k}' unless operation is delete")
        if tag == "service" and p.get("operation") == "change":
            if "startup" not in p:
                errors.append(f"{where}: !service operation change needs 'startup'")
            elif p["startup"] not in (0, 1, 2, 3, 4):
                errors.append(f"{where}: !service startup '{p['startup']}' must be 0-4")
            elif p["startup"] in (0, 1):
                warnings.append(f"{where}: !service startup {p['startup']} (boot/system) is undocumented; ReviOS uses it")
        if tag in ("status", "writeStatus") and "weight" in p:
            errors.append(f"{where}: !{tag} does not support weight")
        if tag == "download" and "git" in p and "regex" not in p:
            errors.append(f"{where}: !download with 'git' needs 'regex'")
        if "ignoreErrors" in p:
            warnings.append(f"{where}: ignoreErrors is deprecated, use errorAction")
        if tag == "task":
            path = str(p.get("path", ""))
            if "\\" in path:
                warnings.append(f"{where}: use forward slashes in !task paths")
            if not resolve_task(root, path).is_file():
                errors.append(f"{where}: !task path {path} not found")
        check_option_refs(where, p, options)


def check_yaml(root, options):
    conf_dir = root / "Configuration"
    if not (conf_dir / "main.yml").is_file():
        if (conf_dir / "custom.yml").is_file():
            warnings.append("Configuration/custom.yml: deprecated entrypoint name (changelog 2024-06-12); use main.yml")
        else:
            errors.append("Configuration/main.yml: missing")
    for f in sorted(conf_dir.rglob("*.yml")):
        rel = f.relative_to(root)
        try:
            doc = yaml.load(f.read_text(encoding="utf-8-sig"), Loader=Loader)
        except yaml.YAMLError as e:
            errors.append(f"{rel}: YAML error: {e}")
            continue
        if not isinstance(doc, dict) or "title" not in doc or "actions" not in doc:
            errors.append(f"{rel}: needs top-level 'title' and 'actions'")
            continue
        for k in doc:
            if k in TASK_KEYS_OBSERVED:
                continue  # undocumented but in every reference playbook
            if k not in TASK_KEYS_DOCUMENTED:
                errors.append(f"{rel}: unknown top-level key '{k}'")
        if "privilege" in doc and doc["privilege"] not in PRIVILEGES:
            errors.append(f"{rel}: privilege '{doc['privilege']}' is not one of {sorted(PRIVILEGES)}")
        if "builds" in doc and not isinstance(doc["builds"], list):
            errors.append(f"{rel}: 'builds' must be a list")
        check_option_refs(str(rel), doc, options)
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
