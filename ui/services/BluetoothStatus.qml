pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import qs.services

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    property bool discoveryRequested: false
    property string errorMessage: ""
    property bool changingPower: false
    property bool requestedPower: false
    property int powerRetries: 0
    readonly property bool busy: changingPower || unblockProc.running || powerProc.running
        || Bluetooth.defaultAdapter?.state === BluetoothAdapterState.Enabling
        || Bluetooth.defaultAdapter?.state === BluetoothAdapterState.Disabling
    readonly property bool blocked: Bluetooth.defaultAdapter?.state === BluetoothAdapterState.Blocked

    function finishPower(error = "") {
        powerRetryTimer.stop();
        root.changingPower = false;
        root.errorMessage = error;
        root.syncDiscovery();
    }
    function retryPower(error) {
        if (root.powerRetries < 1) {
            root.powerRetries++;
            powerRetryTimer.restart();
        } else root.finishPower(error);
    }
    function setEnabled(value) {
        if (!root.available) return;
        const adapter = Bluetooth.defaultAdapter;
        const transitioning = adapter.state === BluetoothAdapterState.Enabling
            || adapter.state === BluetoothAdapterState.Disabling;
        if (value === root.enabled && !transitioning) {
            root.errorMessage = "";
            return;
        }
        if (root.changingPower) return;
        root.errorMessage = "";
        root.requestedPower = value;
        root.powerRetries = 0;
        root.changingPower = true;
        root.syncDiscovery();
        if (value) unblockProc.running = true;
        else powerRetryTimer.restart();
    }
    function applyPower() {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter) {
            root.finishPower(Translation.tr("Bluetooth adapter is unavailable"));
            return;
        }
        const transitioning = adapter.state === BluetoothAdapterState.Enabling
            || adapter.state === BluetoothAdapterState.Disabling;
        if (root.requestedPower === root.enabled && !transitioning) {
            root.finishPower();
            return;
        }
        if (adapter.discovering || transitioning) {
            root.syncDiscovery();
            root.retryPower(Translation.tr("Bluetooth is busy. Try again."));
            return;
        }
        powerProc.exec(["bluetoothctl", "power", root.requestedPower ? "on" : "off"]);
    }
    function requestDiscovery(value) {
        root.discoveryRequested = value;
        root.syncDiscovery();
    }
    function syncDiscovery() {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter) return;
        if (!root.discoveryRequested || root.changingPower) {
            if (adapter.discovering) adapter.discovering = false;
        } else if (adapter.state === BluetoothAdapterState.Enabled && !adapter.discovering) {
            adapter.discovering = true;
        }
    }
    onEnabledChanged: {
        if (root.enabled) root.errorMessage = "";
    }
    Connections {
        target: Bluetooth.defaultAdapter
        function onStateChanged() {
            if (Bluetooth.defaultAdapter?.state === BluetoothAdapterState.Enabled)
                root.errorMessage = "";
            root.syncDiscovery();
        }
    }
    Timer {
        id: powerRetryTimer
        interval: 300
        repeat: false
        onTriggered: root.applyPower()
    }
    Process {
        id: unblockProc
        command: ["rfkill", "unblock", "bluetooth"]
        stderr: StdioCollector { id: unblockErrors }
        onExited: code => {
            if (root.requestedPower === root.enabled) root.finishPower();
            else if (code === 0) powerRetryTimer.restart();
            else root.finishPower(Translation.tr("Could not enable Bluetooth") + ": " + unblockErrors.text.trim());
        }
    }
    Process {
        id: powerProc
        stderr: StdioCollector { id: powerErrors }
        stdout: StdioCollector { id: powerOutput }
        onExited: code => {
            const detail = powerErrors.text.trim() || powerOutput.text.trim();
            if (root.requestedPower === root.enabled) root.finishPower();
            else if (code === 0 || /org\.bluez\.Error\.(Busy|InProgress)/i.test(detail))
                root.retryPower(Translation.tr("Could not change Bluetooth power") + (detail ? ": " + detail : ""));
            else root.finishPower(Translation.tr("Could not change Bluetooth power") + ": " + detail);
        }
    }

    function sortFunction(a, b) {
        // Ones with meaningful names before MAC addresses
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;

        // Alphabetical by name
        return a.name.localeCompare(b.name);
    }
    property list<var> connectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(sortFunction)
    property list<var> pairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(sortFunction)
    property list<var> unpairedDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected).sort(sortFunction)
    property list<var> friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]
}
