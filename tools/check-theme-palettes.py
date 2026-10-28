#!/usr/bin/env python3
"""Exercise the real theme selector and all generators in an isolated temporary root."""
from pathlib import Path
import json,os,shutil,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='rice-palette-check-') as temporary:
    stage=Path(temporary)
    for folder in ('themes','styles'):
        shutil.copytree(ROOT/folder,stage/folder)
    for name in ('theme.py','palette.py','app-style.py','electron-style.py','theme-manager.py','workspace_icons.py','theme-coverage.py','wine-style.py','local-theme.json'):
        if (ROOT/name).exists():shutil.copy2(ROOT/name,stage/name)
    for relative in ('tools/firefox-theme.py','tools/firefox-live.py',
                     'ui/settings/config.json','ui/state/user/generated/colors.json',
                     'ui/modules/common/widgets/StyledContextMenu.qml',
                     'ui/modules/common/widgets/StyledContextMenuItem.qml',
                     'ui/modules/ii/sidebarLeft/WebChat.qml','arc-steel/kitty.conf',
                     'arc-steel/btop/btop.conf','arc-steel/app-settings/kdeglobals',
                     'arc-steel/application-style/webkit-style.c','arc-steel/application-style/clients/retroarch/build.json'):
        source=ROOT/relative
        if source.exists():
            target=stage/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    wallpaper=stage/'wallpaper.svg';wallpaper.write_text('<svg fill="#333333"/>')
    (stage/'wallpaper-path').write_text(str(wallpaper))
    command=[sys.executable,str(stage/'theme-manager.py'),'--root',str(stage)]
    results=[]
    # All saved palettes, plus unlike hues and both limits of a custom seed.
    names=[p.stem for p in (stage/'themes').glob('*.json')]
    for name,color in [('test-violet','#8040d0'),('test-black','#000000'),('test-white','#ffffff')]:
        result=subprocess.run([*command,'save','--name',name,'--color',color],capture_output=True,text=True,check=True)
        names.append('custom-'+name)
    for name in names:
        result=subprocess.run([*command,'select',name],capture_output=True,text=True,timeout=180)
        if result.returncode:
            diagnostic=stage/'arc-steel/generated/theme-last-error.log'
            detail=diagnostic.read_text() if diagnostic.exists() else ''
            raise RuntimeError(name+': '+result.stdout+result.stderr+'\n'+detail)
        report=json.loads((stage/'arc-steel/generated/theme-coverage.json').read_text())
        assert all(report['checks'].values())
        results.append({'theme':name,'checks':len(report['checks']),'palette_sha256':report['palette_sha256']})
        print(json.dumps(results[-1]),flush=True)
    before=(stage/'theme-selection.json').read_bytes()
    invalid=subprocess.run([*command,'select','../escape'],capture_output=True)
    assert invalid.returncode and (stage/'theme-selection.json').read_bytes()==before
    print(json.dumps({'palettes_passed':len(results),'invalid_selection_preserved':True}))
