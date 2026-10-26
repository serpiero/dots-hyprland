import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    objectName: "bluetoothDialog"
    backgroundHeight: 600

    WindowDialogTitle {
        text: Translation.tr("Bluetooth devices")
    }
    RowLayout {
        Layout.fillWidth: true
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: !BluetoothStatus.available ? Translation.tr("No adapter found")
                : BluetoothStatus.enabled ? Translation.tr("On") : Translation.tr("Off")
        }
        DialogButton {
            objectName: "bluetoothPower"
            enabled: BluetoothStatus.available && !BluetoothStatus.busy
            buttonText: BluetoothStatus.enabled ? Translation.tr("Turn off") : Translation.tr("Turn on")
            onClicked: BluetoothStatus.setEnabled(!BluetoothStatus.enabled)
        }
        DialogButton {
            objectName: "bluetoothRefresh"
            visible: BluetoothStatus.enabled
            enabled: !(Bluetooth.defaultAdapter?.discovering ?? false)
            buttonText: Translation.tr("Refresh")
            onClicked: BluetoothStatus.requestDiscovery(true)
        }
    }
    StyledText {
        Layout.fillWidth: true
        visible: BluetoothStatus.errorMessage.length > 0
        text: BluetoothStatus.errorMessage
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        color: Appearance.colors.colError
    }
    StyledIndeterminateProgressBar {
        visible: Bluetooth.defaultAdapter?.discovering ?? false
        Layout.fillWidth: true
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 80
        ListView {
            id: devices
            objectName: "bluetoothDevices"
            anchors.fill: parent
            clip: true
            spacing: 0
            visible: BluetoothStatus.enabled
            model: ScriptModel { values: BluetoothStatus.friendlyDeviceList }
            delegate: BluetoothDeviceItem {
                required property BluetoothDevice modelData
                device: modelData
                width: ListView.view.width
            }
            ScrollBar.vertical: StyledScrollBar {}
        }
        StyledText {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: !BluetoothStatus.enabled || devices.count === 0
            text: !BluetoothStatus.available ? Translation.tr("No adapter found")
                : !BluetoothStatus.enabled ? Translation.tr("Bluetooth is off")
                : (Bluetooth.defaultAdapter?.discovering ?? false) ? Translation.tr("Searching…") : Translation.tr("No devices found")
        }
    }
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        Layout.fillWidth: true
        Layout.margins: 0
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        Layout.minimumHeight: 52
        Layout.preferredHeight: 52

        DialogButton {
            implicitHeight: 44
            Layout.minimumHeight: 44
            buttonText: Translation.tr("Details")
            onClicked: {
                const command = Config.options.apps.bluetooth;
                root.dismiss();
                GlobalStates.runAfterRightSidebarCloses(["bash", "-c", command]);
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            implicitHeight: 44
            Layout.minimumHeight: 44
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
