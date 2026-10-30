"""Desktop registration must not retrigger itself for unchanged nested entries."""
from pathlib import Path
import contextlib
import importlib.util
import io
import tempfile
import types
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("desktop_registration_style", ROOT / "app-style.py")
style = importlib.util.module_from_spec(spec)
spec.loader.exec_module(style)


class DesktopRegistrationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.apps = self.root / "applications"
        self.source = self.apps / "wine/Programs/Example/Uninstall.desktop"
        self.source.parent.mkdir(parents=True)
        self.original = (
            "[Desktop Entry]\nType=Application\nName=Uninstall Example\n"
            "Exec=wine uninstall.exe\n"
        )
        self.source.write_text(self.original)
        self.destination = self.apps / "wine-Programs-Example-Uninstall.desktop"
        self.cache_update = mock.Mock()
        patcher = mock.patch.multiple(
            style,
            ROOT=self.root,
            STYLE=self.root / "style",
            application_directories=lambda: [self.apps],
            update_aerion_autostart=mock.Mock(),
            install_command_wrappers=mock.Mock(),
            subprocess=types.SimpleNamespace(run=self.cache_update),
        )
        patcher.start()
        self.addCleanup(patcher.stop)

    def register(self):
        with contextlib.redirect_stdout(io.StringIO()):
            return style.install_launchers()

    def test_unchanged_nested_entry_does_not_write_or_refresh_cache(self):
        self.assertEqual(self.register(), 1)
        content = self.destination.read_bytes()
        stamp = self.destination.stat().st_mtime_ns
        with mock.patch.object(style, "write", wraps=style.write) as write:
            for _ in range(3):
                self.assertEqual(self.register(), 0)
            write.assert_not_called()
        self.assertEqual(self.source.read_text(), self.original)
        self.assertEqual(self.destination.read_bytes(), content)
        self.assertEqual(self.destination.stat().st_mtime_ns, stamp)
        self.cache_update.assert_called_once_with(
            ["update-desktop-database", str(self.apps)], capture_output=True
        )

    def test_changed_nested_entry_updates_once_then_stabilizes(self):
        self.assertEqual(self.register(), 1)
        self.source.write_text(self.original.replace("uninstall.exe", "updated.exe"))
        self.assertEqual(self.register(), 1)
        self.assertIn("updated.exe", self.destination.read_text())
        self.assertNotIn("uninstall.exe", self.destination.read_text())
        self.assertEqual(self.register(), 0)
        self.assertEqual(self.cache_update.call_count, 2)


if __name__ == "__main__":
    unittest.main()
