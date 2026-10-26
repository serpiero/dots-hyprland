import QtQuick
import QtQuick.Controls as Controls
import qs.modules.common

Controls.Menu {
    id: root
    objectName: "riceContextMenu"
    popupType: Controls.Popup.Item
    padding: 4
    margins: 4
    readonly property real preferredContentWidth: {
        let result=0;
        for(let i=0;i<count;i++) {
            const item=itemAt(i);
            if(!item || item.separator)continue;
            const label=item.text.replace(/&([^&])/g,"$1").replace(/&&/g,"&");
            const shortcut=item.accelerator ?? "";
            result=Math.max(result,metrics.advanceWidth(label)+20+(shortcut.length?metrics.advanceWidth(shortcut)+8:0)+(item.checkable?20:0));
        }
        return result;
    }
    implicitWidth: Math.max(180,preferredContentWidth+leftPadding+rightPadding)
    width: Math.min(360, implicitWidth)
    FontMetrics { id:metrics;font.family:Appearance.font.family.main;font.pixelSize:14 }
    palette.window: Appearance.m3colors.m3surfaceContainerHigh
    palette.windowText: Appearance.m3colors.m3onSurface
    palette.buttonText: Appearance.m3colors.m3onSurface
    palette.highlight: Appearance.m3colors.m3secondaryContainer
    palette.highlightedText: Appearance.m3colors.m3onSurface
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    background: Rectangle {
        implicitWidth: 180
        radius: 8
        border.width: 0
        color: Appearance.m3colors.m3surfaceContainerHigh
    }
    delegate: StyledContextMenuItem { }
    enter: Transition { }
    exit: Transition { }
}
