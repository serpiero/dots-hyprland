#!/usr/bin/env python3
"""Open configuration as text without changing desktop MIME associations."""
import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys


def available(command):
    try:
        args = shlex.split(command)
    except ValueError:
        return []
    return args if args and shutil.which(args[0]) else []


def launch(args):
    try:
        return subprocess.run(args, check=False).returncode == 0
    except OSError:
        return False


def open_config(path, terminal):
    path = str(Path(path).expanduser().resolve())
    if not Path(path).is_file():
        return False
    # Request the text editor explicitly: JSON may be associated with a browser.
    if shutil.which("xdg-mime") and shutil.which("gio"):
        result = subprocess.run(
            ["xdg-mime", "query", "default", "text/plain"],
            capture_output=True, text=True, check=False,
        )
        desktop_id = result.stdout.strip() if result.returncode == 0 else ""
        data_home = os.environ.get("XDG_DATA_HOME") or str(Path.home() / ".local/share")
        data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
        if desktop_id and "/" not in desktop_id and desktop_id.endswith(".desktop"):
            for directory in [data_home, *data_dirs.split(":")]:
                if not directory:
                    continue
                applications = Path(directory) / "applications"
                direct = applications / desktop_id
                entries = [direct] if direct.is_file() else (
                    entry for entry in applications.rglob("*.desktop")
                    if str(entry.relative_to(applications)).replace("/", "-") == desktop_id
                )
                for entry in entries:
                    # The first matching desktop entry overrides lower-priority ones.
                    if launch(["gio", "launch", str(entry), path]):
                        return True
                    break
                else:
                    continue
                break
    for name in ("kate", "kwrite", "gnome-text-editor", "gedit", "mousepad", "xed", "leafpad"):
        if shutil.which(name) and launch([name, path]):
            return True
    terminal_args = available(terminal)
    if terminal_args:
        for editor in (os.environ.get("VISUAL", ""), os.environ.get("EDITOR", ""), "nvim", "vim", "nano", "vi"):
            editor_args = available(editor)
            if editor_args:
                separator = "--" if Path(terminal_args[0]).name in ("gnome-terminal", "kgx", "ptyxis") else "-e"
                if launch([*terminal_args, separator, *editor_args, path]):
                    return True
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path")
    parser.add_argument("--terminal", default="kitty -1")
    args = parser.parse_args()
    if open_config(args.path, args.terminal):
        return 0
    message = "Could not open the configuration. Install a text editor or check your default text editor and terminal settings."
    print(message, file=sys.stderr)
    if shutil.which("notify-send"):
        launch(["notify-send", "Settings", message])
    return 1


if __name__ == "__main__":
    sys.exit(main())
