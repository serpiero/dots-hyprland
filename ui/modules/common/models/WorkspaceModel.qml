import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common as C

NestableObject {
    id: root

    required property HyprlandMonitor monitor
    readonly property var liveMonitorData: HyprlandData.monitors.find(m => m.id === monitor.id)
    readonly property int activeWorkspace: monitor?.activeWorkspace?.id ?? 1
    readonly property int shownCount: C.Config.options.bar.workspaces.shown
    readonly property int group: Math.floor((activeWorkspace - 1) / shownCount)
    readonly property var specialWorkspace: liveMonitorData?.specialWorkspace
    readonly property string specialWorkspaceName: specialWorkspace?.name.replace("special:", "") ?? "special"
    readonly property bool specialWorkspaceActive: specialWorkspaceName !== ""

    // Persistent/visible workspaces can exist without owning a window.
    // Derive both the occupied pill and its icon from the actual mapped clients.
    readonly property var visibleWindows: HyprlandData.windowList.filter(win =>
        win.mapped !== false && !win.hidden)
    readonly property list<bool> occupied: Array.from({length: shownCount}, (_, index) =>
        visibleWindows.some(win => win.workspace?.id === getWorkspaceIdAt(index)))
    readonly property list<var> biggestWindow: Array.from({length: shownCount}, (_, index) =>
        visibleWindows.filter(win => win.workspace?.id === getWorkspaceIdAt(index))
            .reduce((largest, win) => {
                const area = (win.size?.[0] ?? 0) * (win.size?.[1] ?? 0);
                const largestArea = (largest?.size?.[0] ?? 0) * (largest?.size?.[1] ?? 0);
                return area > largestArea ? win : largest;
            }, null))

    function getWorkspaceId(group, index) {
        return group * root.shownCount + index + 1;
    }
    function getWorkspaceIdAt(index) {
        return root.getWorkspaceId(root.group, index);
    }

}
