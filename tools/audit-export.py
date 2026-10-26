#!/usr/bin/env python3
"""Reject private state, credentials, absolute home paths and unsafe export links."""
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
BLOCKED_DIRECTORIES = {
    '.mozilla', '.ssh', '.gnupg', '.cache', 'audit', 'backups', 'cache',
    '__pycache__', 'clients', 'desktop-backups', 'web-profile', 'screenshots',
    'firefox-profile', 'sessionstore-backups', 'bookmarkbackups',
    'saved-telemetry-pings', 'datareporting', 'minidumps', 'weave', 'keyrings',
}
BLOCKED_NAMES = {
    'Cookies', 'History', 'Login Data', 'Visited Links', 'Trust Tokens',
    'Preferences', 'installer.db', 'states.json', 'notes.txt', 'todo.json',
    'profiles.ini', 'installs.ini', 'prefs.js', 'user.js', 'logins.json',
    'extensions.json', 'extensions.ini', 'addonStartup.json.lz4', 'xulstore.json',
    'containers.json', 'handlers.json', 'cookies.txt', 'sessionstore.js',
    'sessionstore.json', 'sessionstore.jsonlz4', 'recovery.jsonlz4',
    'recovery.baklz4', 'previous.jsonlz4', 'compatibility.ini', 'times.json',
    'pkcs11.txt', '.git-credentials', '.netrc', '.env', 'id_rsa', 'id_ed25519',
}
PERSONAL_HOME = re.compile(r'/home/[a-zA-Z0-9_.-]+/')
CREDENTIALS = re.compile(
    r'\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}'
    r'|sk-(?:(?:proj|svcacct)-)?[A-Za-z0-9_-]{20,}'
    r'|AKIA[A-Z0-9]{16}|AIza[A-Za-z0-9_-]{30,}'
    r'|eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,})'
    r'|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
)
SECRET_FIELD = re.compile(r'^(?:api.?key|access.?token|refresh.?token|password|secret|token)$', re.I)


def configured_secrets(value, path, issues):
    if isinstance(value, dict):
        for key, entry in value.items():
            location = f'{path}.{key}'
            if SECRET_FIELD.fullmatch(key) and entry not in ('', None, False, [], {}):
                issues.add(location + ' (configured secret)')
            configured_secrets(entry, location, issues)
    elif isinstance(value, list):
        for index, entry in enumerate(value):
            configured_secrets(entry, f'{path}[{index}]', issues)


def audit():
    issues = set()
    count = 0
    for path in ROOT.rglob('*'):
        relative = path.relative_to(ROOT)
        if '.git' in relative.parts:
            continue
        label = relative.as_posix()
        if path.is_symlink():
            issues.add(label + ' (symlink)')
            continue
        if any(part in BLOCKED_DIRECTORIES for part in relative.parts):
            issues.add(label + ' (private/runtime directory)')
        if relative.parts[0] in ('firefox', 'mozilla'):
            issues.add(label + ' (browser profile directory)')
        if path.name in BLOCKED_NAMES or path.name.startswith('upgrade.jsonlz4-'):
            issues.add(label + ' (private/runtime file)')
        if re.search(r'\.(?:sqlite\d*|db)(?:-(?:wal|shm|journal))?$', path.name):
            issues.add(label + ' (database)')
        if path.suffix in ('.pyc', '.log', '.pid', '.so'):
            issues.add(label + ' (runtime output)')
        if relative.parts[:2] == ('ui', 'state') and label != 'ui/state/user/generated/colors.json' and path.is_file():
            issues.add(label + ' (user state)')
        if relative.parts[:3] == ('arc-steel', 'application-style', 'config'):
            issues.add(label + ' (generated user configuration)')
        if not path.is_file():
            continue
        count += 1
        raw = path.read_bytes()
        if CREDENTIALS.search(raw.decode('utf-8', errors='ignore')):
            issues.add(label + ' (credential pattern)')
        try:
            text = raw.decode('utf-8')
        except UnicodeError:
            continue
        if PERSONAL_HOME.search(text):
            issues.add(label + ' (personal absolute home path)')
        if path.suffix == '.json':
            try:
                data = json.loads(text)
                # Translation dictionaries contain labels such as Password and API Key.
                if relative.parts[:2] != ('ui', 'translations'):
                    configured_secrets(data, label, issues)
            except ValueError:
                issues.add(label + ' (invalid JSON)')
    config = json.loads((ROOT / 'ui/settings/config.json').read_text())
    sites = config.get('sidebar', {}).get('web', {}).get('sites', [])
    if [entry.get('id') for entry in sites] != ['chatgpt', 'gemini']:
        issues.add('Intelligence defaults must contain only ChatGPT and Gemini')
    if config.get('ai', {}).get('extraModels'):
        issues.add('Extra AI models must be empty in the exported defaults')
    if issues:
        print('\n'.join(sorted(issues)), file=sys.stderr)
        return 1
    print(f'Export audit passed: {count} files; no private state, credential patterns, home paths or symlinks.')
    return 0


if __name__ == '__main__':
    raise SystemExit(audit())
