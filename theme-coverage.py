#!/usr/bin/env python3
"""Fail theme application when a supported adapter still contains another palette."""
from pathlib import Path
import argparse,configparser,hashlib,importlib.util,json,re,tomllib,zipfile
ROOT=Path(__file__).resolve().parent

def validate(root=ROOT):
    root=Path(root);style=root/'arc-steel/application-style'
    p=json.loads((root/'arc-steel/generated/spectrum.json').read_text())
    checks={}
    def check(name,condition):
        checks[name]=bool(condition)
        if not condition:raise ValueError('Theme adapter is incomplete: '+name)
    native=json.loads((style/'native/palette.json').read_text())
    check('Qt 5 / Qt 6 / Qt Quick',native==p and all((style/'native'/name).is_file() for name in ['qt5widgets.so','qt6widgets.so']))
    for version in ('gtk-3.0','gtk-4.0'):
        css=(style/'config'/version/'gtk.css').read_text()
        check(version,all(f'@define-color {key} {p[role]};' in css for key,role in [('theme_bg_color','background'),('theme_bg_color_breeze','background'),('theme_text_color','text'),('sidebar_bg_color','background')]) and 'background-image: none' in css)
    theme=json.loads((style/'share/org.kde.syntax-highlighting/themes/arc-steel.theme').read_text())
    check('Kate / KWrite',theme['editor-colors']['BackgroundColor']==p['background'] and theme['editor-colors']['IconBorder']==p['background'] and theme['text-styles']['Normal']['text-color']==p['text'] and (style/'native/editor.so').is_file())
    alacritty=tomllib.loads((style/'config/alacritty/alacritty.toml').read_text())
    check('Alacritty',alacritty['colors']['primary']['background']==p['background'])
    qt=configparser.ConfigParser(interpolation=None);qt.read(root/'arc-steel/app-settings/kdeglobals')
    rgb=','.join(str(int(p['background'][i:i+2],16)) for i in (1,3,5))
    check('KDE / Qt Widgets',qt.get('Colors:Window','BackgroundNormal')==rgb and qt.get('Colors:View','BackgroundNormal')==rgb)
    qb=json.loads((style/'qbittorrent/config.json').read_text())
    check('qBittorrent',qb['colors']['Palette.Window']==p['background'] and qb['colors']['Palette.Base']==p['background'] and (style/'qbittorrent/steel.qbtheme').is_file())
    retro=(style/'native/retroarch.palette').read_text()
    check('RetroArch palette',f'background {p["background"][1:]}\n' in retro and f'text {p["text"][1:]}\n' in retro)
    build=style/'clients/retroarch/build.json'
    if build.exists():
        info=json.loads(build.read_text())
        check('RetroArch runtime',info.get('palette_mode')=='runtime-v1' and info.get('adapter_sha256')==hashlib.sha256((root/'styles/applications/retroarch-palette.c').read_bytes()).hexdigest())
    for filename in ('chatgpt.css','discord.css','webkit.css','spotify-steel.css'):
        css=(style/filename).read_text()
        check(filename,all(f'--steel-{key.replace("_","-")}: {value};' in css for key,value in p.items()) and '{{palette.' not in css)
    spotify=style/'clients/spotify/Apps/xpui.spa'
    if spotify.exists():
        with zipfile.ZipFile(spotify) as z:check('Spotify packaged CSS',z.read('steel.css')==(style/'spotify-steel.css').read_bytes())
    check('MiniMeters',f'background = {rgb}' in (style/'config/MiniMeters/Themes/arc-steel.ini').read_text())
    check('Konsole',f'[Background]\nColor={rgb}' in (style/'share/konsole/arc-steel.colorscheme').read_text())
    check('Kitty',f'background {p["background"]}\n' in (root/'arc-steel/kitty.conf').read_text())
    check('Firefox',f'--steel-background: {p["background"]};' in (root/'arc-steel/firefox/userChrome.css').read_text())
    chrome=(root/'arc-steel/firefox/userChrome.css').read_text()
    check('Shared context menu selection',
          'margin-inline: 4px' in chrome and '[_moz-menuactive="true"]' in chrome and
          'background-color: var(--steel-selection)' in chrome and
          all('menuitem:selected' in (style/'config'/version/'gtk.css').read_text() and
              f'background-color: {p["selection"]}; background-image: none; color: {p["text"]}' in
              (style/'config'/version/'gtk.css').read_text() for version in ('gtk-3.0','gtk-4.0')))
    menu=(root/'styles/applications/electron-context-menu.cjs').read_text()
    check('Electron context menu renderer',all(token in menu for token in
          ['background:var(--selection)','border-radius:4px','padding:4px',
           "backgroundColor:'#00000000'",'hasShadow:false','sandbox:true',
           'command.menu._executeCommand','fs.watch(path.dirname(palettePath)']) and
          'require(CONTEXT_MENU_MODULE)(NATIVE_PALETTE_PATH)' in
          (root/'styles/applications/electron-bootstrap.cjs').read_text())
    quick=(root/'ui/modules/common/widgets/StyledContextMenu.qml').read_text()
    quick_item=(root/'ui/modules/common/widgets/StyledContextMenuItem.qml').read_text()
    intelligence=(root/'ui/modules/ii/sidebarLeft/WebChat.qml').read_text()
    check('Rice Qt Quick context menus',all(token in quick for token in
          ['Controls.Popup.Item','padding: 4','border.width: 0','m3surfaceContainerHigh']) and
          'm3secondaryContainer' in quick_item and 'radius: 4' in quick_item and
          'root.openContextMenu(request,siteView)' in intelligence and
          'request.accepted=false' not in intelligence)
    web=(root/'arc-steel/firefox/userContent.css').read_text()
    check('Firefox web surfaces',f'--steel-background: {p["background"]};' in web and
          '--mat-sidenav-container-background-color: var(--steel-background)' in web and
          '--drawer-background: var(--steel-background)' in web and
          '--dropdown-background: var(--steel-high)' in web)
    btop=(root/'arc-steel/btop/btop.conf').read_text()
    check('btop terminal colors',
          re.search(r'^color_theme\s*=\s*"Default"\s*$',btop,re.M) is not None and
          re.search(r'^theme_background\s*=\s*false\s*$',btop,re.M) is not None and
          (style/'config/btop').resolve()==(root/'arc-steel/btop').resolve() and
          ('\033]11;'+p['background']+'\007') in (root/'arc-steel/generated/terminal-sequences.txt').read_text())
    cava=configparser.ConfigParser(interpolation=None);cava.read(style/'config/cava/config')
    check('Cava terminal colors',cava.get('color','foreground').strip("'\"")==p['accent'] and
          cava.get('color','gradient_color_2').strip("'\"")==p['accent'])
    source=json.dumps(p,sort_keys=True).encode()
    return {'palette_sha256':hashlib.sha256(source).hexdigest(),'checks':checks,
      'refresh':{'Qt / GTK / Electron / Aerion / RetroArch':'live after the updated adapter has been loaded',
                 'Spotify / Firefox chrome / MiniMeters':'reopen the application after a color change',
                 'Wine':'generated registry display colors; applications may cache them until reopened'},
      'scope':'Interface colors. Websites, document artwork, games and custom skins can keep their own colors.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,default=ROOT);args=parser.parse_args()
    print(json.dumps(validate(args.root),indent=2))
