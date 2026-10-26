import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

DialogListItem {
    id: root
    required property var device
    property bool expanded: false
    animateHeight: false
    readonly property bool busy: device?.pairing || device?.state === BluetoothDeviceState.Connecting || device?.state === BluetoothDeviceState.Disconnecting
    pointingHandCursor: !expanded

    onClicked: expanded = !expanded
    altAction: () => expanded = !expanded
    
    component ActionButton: DialogButton {
        colBackground: Appearance.colors.colPrimary
        colBackgroundHover: Appearance.colors.colPrimaryHover
        colRipple: Appearance.colors.colPrimaryActive
        colText: Appearance.colors.colOnPrimary
    }

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            // Name
            spacing: 10

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon || "")
                color: Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: root.device?.name || Translation.tr("Unknown device")
                    textFormat: Text.PlainText
                }
                StyledText {
                    visible: (root.device?.connected || root.device?.paired || root.busy) ?? false
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: {
                        if (root.device?.pairing) return Translation.tr("Pairing…");
                        if (root.device?.state === BluetoothDeviceState.Connecting) return Translation.tr("Connecting…");
                        if (root.device?.state === BluetoothDeviceState.Disconnecting) return Translation.tr("Disconnecting…");
                        if (!root.device?.paired) return "";
                        let statusText = root.device?.connected ? Translation.tr("Connected") : Translation.tr("Paired");
                        if (!root.device?.batteryAvailable) return statusText;
                        statusText += ` • ${Math.round(root.device?.battery * 100)}%`;
                        return statusText;
                    }
                }
            }

            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer3
                rotation: root.expanded ? 180 : 0
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: root.expanded
            spacing: 6
            ActionButton {
                objectName: "bluetoothPair"
                enabled: !root.busy
                buttonText: root.device?.paired ? Translation.tr("Forget") : Translation.tr("Pair")
                onClicked: {
                    if (root.device?.paired) root.device.forget();
                    else root.device?.pair();
                }
            }
            ActionButton {
                objectName: "bluetoothConnect"
                enabled: !root.busy && (root.device?.paired ?? false)
                buttonText: root.device?.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")
                onClicked: {
                    if (root.device?.connected) root.device.disconnect();
                    else root.device?.connect();
                }
            }
            ActionButton {
                objectName: "bluetoothTrust"
                visible: root.device?.paired ?? false
                enabled: !root.busy
                buttonText: root.device?.trusted ? Translation.tr("Stop auto-connect") : Translation.tr("Always connect")
                onClicked: if (root.device) root.device.trusted = !root.device.trusted
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
