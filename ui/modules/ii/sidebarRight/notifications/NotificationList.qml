import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property var expandedIds: []
    readonly property var notifications: Notifications.list.slice().sort((a, b) => b.time - a.time)
    readonly property int cardCount: listview.count
    readonly property real viewportHeight: notifications.length === 0 ? 64 : Math.min(320, Math.max(64, listview.contentHeight))
    implicitHeight: viewportHeight + statusRow.implicitHeight + 10

    Connections {
        target: Notifications
        function onListChanged() {
            root.expandedIds = root.expandedIds.filter(id => Notifications.list.some(n => n.notificationId === id));
        }
    }

    ListView {
        id: listview
        objectName: "notificationCards"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        anchors.bottomMargin: 5
        visible: count > 0
        clip: true
        spacing: 5
        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 3500
        ScrollBar.vertical: StyledScrollBar {}
        model: ScriptModel { values: root.notifications }
        delegate: SidebarNotificationCard {
            required property var modelData
            width: listview.width
            notificationObject: modelData
            expanded: root.expandedIds.includes(modelData.notificationId)
            onToggleExpanded: {
                const id = modelData.notificationId;
                root.expandedIds = expanded ? root.expandedIds.filter(value => value !== id) : [...root.expandedIds, id];
            }
        }
    }

    RowLayout {
        objectName: "emptyNotificationState"
        visible: root.notifications.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: (root.viewportHeight - height) / 2
        spacing: 10
        MaterialSymbol {
            text: "notifications_none"
            iconSize: 24
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: Translation.tr("No notifications")
            color: Appearance.colors.colSubtext
        }
    }

    ButtonGroup {
        id: statusRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "notifications_paused"
            toggled: Notifications.silent
            onClicked: Notifications.silent = !Notifications.silent
        }
        NotificationStatusButton {
            enabled: false
            Layout.fillWidth: true
            buttonText: Translation.tr("%1 notifications").arg(root.notifications.length)
        }
        NotificationStatusButton {
            enabled: root.notifications.length > 0
            Layout.fillWidth: false
            buttonIcon: "delete_sweep"
            onClicked: Notifications.discardAllNotifications()
        }
    }
}
