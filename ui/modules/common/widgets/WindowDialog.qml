import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property bool show: false
    default property alias contentData: contentColumn.data
    property real backgroundHeight: contentColumn.implicitHeight + Appearance.rounding.large * 2
    property real backgroundWidth: 350
    readonly property real edgeMargin: Math.min(16, Math.min(width, height) / 10)
    signal dismiss()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.dismiss();
            event.accepted = true;
        }
    }
    color: Appearance.colors.colScrim
    visible: show
    radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: root.dismiss()
    }
    Rectangle {
        id: dialogBackground
        objectName: "dialogSurface"
        anchors.centerIn: parent
        width: Math.max(0, Math.min(root.backgroundWidth, root.width - root.edgeMargin * 2))
        height: Math.max(0, Math.min(root.backgroundHeight, root.height - root.edgeMargin * 2))
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
        }
        Flickable {
            id: scroll
            objectName: "dialogScroll"
            anchors.fill: parent
            anchors.margins: Math.min(dialogBackground.radius, dialogBackground.width / 8)
            clip: true
            contentWidth: width
            contentHeight: Math.max(height, contentColumn.implicitHeight)
            interactive: contentHeight > height + 1
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: StyledScrollBar {}
            ColumnLayout {
                id: contentColumn
                objectName: "dialogContents"
                width: scroll.width
                height: scroll.contentHeight
                spacing: 16
            }
        }
    }
}
