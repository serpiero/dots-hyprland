#!/usr/bin/env python3
"""Compile Firefox application CSS without modifying browser profiles."""
import argparse
import configparser
import importlib.util
import os
from pathlib import Path
import tempfile
import sys

ROOT = Path(__file__).resolve().parents[1]


def atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.steel-firefox-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def detect_profile(base):
    """Resolve the installation/default profile without guessing among multiple users."""
    config = configparser.ConfigParser(interpolation=None)
    config.read(base / 'profiles.ini')
    candidates = []
    for section in config.sections():
        if section.startswith('Install') and config[section].get('Default'):
            candidates.append(base / config[section]['Default'])
    if not candidates:
        for section in config.sections():
            if section.startswith('Profile') and config[section].get('Default') == '1':
                path = Path(config[section]['Path']).expanduser()
                candidates.append(base / path if config[section].get('IsRelative', '1') == '1' else path)
    if not candidates:
        sections = [s for s in config.sections() if s.startswith('Profile') and config[s].get('Path')]
        if len(sections) == 1:
            settings = config[sections[0]]
            path = Path(settings['Path']).expanduser()
            candidates.append(base / path if settings.get('IsRelative', '1') == '1' else path)
    unique = {path.resolve() for path in candidates}
    return unique.pop() if len(unique) == 1 else None


def refresh(root=ROOT):
    """Compile desktop-specific CSS without selecting or creating any profile."""
    root = Path(root).resolve()
    spec = importlib.util.spec_from_file_location('steel_firefox_theme', root / 'theme.py')
    theme = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(theme)
    added = str(root) not in sys.path
    if added:
        sys.path.insert(0, str(root))
    try:
        theme.render(root)
    finally:
        if added:
            sys.path.remove(str(root))
    chrome = (root / 'arc-steel/firefox/userChrome.css').read_text()
    output = root / 'arc-steel/application-style/firefox-chrome.css'
    # Firefox's application snapshot loads this CSS. Browser data is untouched.
    atomic(output, '@-moz-document url-prefix("chrome://") {\n' + chrome + '\n}\n')
    print('Firefox application CSS updated; browser profiles unchanged.')
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    refresh(args.root)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, configparser.Error) as error:
        raise SystemExit(str(error))
