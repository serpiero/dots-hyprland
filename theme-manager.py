#!/usr/bin/env python3
"""Saved palettes, favorite colors and theme selection for this rice profile."""
from pathlib import Path
import argparse,colorsys,copy,fcntl,importlib.util,json,re,subprocess,sys
ROOT=Path(__file__).resolve().parent
HEX=re.compile(r'#[0-9a-fA-F]{6}\Z')

def engine(root):
 spec=importlib.util.spec_from_file_location('rice_theme_engine',root/'theme.py')
 module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
 return module

def selected(root):
 return engine(root).selected_name(root)

def favorites(root):
 p=root/'theme-favorites.json'
 try:
  data=json.loads(p.read_text())
  values=data.get('favorites',[]) if isinstance(data,dict) else []
  return [name for name in values if isinstance(name,str)] if isinstance(values,list) else []
 except (OSError,ValueError):return []

def catalog(root):
 module=engine(root);active=module.selected_name(root);fav=favorites(root);themes=[]
 for name in module.saved_theme_names(root):
  spec=module.load(root,name)
  colors=module.resolve_colors(spec['palette']['colors'])
  themes.append({'id':name,'name':spec['name'],'description':spec.get('description',''),
   'favorite':name in fav,'color':colors['accent'],'background':colors['background'],
   'surface':colors['high'],'text':colors['text']})
 themes.sort(key=lambda t:(not t['favorite'],t['name'].casefold()))
 return {'active':active,'themes':themes}

def custom_theme(root,name,seed):
 if not HEX.fullmatch(seed):raise ValueError('Use a color in #RRGGBB format')
 if not name.strip() or len(name.strip())>40:raise ValueError('Choose a name up to 40 characters')
 spec=engine(root).internal_seed(root)
 spec.pop('material',None);spec['name']=name.strip();spec['seed']=seed.lower();spec['description']='Custom color'
 rgb=tuple(int(seed[i:i+2],16)/255 for i in (1,3,5));h,l,s=colorsys.rgb_to_hls(*rgb)
 def color(light,saturation,offset=0):
  return '#'+''.join(f'{round(c*255):02x}' for c in colorsys.hls_to_rgb((h+offset)%1,light,max(0,min(1,saturation))))
 accent=color(max(.66,min(.80,l)),min(.72,s))
 spec['palette']={'mode':'fixed','colors':{
  'background':color(.075,min(.14,s*.14)), 'low':color(.105,min(.14,s*.16)),
  'surface':'{background}','high':color(.17,min(.16,s*.20)), 'highest':color(.22,min(.18,s*.22)),
  'text':color(.9,min(.10,s*.08)),'muted':color(.64,min(.16,s*.12)), 'accent':accent,
  'selection':color(.29,min(.30,s*.35)), 'wine':'#bd9299','sage':'#9aafa4',
  'warm':'#b9ae98','elevated':color(.12,min(.14,s*.15)),
  'accent_pressed':color(.58,min(.70,s)), 'terminal_text':'{text}','terminal_accent':'{accent}'}}
 spec['terminal']={'foreground':'{text}','accent':'{accent}','ansi_overrides':{}}
 return spec

def choose(root,name,apply):
 module=engine(root);spec=module.load(root,name);module.resolve_colors(spec['palette']['colors'])
 p=root/'theme-selection.json';previous=p.read_text() if p.exists() else None
 module.atomic(p,json.dumps({'theme':name},indent=2)+'\n')
 if apply:
  try:
   subprocess.run([sys.executable,str(root/'theme.py'),'apply','--root',str(root)],check=True,capture_output=True,text=True,timeout=120)
   coverage_spec=importlib.util.spec_from_file_location('rice_apply_coverage',root/'theme-coverage.py')
   coverage=importlib.util.module_from_spec(coverage_spec);coverage_spec.loader.exec_module(coverage)
   report=coverage.validate(root)
   source=json.loads((root/'palette-source.json').read_text())
   if not report['checks'] or not all(report['checks'].values()) or source.get('theme')!=module.fingerprint(root) or module.selected_name(root)!=name:
    raise RuntimeError('Theme application verification failed')
  except (subprocess.CalledProcessError,subprocess.TimeoutExpired,OSError,ValueError,KeyError,RuntimeError) as error:
   def readable(value):return value.decode(errors='replace') if isinstance(value,bytes) else (value or '')
   module.atomic(root/'arc-steel/generated/theme-last-error.log',str(error)+'\n'+readable(getattr(error,'stdout',None))+'\n'+readable(getattr(error,'stderr',None)))
   if previous is None:p.unlink(missing_ok=True)
   else:module.atomic(p,previous)
   try:
    rollback=subprocess.run([sys.executable,str(root/'theme.py'),'apply','--root',str(root)],capture_output=True,text=True,timeout=120)
   except (OSError,subprocess.TimeoutExpired) as rollback_error:
    raise RuntimeError('Theme selection restored, but palette restoration failed; no theme was deleted') from rollback_error
   if rollback.returncode:
    raise RuntimeError('Theme selection restored, but palette restoration failed; no theme was deleted') from error
   raise RuntimeError('Could not apply the theme; the previous selection was restored') from error

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--root',type=Path,default=ROOT)
 commands=parser.add_subparsers(dest='action',required=True)
 commands.add_parser('info')
 delete=commands.add_parser('delete');delete.add_argument('theme')
 select=commands.add_parser('select');select.add_argument('theme');select.add_argument('--no-apply',action='store_true')
 favorite=commands.add_parser('favorite');favorite.add_argument('theme');favorite.add_argument('enabled',choices=['true','false'])
 save=commands.add_parser('save');save.add_argument('--name',required=True);save.add_argument('--color',required=True);save.add_argument('--apply',action='store_true');save.add_argument('--favorite',action='store_true')
 args=parser.parse_args();root=args.root.resolve();module=engine(root)
 with (root/'.theme-manager.lock').open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  if args.action=='select':choose(root,args.theme,not args.no_apply)
  elif args.action=='delete':module.delete_theme(root,args.theme)
  elif args.action=='favorite':
   module.load(root,args.theme);fav=favorites(root)
   fav=[name for name in fav if name!=args.theme]
   if args.enabled=='true':fav.append(args.theme)
   module.atomic(root/'theme-favorites.json',json.dumps({'favorites':fav},indent=2)+'\n')
  elif args.action=='save':
   spec=custom_theme(root,args.name,args.color)
   slug=re.sub(r'[^a-z0-9]+','-',args.name.lower()).strip('-') or 'color'
   name='custom-'+slug[:48]
   module.atomic(root/'themes'/f'{name}.json',json.dumps(spec,indent=2)+'\n')
   if args.favorite:
    fav=favorites(root)
    if name not in fav:fav.append(name)
    module.atomic(root/'theme-favorites.json',json.dumps({'favorites':fav},indent=2)+'\n')
   if args.apply:choose(root,name,True)
  print(json.dumps(catalog(root),ensure_ascii=False))

if __name__=='__main__':
 try:main()
 except (ValueError,OSError,KeyError,RuntimeError,json.JSONDecodeError) as error:
  print(json.dumps({'error':str(error)},ensure_ascii=False));sys.exit(1)
