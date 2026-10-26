#!/usr/bin/env python3
from pathlib import Path
import subprocess as sp,sys,os,json,time
ROOT=Path(__file__).resolve().parent
E=dict(os.environ)
if not E.get('HYPRLAND_INSTANCE_SIGNATURE'):
    instances=json.loads(sp.check_output(['hyprctl','instances','-j'],text=True))
    if len(instances)!=1:raise SystemExit('Se necesita una única sesión de Hyprland')
    E.update(HYPRLAND_INSTANCE_SIGNATURE=instances[0]['instance'],WAYLAND_DISPLAY=instances[0]['wl_socket'])
E.setdefault('XDG_RUNTIME_DIR',f'/run/user/{os.getuid()}')
E.setdefault('DBUS_SESSION_BUS_ADDRESS','unix:path='+E['XDG_RUNTIME_DIR']+'/bus')
E.update(XDG_CURRENT_DESKTOP='Hyprland',XDG_SESSION_TYPE='wayland')
mode=sys.argv[1] if len(sys.argv)>1 else 'region'
args=['grim']
if mode=='region':
    selection=sp.run(['slurp','-c','#b5b9bd','-b','#00000055'],env=E,capture_output=True,text=True)
    if selection.returncode:raise SystemExit(0)
    args+=['-g',selection.stdout.strip()]
elif mode=='window':
    win=json.loads(sp.check_output(['hyprctl','activewindow','-j'],env=E))
    if not win.get('address'):raise SystemExit(0)
    args+=['-g',f"{win['at'][0]},{win['at'][1]} {win['size'][0]}x{win['size'][1]}"]
elif mode=='screen':
    monitors=json.loads(sp.check_output(['hyprctl','monitors','-j'],env=E))
    args+=['-o',next(m['name'] for m in monitors if m['focused'])]
else:raise SystemExit('Usa region, window o screen')
# Selection overlay must disappear before grabbing the pixels.
time.sleep(.12)
image=sp.check_output(args+['-'],env=E)
folder=Path.home()/'Pictures/Screenshots';folder.mkdir(parents=True,exist_ok=True)
E.update(ADW_DEBUG_COLOR_SCHEME='prefer-dark',XDG_CONFIG_HOME=str(ROOT/'satty-settings'))
sp.run([str(ROOT/'bin/satty'),'--config',str(ROOT/'arc-steel/satty.toml'),
    '--filename','-','--output-filename',str(folder/'Captura_%Y-%m-%d_%H-%M-%S.png'),
    '--copy-command','wl-copy','--actions-on-enter','save-to-clipboard,exit',
    '--actions-on-escape','exit','--initial-tool','pointer','--app-id','io.arc-steel.Satty',
    '--title','Arc Steel · Capturas'],input=image,env=E,check=True)
