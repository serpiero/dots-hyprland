#!/usr/bin/env python3
"""Share the native updater's check and tray state with the rice update counter."""
from pathlib import Path
import os
import shutil
import subprocess
import sys


def main():
    if shutil.which('cachy-update') or shutil.which('arch-update'):
        # systemd coalesces simultaneous timer/bar requests into the same check.
        result = subprocess.run(['systemctl','--user','start','arch-update.service'])
        if result.returncode:
            return result.returncode
        state = Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'arch-update/last_updates_check'
        try:
            count = sum(bool(line.strip()) for line in state.read_text().splitlines())
        except OSError:
            return 1
    else:
        result = subprocess.run(['checkupdates'],capture_output=True,text=True)
        # checkupdates uses 2 for a successful check with no available updates.
        if result.returncode not in (0,2):
            print(result.stderr,file=sys.stderr,end='')
            return result.returncode
        count = sum(bool(line.strip()) for line in result.stdout.splitlines())
    print(count)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
