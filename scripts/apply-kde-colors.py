#!/usr/bin/env python3
"""Merge a KDE .colors scheme into ~/.config/kdeglobals.

Only colour-related sections are touched; every other kdeglobals setting
(shortcuts, dialog state, KDE preferences) is preserved as-is.
"""
import configparser
import shutil
import sys
import time
from pathlib import Path

SCHEME = Path(sys.argv[1] if len(sys.argv) > 1
              else Path(__file__).resolve().parent.parent / "config/kde/Unit3Gold.colors")
KDEGLOBALS = Path.home() / ".config/kdeglobals"
SHARE = Path.home() / ".local/share/color-schemes"


def parser():
    p = configparser.RawConfigParser(strict=False)
    p.optionxform = str          # KDE keys are case-sensitive
    return p


def main():
    if not SCHEME.is_file():
        sys.exit(f"colour scheme not found: {SCHEME}")

    src = parser()
    src.read(SCHEME)

    dst = parser()
    if KDEGLOBALS.is_file():
        dst.read(KDEGLOBALS)
        backup = KDEGLOBALS.with_name(f"kdeglobals.bak-{time.strftime('%Y%m%d-%H%M%S')}")
        shutil.copy2(KDEGLOBALS, backup)
        print(f"backed up kdeglobals -> {backup.name}")

    for section in src.sections():
        if section == "General":
            # only carry the scheme name across; leave other General keys alone
            if not dst.has_section("General"):
                dst.add_section("General")
            dst["General"]["ColorScheme"] = src["General"].get("ColorScheme", "Unit3Gold")
            continue
        dst[section] = dict(src[section])

    # a stale hash makes KDE think the scheme is customised
    dst.remove_option("General", "ColorSchemeHash")

    KDEGLOBALS.parent.mkdir(parents=True, exist_ok=True)
    with KDEGLOBALS.open("w") as fh:
        dst.write(fh, space_around_delimiters=False)

    SHARE.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SCHEME, SHARE / SCHEME.name)
    print(f"applied {SCHEME.stem} to {KDEGLOBALS}")


if __name__ == "__main__":
    main()
