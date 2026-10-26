pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.modules.common
import qs.services.network

Singleton {
    id: root
    property bool wifi: false
    property bool ethernet: false
    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property bool wifiScanning: false
    readonly property bool wifiSwitching: enableWifiProc.running
    readonly property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget: null
    property string pendingPassword: ""
    property bool passwordAttempt: false
    property string errorMessage: ""
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a,b) => Number(b.active)-Number(a.active) || b.strength-a.strength)
    property string detectedWifiStatus: "disconnected"
    readonly property string wifiStatus: wifiEnabled ? detectedWifiStatus : "disabled"
    property string networkName: ""
    readonly property int networkStrength: active?.strength ?? 0
    readonly property string materialSymbol: ethernet ? "lan"
        : !wifiEnabled ? "signal_wifi_off"
        : wifiStatus === "connecting" ? "signal_wifi_statusbar_not_connected"
        : !active ? "wifi_find"
        : networkStrength > 80 ? "signal_wifi_4_bar"
        : networkStrength > 60 ? "network_wifi_3_bar"
        : networkStrength > 40 ? "network_wifi_2_bar"
        : networkStrength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"

    // nmcli escapes both delimiters and backslashes, including those inside SSIDs.
    function fields(line) {
        const result = [];
        let part = "", escaped = false;
        for (const ch of line) {
            if (escaped) { part += ch; escaped = false; }
            else if (ch === "\\") escaped = true;
            else if (ch === ":") { result.push(part); part = ""; }
            else part += ch;
        }
        result.push(part);
        return result;
    }
    function enableWifi(enabled = true) {
        if (enableWifiProc.running) return;
        root.errorMessage = "";
        enableWifiProc.exec(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
    }
    function toggleWifi() { enableWifi(!wifiEnabled); }
    function rescanWifi() {
        if (!wifiEnabled || rescanProcess.running) return;
        root.errorMessage = "";
        root.wifiScanning = true;
        rescanProcess.running = true;
    }
    function connectToWifiNetwork(accessPoint) {
        if (!accessPoint || connectProc.running || accessPoint.active) return;
        root.errorMessage = "";
        if (accessPoint.security.includes("802.1X")) {
            Quickshell.execDetached(["bash", "-c", Config.options.apps.network]);
            return;
        }
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        root.passwordAttempt = false;
        connectProc.exec(["nmcli", "--wait", "30", "device", "wifi", "connect", accessPoint.ssid]);
    }
    function changePassword(network, password, username = "") {
        if (!network || !password || connectProc.running) return;
        root.errorMessage = "";
        network.askingPassword = false;
        root.wifiConnectTarget = network;
        root.pendingPassword = password;
        root.passwordAttempt = true;
        // The password goes through stdin, never through command arguments or a file.
        connectProc.exec(["nmcli", "--ask", "--wait", "30", "device", "wifi", "connect", network.ssid]);
    }
    function disconnectWifiNetwork() {
        if (active) disconnectProc.exec(["nmcli", "device", "disconnect", activeDevice]);
    }
    property string activeDevice: ""
    function openPublicWifiPortal() { Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]); }
    function update() { refreshTimer.restart(); }
    Timer {
        id: refreshTimer
        interval: 80
        onTriggered: {
            updateConnectionType.running = true;
            wifiStatusProcess.running = true;
            getNetworks.running = true;
        }
    }
    Process {
        id: enableWifiProc
        stderr: StdioCollector { id: enableErrors }
        onExited: code => {
            if (code !== 0) root.errorMessage = Translation.tr("Could not change Wi-Fi power") + ": " + enableErrors.text.trim();
            root.update();
        }
    }
    Connections {
        target: root
        function onWifiEnabledChanged() { if (root.wifiEnabled) root.rescanWifi(); }
    }
    Process {
        id: connectProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdinEnabled: true
        onStarted: {
            if (root.passwordAttempt) {
                write(root.pendingPassword + "\n");
                root.pendingPassword = "";
            }
        }
        stdout: StdioCollector {}
        stderr: StdioCollector { id: connectErrors }
        onExited: code => {
            const network = root.wifiConnectTarget;
            const detail = connectErrors.text.trim();
            if (network) {
                network.askingPassword = code !== 0 && network.isSecure
                    && (root.passwordAttempt || /secret|password|authentication/i.test(detail));
            }
            if (code !== 0) root.errorMessage = Translation.tr("Could not connect to Wi-Fi") + (detail ? ": " + detail : "");
            root.wifiConnectTarget = null;
            root.pendingPassword = "";
            root.update();
        }
    }
    Process {
        id: disconnectProc
        stderr: StdioCollector { id: disconnectErrors }
        onExited: code => {
            if (code !== 0) root.errorMessage = Translation.tr("Could not disconnect Wi-Fi") + ": " + disconnectErrors.text.trim();
            root.update();
        }
    }
    Process {
        id: rescanProcess
        command: ["nmcli", "device", "wifi", "rescan"]
        stderr: StdioCollector { id: scanErrors }
        onExited: code => {
            root.wifiScanning = false;
            if (code !== 0) root.errorMessage = Translation.tr("Could not scan Wi-Fi networks") + ": " + scanErrors.text.trim();
            getNetworks.running = true;
        }
    }
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: root.update() }
    }
    Process {
        id: updateConnectionType
        running: true
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "device", "status"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const devices = text.trim().split("\n").filter(Boolean).map(line => root.fields(line));
                const isConnected = d => d[1] === "connected" || d[1] === "connected (externally)";
                const ethernet = devices.find(d => d[0] === "ethernet" && isConnected(d));
                const wireless = devices.find(d => d[0] === "wifi");
                root.ethernet = !!ethernet;
                root.wifiAvailable = !!wireless;
                root.wifi = !!wireless && isConnected(wireless);
                root.detectedWifiStatus = root.wifi ? "connected"
                    : wireless?.[1]?.startsWith("connecting") ? "connecting" : "disconnected";
                root.activeDevice = wireless?.[3] ?? "";
                root.networkName = ethernet?.[2] ?? (root.wifi ? wireless[2] : "");
            }
        }
    }
    Process {
        id: wifiStatusProcess
        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }
    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "--escape", "yes", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const networks = new Map();
                for (const line of text.trim().split("\n").filter(Boolean)) {
                    const f = root.fields(line);
                    if (!f[3]) continue;
                    const n = {active:f[0] === "yes", strength:Number(f[1]) || 0, frequency:Number(f[2]) || 0,
                        ssid:f[3], bssid:f[4] || "", security:f[5] || ""};
                    const previous = networks.get(n.ssid);
                    if (!previous || (n.active && !previous.active) || (!previous.active && n.strength > previous.strength)) networks.set(n.ssid,n);
                }
                const current = root.wifiNetworks;
                for (let i=current.length-1; i>=0; --i) {
                    if (!networks.has(current[i].ssid)) {
                        const removed = current[i];
                        if (removed === root.wifiConnectTarget || removed.askingPassword) continue;
                        current.splice(i,1);
                        removed.destroy();
                    }
                }
                for (const n of networks.values()) {
                    const match = current.find(ap => ap.ssid === n.ssid);
                    if (match) match.lastIpcObject = n;
                    else current.push(apComp.createObject(root,{lastIpcObject:n}));
                }
            }
        }
    }
    Component { id: apComp; WifiAccessPoint {} }
}
