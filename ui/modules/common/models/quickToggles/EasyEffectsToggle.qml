import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("EasyEffects")

    available: EasyEffects.available
    toggled: EasyEffects.active
    icon: "graphic_eq"

    Component.onCompleted: {
        EasyEffects.fetchActiveState()
    }

    mainAction: () => {
        EasyEffects.toggle()
    }

    altAction: () => {
        GlobalStates.runAfterRightSidebarCloses(["bash", "-c",
            "if command -v easyeffects >/dev/null 2>&1; then exec easyeffects; else exec flatpak run com.github.wwmm.easyeffects; fi"]);
    }

    tooltipText: Translation.tr("EasyEffects | Right-click to configure")
}
