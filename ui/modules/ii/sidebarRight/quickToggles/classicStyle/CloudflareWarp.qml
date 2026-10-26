import QtQuick
import qs.services
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets

QuickToggleButton {
    id: root
    CloudflareWarpToggle { id: model }
    visible: model.available
    enabled: model.available && !model.busy
    toggled: model.toggled
    buttonIcon: model.icon
    onClicked: model.mainAction()
    StyledToolTip { text: model.tooltipText }
}
