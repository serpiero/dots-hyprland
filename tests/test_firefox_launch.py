"""Regression checks for shared Firefox profiles and Taskbar Tab IPC."""
import importlib.util
from pathlib import Path
import shlex
import tempfile
import types
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('firefox_app_style', ROOT / 'app-style.py')
style = importlib.util.module_from_spec(spec)
spec.loader.exec_module(style)


class FirefoxLaunchTests(unittest.TestCase):
    def setUp(self):
        self.native = ['/usr/lib/firefox/firefox']
        self.webapp = self.native + [
            '-taskbar-tab', '9ba18b98-4aee-436f-9185-7c207d8555c4',
            '-new-window', 'https://gemini.google.com', '-container', '0',
        ]

    def test_webapps_drop_profile_and_process_isolation(self):
        selections = [
            ['-profile', '/missing/profile with spaces'],
            ['--profile', '/missing/profile'],
            ['--profile=/missing/profile'],
            ['-PROFILE=/missing/profile'],
            ['-P', 'Original Profile'],
            ['-p=Original Profile'],
        ]
        for selection in selections:
            with self.subTest(selection=selection):
                args = self.webapp + selection + ['--no-remote', '-new-instance']
                self.assertEqual(style.firefox_webapp_command(args), self.webapp)

    def test_incomplete_profile_flag_keeps_following_option(self):
        args = self.native + ['-profile'] + self.webapp[1:]
        self.assertEqual(style.firefox_webapp_command(args), self.webapp)

    def test_equals_taskbar_option_is_recognized(self):
        args = self.native + ['--taskbar-tab=id', '--profile=/missing']
        self.assertEqual(style.firefox_webapp_command(args), self.native + ['--taskbar-tab=id'])

    def test_explicit_browser_profiles_are_preserved(self):
        args = self.native + ['--profile', '/chosen/profile', '--no-remote']
        self.assertEqual(style.firefox_command(args), args)

    def test_known_wrapper_chains_are_sanitized_once(self):
        args = ['/usr/bin/python3', str(ROOT / 'app-style.py'), 'launch', '--',
                '/usr/bin/python3', str(Path.home() / '.local/share/kde-arc-steel/apps/launch.py'),
                '--', *self.webapp, '-profile', '/missing']
        self.assertEqual(style.firefox_command(args), self.webapp)
        command = style.firefox_desktop_command(shlex.join(args))
        tokens = shlex.split(command)
        self.assertEqual(tokens[tokens.index(self.native[0]):], self.webapp)
        self.assertEqual(style.firefox_desktop_command(command), command)

    def test_other_applications_are_not_changed(self):
        self.assertIsNone(style.firefox_command(['other-app', '--profile', '/chosen']))
        self.assertIsNone(style.firefox_desktop_command('/usr/bin/other-app --profile /chosen'))

    def test_default_launch_never_refreshes_or_injects_profile(self):
        adapter = types.SimpleNamespace(prepare=mock.Mock(return_value='/themed/firefox'))
        loader = types.SimpleNamespace(exec_module=mock.Mock())
        fake_spec = types.SimpleNamespace(loader=loader)
        for original in (self.native, self.webapp + ['--profile=/missing']):
            with self.subTest(args=original), \
                    mock.patch.object(style.importlib.util, 'spec_from_file_location', return_value=fake_spec) as load, \
                    mock.patch.object(style.importlib.util, 'module_from_spec', return_value=adapter):
                args = list(original)
                environment = {'MOZ_NO_REMOTE': '1', 'MOZ_NEW_INSTANCE': '1', 'XDG_CURRENT_DESKTOP': 'Hyprland'}
                style.firefox_profile(args, environment)
                self.assertEqual(args, ['/themed/firefox', *style.firefox_webapp_command(original)[1:]])
                self.assertEqual(environment['MOZ_LEGACY_PROFILES'], '1')
                self.assertEqual(environment['XDG_CONFIG_HOME'], str(Path.home() / '.config'))
                self.assertNotIn('MOZ_NO_REMOTE', environment)
                self.assertNotIn('MOZ_NEW_INSTANCE', environment)
                load.assert_called_once_with('steel_firefox_live', ROOT / 'tools/firefox-live.py')

    def test_missing_explicit_browser_profile_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            with self.assertRaisesRegex(ValueError, 'does not exist'):
                style.firefox_profile(self.native + ['--profile', temporary + '/missing'], {})


if __name__ == '__main__':
    unittest.main()
