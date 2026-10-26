import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.modules.common

Controls.MenuItem {
    id: root
    property bool separator: false
    property string accelerator: ""
    implicitHeight: separator ? 9 : Math.max(34, contentItem.implicitHeight + topPadding + bottomPadding)
    implicitWidth: separator ? 24 : contentItem.implicitWidth + leftPadding + rightPadding
    leftPadding: 10
    rightPadding: 10
    topPadding: 6
    bottomPadding: 6
    indicator: null
    contentItem: RowLayout {
        visible: !root.separator
        spacing: 8
        StyledText { visible: root.checkable; text: root.checked ? "✓" : ""; Layout.preferredWidth: 12; color: Appearance.m3colors.m3onSurface }
        StyledText {
            text: root.text.replace(/&([^&])/g, "$1").replace(/&&/g, "&")
            font.pixelSize: 14
            Layout.fillWidth: true
            elide: Text.ElideRight
            color: root.enabled ? Appearance.m3colors.m3onSurface : Appearance.colors.colSubtext
        }
        StyledText { visible: root.accelerator.length > 0; text: root.accelerator; font.pixelSize: 13; color: Appearance.colors.colSubtext }
    }
    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: 4
            border.width: 0
            visible: !root.separator
            color: root.enabled && (root.highlighted || root.hovered) ? Appearance.m3colors.m3secondaryContainer : "transparent"
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 16)
            height: 1
            visible: root.separator
            color: Appearance.m3colors.m3secondaryContainer
        }
    }
}
