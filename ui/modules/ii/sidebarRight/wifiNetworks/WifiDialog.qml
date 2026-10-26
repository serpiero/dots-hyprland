import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    objectName: "wifiDialog"
    backgroundHeight: 600

    WindowDialogTitle {
        text: Translation.tr("Connect to Wi-Fi")
    }
    RowLayout {
        Layout.fillWidth: true
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: !Network.wifiAvailable ? Translation.tr("No adapter found")
                : Network.wifiEnabled ? Translation.tr("On") : Translation.tr("Off")
        }
        DialogButton {
            objectName: "wifiPower"
            enabled: Network.wifiAvailable && !Network.wifiSwitching
            buttonText: Network.wifiEnabled ? Translation.tr("Turn off") : Translation.tr("Turn on")
            onClicked: Network.enableWifi(!Network.wifiEnabled)
        }
        DialogButton {
            objectName: "wifiRefresh"
            visible: Network.wifiEnabled
            enabled: !(Network.wifiScanning)
            buttonText: Translation.tr("Refresh")
            onClicked: Network.rescanWifi()
        }
    }
    StyledText {
        Layout.fillWidth: true
        visible: Network.errorMessage.length > 0
        text: Network.errorMessage
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        color: Appearance.colors.colError
    }
    StyledIndeterminateProgressBar {
        visible: Network.wifiScanning
        Layout.fillWidth: true
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 80
        ListView {
            id: devices
            objectName: "wifiDevices"
            anchors.fill: parent
            clip: true
            spacing: 0
            visible: Network.wifiEnabled
            model: ScriptModel { values: Network.friendlyWifiNetworks }
            delegate: WifiNetworkItem {
                required property WifiAccessPoint modelData
                wifiNetwork: modelData
                width: ListView.view.width
            }
            ScrollBar.vertical: StyledScrollBar {}
        }
        StyledText {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: !Network.wifiEnabled || devices.count === 0
            text: !Network.wifiAvailable ? Translation.tr("No adapter found")
                : !Network.wifiEnabled ? Translation.tr("Wi-Fi is off")
                : (Network.wifiScanning) ? Translation.tr("Searching…") : Translation.tr("No networks found")
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
                const command = Config.options.apps.network;
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