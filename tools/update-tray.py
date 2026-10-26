#!/usr/bin/env python3
"""Keep the optional native Arch/Cachy updater tray alive in this Hyprland session."""
from pathlib import Path
import os, re, shutil, subprocess, time

updater = shutil.which('cachy-update') or shutil.which('arch-update')
if not updater:
    raise SystemExit(0)
config = Path.home()/'.config/arch-update/arch-update.conf'
if config.exists():
    current = config.read_text()
    updated = re.sub(r'^([ \t]*)ShowTrayWhenRelevant[ \t]*$',
                     r'\1# ShowTrayWhenRelevant — Steel keeps the tray visible', current, flags=re.M)
    if current != updated:
        backup = config.with_suffix('.conf.before-steel-tray')
        if not backup.exists(): backup.write_text(current)
        config.write_text(updated)
unit = Path.home()/'.config/systemd/user/steel-update-tray.service'
text = f'''[Unit]
Description=Steel native updater tray
PartOf=graphical-session.target

[Service]
Type=forking
GuessMainPID=yes
Environment=XDG_CONFIG_HOME=%h/.config
Environment=QT_QPA_PLATFORM=wayland
ExecStart={updater} --tray
Restart=always
RestartSec=5
'''
changed = not unit.exists() or unit.read_text() != text
if changed:
    unit.parent.mkdir(parents=True, exist_ok=True)
    unit.write_text(text)

# Starting the tray does not check for updates. The packaged timer only checks
# daily, so keep the native checker (and its tray state) current in the rice.
timer = unit.parent/'arch-update.timer.d/arc-steel.conf'
timer_text = '''[Unit]
Description=Check updater tray every 30 minutes

[Timer]
OnStartupSec=
OnUnitActiveSec=
OnStartupSec=2min
OnUnitActiveSec=30min
RandomizedDelaySec=1min
AccuracySec=30s
'''
timer_changed = not timer.exists() or timer.read_text() != timer_text
if timer_changed:
    timer.parent.mkdir(parents=True, exist_ok=True)
    timer.write_text(timer_text)

if changed or timer_changed:
    subprocess.run(['systemctl','--user','daemon-reload'],check=True)
subprocess.run(['systemctl','--user','start','steel-update-tray.service'],check=True)
subprocess.run(['systemctl','--user','enable','--now','arch-update.timer'],check=True)
if timer_changed:
    subprocess.run(['systemctl','--user','restart','arch-update.timer'],check=True)

# Do not block session startup on network access or open an updater terminal.
state = Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'arch-update/last_updates_check_time'
try:
    checked_at = int(state.read_text().splitlines()[0])
except (OSError, ValueError, IndexError):
    checked_at = 0
if time.time() - checked_at >= 30*60:
    subprocess.run(['systemctl','--user','start','--no-block','arch-update.service'],check=True)
