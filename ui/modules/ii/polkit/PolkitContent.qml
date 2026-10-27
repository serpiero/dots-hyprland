import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
    id: root
    readonly property bool usePasswordChars: !(PolkitService.flow?.responseVisible ?? false)

    function submit() {
        PolkitService.submit(inputField.text);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            PolkitService.cancel();
            event.accepted = true;
        }
    }

    Connections {
        target: PolkitService
        function onInteractionAvailableChanged() {
            if (!PolkitService.interactionAvailable) return;
            inputField.text = "";
            inputField.forceActiveFocus();
        }
    }

    // The transparent layer surface uses the compositor's existing panel blur.
    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colScrim
    }

    Rectangle {
        id: card
        objectName: "polkitCard"
        anchors.centerIn: parent
        width: Math.max(0, Math.min(450, root.width - 32))
        height: Math.max(0, Math.min(contentColumn.implicitHeight + 48, root.height - 32))
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0
        border.width: 0
        clip: true

        Flickable {
            id: scroll
            anchors.fill: parent
            anchors.margins: Math.min(24, card.width / 8, card.height / 8)
            contentWidth: width
            contentHeight: Math.max(height, contentColumn.implicitHeight)
            interactive: contentHeight > height + 1
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.vertical: StyledScrollBar {}

            ColumnLayout {
                id: contentColumn
                width: scroll.width
                spacing: 16

                MaterialSymbol {
                    objectName: "polkitIcon"
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 26
                    text: "security"
                    color: Appearance.colors.colPrimary
                }

                WindowDialogTitle {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Authentication")
                }

                WindowDialogParagraph {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    text: PolkitService.cleanMessage
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        objectName: "polkitPasswordLabel"
                        Layout.fillWidth: true
                        text: PolkitService.cleanPrompt
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    Basic.TextField {
                        id: inputField
                        objectName: "polkitPassword"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 44
                        implicitHeight: 44
                        leftPadding: 12
                        rightPadding: 12
                        topPadding: 10
                        bottomPadding: 10
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.small
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        enabled: PolkitService.interactionAvailable
                        Accessible.name: PolkitService.cleanPrompt
                        echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                        color: Appearance.colors.colOnLayer0
                        selectionColor: Appearance.colors.colPrimary
                        selectedTextColor: Appearance.colors.colOnPrimary
                        onAccepted: root.submit()
                        Component.onCompleted: Qt.callLater(() => inputField.forceActiveFocus())

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, Appearance.backgroundTransparency)
                            border.width: 1
                            border.color: inputField.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                PolkitService.cancel();
                                event.accepted = true;
                            }
                        }
                    }
                }

                RowLayout {
                    id: actions
                    objectName: "polkitActions"
                    Layout.fillWidth: true
                    spacing: 8
                    Item { Layout.fillWidth: true }
                    DialogButton {
                        Layout.minimumWidth: 88
                        Layout.minimumHeight: 36
                        buttonText: Translation.tr("Cancel")
                        onClicked: PolkitService.cancel()
                    }
                    DialogButton {
                        objectName: "polkitConfirm"
                        Layout.minimumWidth: 72
                        Layout.minimumHeight: 36
                        enabled: PolkitService.interactionAvailable
                        buttonText: Translation.tr("OK")
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        colRipple: Appearance.colors.colPrimaryActive
                        colEnabled: Appearance.colors.colOnPrimary
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}
