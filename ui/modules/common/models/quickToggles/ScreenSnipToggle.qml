import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Screen snip")
    hasStatusText: false
    toggled: false
    icon: "screenshot_region"

    mainAction: () => {
        GlobalStates.runAfterRightSidebarCloses(["qs", "ipc", "--path", Quickshell.shellPath("shell.qml"), "call", "region", "screenshot"]);
    }

    tooltipText: Translation.tr("Screen snip")
}
