import QtQuick
import qs.services
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: root
    name: Translation.tr("Cloudflare WARP")
    available: QuickToggleApps.cloudflareWarp
    readonly property bool busy: action.running
    property string errorMessage: ""
    toggled: false
    icon: "cloud_lock"
    tooltipText: !available ? Translation.tr("Not installed: cloudflare-warp")
        : errorMessage || Translation.tr("Cloudflare WARP (1.1.1.1)")

    function refresh() {
        if (root.available && !status.running) status.running = true;
    }
    Component.onCompleted: refresh()
    onAvailableChanged: refresh()
    mainAction: () => {
        if (!root.available || root.busy) return;
        root.errorMessage = "";
        action.exec(["warp-cli", root.toggled ? "disconnect" : "connect"]);
    }
    Process {
        id: action
        environment: ({ LANG: "C", LC_ALL: "C" })
        stderr: StdioCollector { id: actionErrors }
        onExited: code => {
            if (code !== 0) root.errorMessage = Translation.tr("Could not change WARP connection")
                + ": " + actionErrors.text.trim();
            root.refresh();
        }
    }
    Process {
        id: status
        command: ["warp-cli", "status"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector { id: statusOutput }
        onExited: code => {
            root.toggled = code === 0 && /\bConnected\b/i.test(statusOutput.text);
        }
    }
}
