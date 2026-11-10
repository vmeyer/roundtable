#!/usr/bin/env python3
"""Structural validator for the party-mode plugin. Standard library only.

Usage:
    python3 tests/validate.py [--root PLUGIN_ROOT] [--party-dir PROJECT/.party]
"""
import argparse
import json
import os
import re
import sys

PERSONA_FIELDS = ["name", "icon", "role", "voice", "cares_about",
                  "pushes_back_on", "signature_question", "friction"]
ROOM_FIELDS = ["name", "members", "memory", "scene"]
CODE_RE = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
FIELD_RE = re.compile(r"^- ([a-z_]+):\s*(.*)$")
DEFAULT_ROOM = "round-table"


def parse_entries(path, errors):
    """Parse '## code' headings, each followed by '- key: value' bullets."""
    entries = {}
    current = None
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.rstrip("\n")
            if line.startswith("## "):
                current = line[3:].strip()
                if current in entries:
                    errors.append("%s:%d: duplicate entry '%s'" % (path, lineno, current))
                entries[current] = {}
                continue
            match = FIELD_RE.match(line)
            if match and current is not None:
                entries[current][match.group(1)] = match.group(2).strip()
    return entries


def check_fields(code, fields, required, path, errors):
    if not CODE_RE.match(code):
        errors.append("%s: invalid code '%s' (use lowercase kebab-case)" % (path, code))
    for field in required:
        if field not in fields:
            errors.append("%s: '%s' missing field '%s'" % (path, code, field))
        elif not fields[field]:
            errors.append("%s: '%s' field '%s' is empty" % (path, code, field))


def load(path, required, errors, must_exist=True):
    """Return ({code: fields}, {code: source path}) for one entries file."""
    if not os.path.isfile(path):
        if must_exist:
            errors.append("missing file %s" % path)
        return {}, {}
    entries = parse_entries(path, errors)
    for code, fields in entries.items():
        check_fields(code, fields, required, path, errors)
    return entries, dict((code, path) for code in entries)


def split_list(value):
    return [item.strip() for item in value.split(",") if item.strip()]


def check_friction(personas, sources, errors):
    for code, fields in personas.items():
        value = fields.get("friction", "")
        if not value or value == "none":
            continue
        for item in split_list(value):
            ref = item.split("(")[0].strip()
            if ref not in personas:
                errors.append("%s: '%s' friction references unknown persona '%s'"
                              % (sources[code], code, ref))


def check_rooms(rooms, sources, personas, errors):
    for room_id, fields in rooms.items():
        path = sources[room_id]
        if "members" in fields:
            members = split_list(fields["members"])
            if not 3 <= len(members) <= 5:
                errors.append("%s: room '%s' needs 3-5 members, has %d"
                              % (path, room_id, len(members)))
            for member in members:
                if member not in personas:
                    errors.append("%s: room '%s' has unknown member '%s'"
                                  % (path, room_id, member))
        if "memory" in fields and fields["memory"] not in ("true", "false"):
            errors.append("%s: room '%s' memory must be true or false" % (path, room_id))
    if DEFAULT_ROOM not in rooms:
        errors.append("default room '%s' missing" % DEFAULT_ROOM)


def check_frontmatter(path, errors):
    if not os.path.isfile(path):
        errors.append("missing file %s" % path)
        return
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    if not lines or lines[0].strip() != "---" or "---" not in [l.strip() for l in lines[1:]]:
        errors.append("%s: missing YAML frontmatter" % path)
        return
    end = [l.strip() for l in lines[1:]].index("---") + 1
    keys = {}
    for line in lines[1:end]:
        if ":" in line and not line.startswith(" "):
            key, value = line.split(":", 1)
            keys[key.strip()] = value.strip()
    for key in ("name", "description"):
        if not keys.get(key):
            errors.append("%s: missing frontmatter '%s'" % (path, key))


def check_manifest(path, errors):
    if not os.path.isfile(path):
        errors.append("missing file %s" % path)
        return
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except ValueError as exc:
        errors.append("%s: invalid JSON (%s)" % (path, exc))
        return
    for key in ("name", "description", "version", "license"):
        if not data.get(key):
            errors.append("%s: missing key '%s'" % (path, key))
    if not (data.get("author") or {}).get("name"):
        errors.append("%s: missing key 'author.name'" % path)
    version = data.get("version", "")
    if version and not SEMVER_RE.match(version):
        errors.append("%s: version '%s' is not semver (X.Y.Z)" % (path, version))


def main(argv=None):
    default_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parser = argparse.ArgumentParser(description="Validate the party-mode plugin structure.")
    parser.add_argument("--root", default=default_root, help="plugin root (default: repo root)")
    parser.add_argument("--party-dir", help="a project's .party directory with overrides")
    args = parser.parse_args(argv)

    errors = []
    root = args.root
    refs = os.path.join(root, "skills", "party-mode", "references")
    check_manifest(os.path.join(root, ".claude-plugin", "plugin.json"), errors)
    check_frontmatter(os.path.join(root, "skills", "party-mode", "SKILL.md"), errors)
    check_frontmatter(os.path.join(root, "agents", "party-guest.md"), errors)

    personas, persona_src = load(os.path.join(refs, "personas.md"), PERSONA_FIELDS, errors)
    rooms, room_src = load(os.path.join(refs, "rooms.md"), ROOM_FIELDS, errors)

    if args.party_dir:
        extra, extra_src = load(os.path.join(args.party_dir, "personas.md"),
                                PERSONA_FIELDS, errors, must_exist=False)
        personas.update(extra)
        persona_src.update(extra_src)
        extra, extra_src = load(os.path.join(args.party_dir, "rooms.md"),
                                ROOM_FIELDS, errors, must_exist=False)
        rooms.update(extra)
        room_src.update(extra_src)

    check_friction(personas, persona_src, errors)
    check_rooms(rooms, room_src, personas, errors)

    if errors:
        for error in errors:
            print("ERROR: %s" % error)
        print("FAILED (%d error(s))" % len(errors))
        return 1
    print("OK: %d personas, %d rooms" % (len(personas), len(rooms)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
