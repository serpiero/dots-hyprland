pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var executables: ({})
    readonly property bool cloudflareWarp: Boolean(root.executables.warp)
    readonly property string audioMixer: root.executables.audioMixer ?? ""

    Process {
        running: true
        command: ["python3", "-c", "import json,shutil; print(json.dumps({'warp':shutil.which('warp-cli'), 'audioMixer':shutil.which('pavucontrol') or shutil.which('pavucontrol-qt')}))"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.executables = JSON.parse(text); }
                catch (error) { root.executables = {}; }
            }
        }
    }
}
