import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions

Rectangle {
    id: root
    required property var notificationObject
    property bool expanded: false
    signal toggleExpanded()
    readonly property var actions: notificationObject.actions ?? []
    readonly property bool canOpenApplication: Notifications.applicationEntry(notificationObject) !== null
    readonly property var primaryActions: Notifications.primaryActions(root.notificationObject)
    readonly property bool expandable: notificationObject.body.length > 0 || primaryActions.length > 0
    function activateCard() {
        if (root.expandable) root.toggleExpanded();
    }

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    implicitHeight: content.implicitHeight + 20
    height: implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Notifications.discardNotification(root.notificationObject.notificationId);
            else root.activateCard();
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            NotificationAppIcon {
                Layout.alignment: Qt.AlignTop
                appIcon: root.notificationObject.appIcon
                image: root.notificationObject.image
                summary: root.notificationObject.summary
                urgency: root.notificationObject.urgency
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    Layout.fillWidth: true
                    text: root.notificationObject.summary || root.notificationObject.appName
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    wrapMode: root.expanded ? Text.WordWrap : Text.NoWrap
                    maximumLineCount: root.expanded ? 3 : 1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: !root.expanded && root.notificationObject.body.length > 0
                    text: NotificationUtils.processNotificationBody(root.notificationObject.body, root.notificationObject.appName).replace(/\n/g, " ")
                    textFormat: Text.StyledText
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignTop
                text: NotificationUtils.getFriendlyNotifTimeString(root.notificationObject.time)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            RippleButton {
                objectName: "notificationExpand"
                visible: root.expandable
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: 14
                rippleEnabled: false
                onClicked: root.toggleExpanded()
                contentItem: MaterialSymbol {
                    text: root.expanded ? "keyboard_arrow_up" : "keyboard_arrow_down"
                    iconSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            RippleButton {
                objectName: "notificationDismiss"
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: 14
                rippleEnabled: false
                onClicked: Notifications.discardNotification(root.notificationObject.notificationId)
                contentItem: MaterialSymbol {
                    text: "close"
                    iconSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        StyledText {
            objectName: "notificationBody"
            Layout.fillWidth: true
            visible: root.expanded && root.notificationObject.body.length > 0
            text: NotificationUtils.processNotificationBody(root.notificationObject.body, root.notificationObject.appName).replace(/\n/g, "<br/>")
            textFormat: Text.RichText
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            onLinkActivated: link => { Qt.openUrlExternally(link); GlobalStates.sidebarRightOpen = false; }
        }

        Flow {
            objectName: "notificationActions"
            Layout.fillWidth: true
            visible: root.expanded
            spacing: 6
            Repeater {
                model: root.primaryActions
                delegate: NotificationActionButton {
                    required property var modelData
                    objectName: "notificationAction_" + modelData.identifier
                    buttonText: modelData.text
                    urgency: root.notificationObject.urgency
                    rippleEnabled: false
                    onClicked: {
                        if (modelData.kind === "copy") Quickshell.clipboardText = root.notificationObject.body || root.notificationObject.summary;
                        else if (modelData.kind === "open") Notifications.openNotification(root.notificationObject.notificationId);
                        else Notifications.attemptInvokeAction(root.notificationObject.notificationId, modelData.identifier);
                    }
                }
            }
        }
    }
}
