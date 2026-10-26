#!/usr/bin/env python3
"""Capture via Hyprland; edit in existing Spectacle using isolated preferences."""
from pathlib import Path
import subprocess as sp, os, sys, json, tempfile, shutil, time
root=Path(__file__).resolve().parent
env=dict(os.environ)
if not env.get('HYPRLAND_INSTANCE_SIGNATURE'):
    instances=json.loads(sp.check_output(['hyprctl','instances','-j'],text=True))
    if len(instances)!=1:raise SystemExit('Se necesita una única sesión Hyprland')
    env.update(HYPRLAND_INSTANCE_SIGNATURE=instances[0]['instance'],WAYLAND_DISPLAY=instances[0]['wl_socket'])
env.setdefault('XDG_RUNTIME_DIR',f'/run/user/{os.getuid()}')
def preview_only(pid):
    # Spectacle's edit-existing option enables annotation. Toggle its own
    # accessible Edit control, identified by process, to show plain preview.
    try:
        import gi
        gi.require_version('Atspi','2.0')
        from gi.repository import Atspi
        def find_control(node, depth=0):
            if depth>7:return None
            if node.get_name() in ('Edit…','Edit...','Editar…','Editar...') and node.get_role()==Atspi.Role.CHECK_BOX:
                return node
            for index in range(node.get_child_count()):
                result=find_control(node.get_child_at_index(index),depth+1)
                if result is not None:return result
        for attempt in range(30):
            desktop=Atspi.get_desktop(0)
            for index in range(desktop.get_child_count()):
                app=desktop.get_child_at_index(index)
                if app.get_process_id()!=pid:continue
                control=find_control(app)
                if control is not None:
                    if control.get_state_set().contains(Atspi.StateType.CHECKED):
                        control.get_action_iface().do_action(0)
                    return
            time.sleep(.1)
    except (ImportError,ValueError,RuntimeError):
        pass

mode=sys.argv[1] if len(sys.argv)>1 else 'region'
args=['grim']
if mode=='region':
    selected=sp.run(['slurp'],env=env,text=True,capture_output=True)
    if selected.returncode:raise SystemExit(0)
    args+=['-g',selected.stdout.strip()]
elif mode=='window':
    win=json.loads(sp.check_output(['hyprctl','activewindow','-j'],env=env))
    if not win.get('address'):raise SystemExit(0)
    args+=['-g',f"{win['at'][0]},{win['at'][1]} {win['size'][0]}x{win['size'][1]}"]
elif mode=='screen':
    monitors=json.loads(sp.check_output(['hyprctl','monitors','-j'],env=env))
    args+=['-o',next(m['name'] for m in monitors if m['focused'])]
else:raise SystemExit('Usa region, window o screen')
cache=root/'ui/cache/screenshots';cache.mkdir(parents=True,exist_ok=True)
fd,name=tempfile.mkstemp(prefix='captura-',suffix='.png',dir=cache);os.close(fd)
try:
    time.sleep(.12)
    sp.run(args+[name],env=env,check=True)
    if '--preview' not in sys.argv[2:]:
        sp.run(['wl-copy','--type','image/png'],input=Path(name).read_bytes(),env=env,check=True)
        raise SystemExit(0)
    env.update(QT_QPA_PLATFORM='xcb',QT_QPA_PLATFORMTHEME='kde',QT_LINUX_ACCESSIBILITY_ALWAYS_ON='1',XDG_CONFIG_HOME=str(root/'spectacle-settings'))
    viewer=sp.Popen(['spectacle','--new-instance','--edit-existing',name],env=env)
    preview_only(viewer.pid)
    viewer.wait()
finally:Path(name).unlink(missing_ok=True)
