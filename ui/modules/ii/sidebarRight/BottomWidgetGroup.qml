pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.calendar
import qs.modules.ii.sidebarRight.todo
import qs.modules.ii.sidebarRight.pomodoro
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    objectName: "bottomWidgetGroup"
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true
    implicitHeight: collapsed ? collapsedBottomWidgetGroupRow.implicitHeight :
        (selectedTab === 0 ? calendarPage.implicitHeight + 20 : 320)
    property int selectedTab: Persistent.states.sidebar.bottomGroup.tab
    property bool collapsed: Persistent.states.sidebar.bottomGroup.collapsed
    property var tabs: [
        {
            "type": "calendar",
            "name": Translation.tr("Calendar"),
            "icon": "calendar_month"
        },
        {
            "type": "todo",
            "name": Translation.tr("To Do"),
            "icon": "done_outline"
        },
        {
            "type": "timer",
            "name": Translation.tr("Timer"),
            "icon": "schedule"
        },
    ]

    function setCollapsed(state) {
        // Update the visible state immediately, independently of debounced file reloads.
        root.collapsed = state;
        Persistent.states.sidebar.bottomGroup.collapsed = state;
    }

    function selectTab(index) {
        root.selectedTab = index;
        Persistent.states.sidebar.bottomGroup.tab = index;
    }

    Keys.onPressed: event => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                root.selectTab(Math.min(root.selectedTab + 1, root.tabs.length - 1));
            } else if (event.key === Qt.Key_PageUp) {
                root.selectTab(Math.max(root.selectedTab - 1, 0));
            }
            event.accepted = true;
        }
    }

    // The thing when collapsed
    RowLayout {
        id: collapsedBottomWidgetGroupRow
        objectName: "bottomCollapsedRow"
        visible: root.collapsed

        spacing: 15

        CalendarHeaderButton {
            objectName: "bottomExpand"
            Layout.margins: 10
            Layout.rightMargin: 0
            forceCircle: true
            downAction: () => {
                root.setCollapsed(false);
            }
            contentItem: MaterialSymbol {
                text: "keyboard_arrow_up"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer1
            }
        }

        StyledText {
            property int remainingTasks: Todo.list.filter(task => !task.done).length
            Layout.margins: 10
            Layout.leftMargin: 0
            text: Translation.tr("%1   •   %2 tasks").arg(DateTime.collapsedCalendarFormat).arg(remainingTasks)
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }
    }

    // The thing when expanded
    RowLayout {
        id: bottomWidgetGroupRow

        objectName: "bottomExpandedRow"
        visible: !root.collapsed

        anchors.fill: parent
        spacing: 10

        // Navigation rail
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.leftMargin: 10
            Layout.topMargin: 10
            implicitWidth: tabBar.implicitWidth
            // Navigation rail buttons
            NavigationRailTabArray {
                id: tabBar
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                currentIndex: root.selectedTab
                expanded: false
                Repeater {
                    model: root.tabs
                    NavigationRailButton {
                        required property int index
                        required property var modelData
                        objectName: "bottomTab_" + modelData.type
                        showToggledHighlight: false
                        toggled: root.selectedTab == index
                        buttonText: modelData.name
                        buttonIcon: modelData.icon
                        onPressed: {
                            root.selectTab(index);
                        }
                    }
                }
            }
            // Collapse button
            CalendarHeaderButton {
                objectName: "bottomCollapse"
                anchors.left: parent.left
                anchors.top: parent.top
                forceCircle: true
                downAction: () => {
                    root.setCollapsed(true);
                }
                contentItem: MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Keep the three pages ready so switching never waits for a loader or fade.
        StackLayout {
            id: tabStack
            objectName: "bottomPages"
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.selectedTab

            CalendarWidget { id: calendarPage }
            TodoWidget {}
            PomodoroWidget {}
        }
    }
}
