#!/usr/bin/env python3
"""Set the in-app update switches these programs actually read.

Only the named keys are rewritten. TUN, proxy ports, subscriptions, and
every other setting stay as they are. A missing file is created with just
that switch. A file that is not the expected format is left untouched.
"""

import json
import os
import pathlib
import re
import sys

home = pathlib.Path(os.environ["HOME"])
config = home / ".config"

CHECK_NEEDED = re.compile(
    r'(<option\s+name="CHECK_NEEDED"\s+value=")(?:true|false)("\s*/>)'
)


def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    current = path.read_text() if path.exists() else None
    if current != text:
        path.write_text(text)


def load_json(path):
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text() or "{}")
    except json.JSONDecodeError:
        print(f"skip {path}: not JSON", file=sys.stderr)
        return None
    if not isinstance(data, dict):
        print(f"skip {path}: JSON root is not an object", file=sys.stderr)
        return None
    return data


def save_json(path, data):
    write_text(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def merge_json(path, values):
    data = load_json(path)
    if data is None:
        return
    data.update(values)
    save_json(path, data)


def set_ini_keys(path, updates):
    """updates: {section: {key: value}}. Other lines, including secrets, stay."""
    original = path.read_text() if path.exists() else ""
    newline = "\n"
    lines = original.splitlines()
    section = None
    seen = {name: set() for name in updates}
    out = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]") and stripped.count("[") == 1:
            name = stripped[1:-1]
            if section in updates:
                for key, value in updates[section].items():
                    if key not in seen[section]:
                        out.append(f"{key}={value}")
                        seen[section].add(key)
            section = name
            out.append(line)
            continue
        if section in updates:
            key = line.split("=", 1)[0]
            if key in updates[section]:
                out.append(f"{key}={updates[section][key]}")
                seen[section].add(key)
                continue
        out.append(line)
    if section in updates:
        for key, value in updates[section].items():
            if key not in seen[section]:
                out.append(f"{key}={value}")
                seen[section].add(key)
    for name, keys in updates.items():
        missing = [key for key in keys if key not in seen[name]]
        if not missing:
            continue
        if out and out[-1] != "":
            out.append("")
        out.append(f"[{name}]")
        for key in missing:
            out.append(f"{key}={keys[key]}")
    text = newline.join(out)
    if text and not text.endswith(newline):
        text += newline
    if not original and text == newline:
        text = ""
    write_text(path, text)


def set_toml_table(path, table, values):
    """Set keys on one exact TOML table. Nested tables are not that table."""
    if not path.exists():
        body = ["schema_version = 11", "", f"[{table}]"]
        body.extend(f"{key} = {value}" for key, value in values.items())
        write_text(path, "\n".join(body) + "\n")
        return
    original = path.read_text()
    lines = original.splitlines()
    header = f"[{table}]"
    in_table = False
    seen = set()
    out = []
    inserted = False

    def flush_missing():
        nonlocal inserted
        blanks = []
        while out and out[-1] == "":
            blanks.append(out.pop())
        for key, value in values.items():
            if key not in seen:
                out.append(f"{key} = {value}")
                seen.add(key)
        out.extend(reversed(blanks))
        inserted = True

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if in_table:
                flush_missing()
            in_table = stripped == header
            out.append(line)
            continue
        if in_table:
            key = stripped.split("=", 1)[0].strip()
            if key in values:
                out.append(f"{key} = {values[key]}")
                seen.add(key)
                continue
        out.append(line)
    if in_table:
        flush_missing()
    if not inserted:
        if out and out[-1] != "":
            out.append("")
        out.append(header)
        flush_missing()
    text = "\n".join(out)
    if original.endswith("\n") or original == "":
        text += "\n"
    write_text(path, text)


def ensure_check_needed(path):
    """JetBrains UpdatesConfigurable CHECK_NEEDED. isCheckNeeded() reads this."""
    minimal = """<application>
  <component name="UpdatesConfigurable">
    <option name="CHECK_NEEDED" value="false" />
  </component>
</application>
"""
    if not path.exists():
        write_text(path, minimal)
        return
    text = path.read_text()
    if 'name="CHECK_NEEDED"' in text:
        new = CHECK_NEEDED.sub(r"\1false\2", text)
        if new == text and 'value="false"' not in text:
            print(f"skip {path}: CHECK_NEEDED is not a boolean option", file=sys.stderr)
            return
    else:
        needle = '<component name="UpdatesConfigurable">'
        if needle not in text:
            print(f"skip {path}: no UpdatesConfigurable component", file=sys.stderr)
            return
        new = text.replace(
            needle,
            needle + '\n    <option name="CHECK_NEEDED" value="false" />',
            1,
        )
    write_text(path, new)


def main():
    # Discord host updater. The same key nixpkgs writes in
    # pkgs/applications/networking/instant-messengers/discord/disable-breaking-updates.py.
    merge_json(config / "discord" / "settings.json", {"SKIP_HOST_UPDATE": True})

    # OBS stores "Automatically check for updates" as EnableAutoUpdates in [General].
    set_ini_keys(
        config / "obs-studio" / "global.ini",
        {"General": {"EnableAutoUpdates": "false"}},
    )

    # KeePassXC Config.cpp: GUI/CheckForUpdates and UpdateCheckMessageShown.
    # The second one is the "Check for updates on startup?" dialog.
    set_ini_keys(
        config / "keepassxc" / "keepassxc.ini",
        {
            "General": {"UpdateCheckMessageShown": "true"},
            "GUI": {"CheckForUpdates": "false"},
        },
    )

    # Heroic persists these two booleans in config.json defaultSettings.
    heroic = load_json(config / "heroic" / "config.json")
    if heroic is not None:
        settings = heroic.get("defaultSettings")
        if settings is None:
            settings = {}
            heroic["defaultSettings"] = settings
        if isinstance(settings, dict):
            settings["enableUpdates"] = False
            settings["checkForUpdatesOnStartup"] = False
            save_json(config / "heroic" / "config.json", heroic)
        else:
            print("skip heroic config.json: defaultSettings is not an object", file=sys.stderr)

    # Trae staff: Settings → Update: Mode → manual. That is update.mode.
    # Linux user settings live in ~/.config/Trae CN/User/settings.json.
    merge_json(config / "Trae CN" / "User" / "settings.json", {"update.mode": "manual"})

    # OpenLogi schema 11. check_for_updates defaults to false. The first-run
    # "Check for updates?" dialog stays up until update_prompt_seen is true.
    set_toml_table(
        config / "openlogi" / "config.toml",
        "app_settings",
        {
            "check_for_updates": "false",
            "update_prompt_seen": "true",
        },
    )

    seeded = []
    for relative in os.environ.get("JB_UPDATE_DIRS", "").split(":"):
        if relative:
            seeded.append(config / relative / "options" / "updates.xml")
    for path in seeded:
        ensure_check_needed(path)

    # Also the copy an already-launched IDE wrote, including a DevEco or
    # Android Studio directory whose exact name this generation does not know.
    for root in (config / "JetBrains", config / "Google", config / "Huawei"):
        if not root.is_dir():
            continue
        for path in root.glob("*/options/updates.xml"):
            if path not in seeded:
                ensure_check_needed(path)


if __name__ == "__main__":
    main()
