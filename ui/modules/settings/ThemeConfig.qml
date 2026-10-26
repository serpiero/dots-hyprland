pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs as Dialogs
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentSection {
    id: root
    objectName: "themeSettings"
    title: Translation.tr("Theme")
    icon: "palette"
    property string profileRoot: Quickshell.env("HOME") + "/.local/share/rice-profiles"
    property var catalog: ({active:"",themes:[]})
    property string colorHex: Appearance.colors.colPrimary.toString()
    property string message: ""
    property bool failed: false
    readonly property bool busy: action.running
    readonly property var availableThemes: catalog.themes.filter(theme => theme.id === catalog.active || !/^test(?:\s|$)/i.test(theme.name))
    readonly property var favorites: availableThemes.filter(theme => theme.favorite)
    readonly property var others: availableThemes.filter(theme => !theme.favorite)
    readonly property var current: catalog.themes.find(theme => theme.id === catalog.active)

    function run(commandArgs) {
        if (root.busy) return;
        root.message = "";
        root.failed = false;
        action.exec(["python3", root.profileRoot + "/theme-manager.py", "--root", root.profileRoot, ...commandArgs]);
    }
    function refresh() {
        if (!info.running) info.running = true;
    }
    Component.onCompleted: refresh()
    Process {
        id: info
        command: ["python3", root.profileRoot + "/theme-manager.py", "--root", root.profileRoot, "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.catalog = JSON.parse(text); }
                catch(error) {root.failed=true;root.message=Translation.tr("Could not load themes");}
            }
        }
    }
    Process {
        id: action
        stdout: StdioCollector { id: actionOutput }
        stderr: StdioCollector { id: actionErrors }
        onExited: code => {
            root.failed = code !== 0;
            try {
                const result=JSON.parse(actionOutput.text);
                if (result.error) {root.message=Translation.tr("Could not update the theme") + ": " + Translation.tr(result.error);root.refresh();}
                else {root.catalog=result;root.message=Translation.tr("Theme saved");}
            } catch(error) {root.message=Translation.tr("Could not update the theme") + ": " + actionErrors.text.trim();}
        }
    }
    StyledText {
        Layout.fillWidth: true
        text: Translation.tr("Current theme: %1").arg(root.current?.name ?? "…")
        font.pixelSize: Appearance.font.pixelSize.large
    }
    StyledText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: Translation.tr("Choose a saved theme or create a matching dark palette from any color.")
    }
    StyledText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: Translation.tr("Some apps, such as Spotify and Firefox, need to be reopened to update their colors.")
        color: Appearance.colors.colSubtext
    }
    StyledText { visible: root.favorites.length > 0; text: Translation.tr("Favorites"); font.weight: Font.Medium }
    Repeater {
        model: root.favorites
        delegate: ThemeRow { required property var modelData; entry: modelData }
    }
    StyledText { visible: root.others.length > 0; text: Translation.tr("Other themes"); font.weight: Font.Medium }
    Repeater {
        model: root.others
        delegate: ThemeRow { required property var modelData; entry: modelData }
    }
    StyledText { text: Translation.tr("Custom color"); font.weight: Font.Medium; Layout.topMargin: 12 }
    RowLayout {
        Layout.fillWidth: true
        Rectangle {
            implicitWidth: 36; implicitHeight: 36
            radius: 12
            color: /^#[0-9a-fA-F]{6}$/.test(root.colorHex) ? root.colorHex : "transparent"
            border.width: 1
            border.color: Appearance.colors.colOutline
        }
        MaterialTextField {
            id: hexField
            objectName: "themeColorHex"
            Layout.fillWidth: true
            placeholderText: "#RRGGBB"
            text: root.colorHex
            validator: RegularExpressionValidator { regularExpression: /^#[0-9a-fA-F]{6}$/ }
            onTextEdited: root.colorHex = text
        }
        RippleButtonWithIcon {
            objectName: "themeColorPicker"
            materialIcon: "colorize"
            mainText: Translation.tr("Choose color")
            enabled: !root.busy
            onClicked: {
                colorDialog.selectedColor = /^#[0-9a-fA-F]{6}$/.test(root.colorHex) ? root.colorHex : Appearance.colors.colPrimary.toString();
                colorDialog.open();
            }
        }
    }
    MaterialTextField {
        id: nameField
        objectName: "themeColorName"
        Layout.fillWidth: true
        placeholderText: Translation.tr("Theme name")
        text: Translation.tr("My theme")
        maximumLength: 40
    }
    RippleButtonWithIcon {
        objectName: "themeSaveAndApply"
        materialIcon: "check"
        mainText: Translation.tr("Save and apply")
        enabled: !root.busy && /^#[0-9a-fA-F]{6}$/.test(root.colorHex) && nameField.text.trim().length > 0
        onClicked: root.run(["save", "--name", nameField.text.trim(), "--color", root.colorHex, "--apply"])
    }
    StyledText {
        Layout.fillWidth: true
        visible: root.busy || root.message.length > 0
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: root.busy ? Translation.tr("Applying theme…") : root.message
        color: root.failed ? Appearance.colors.colError : Appearance.colors.colSubtext
    }
    Dialogs.ColorDialog {
        id: colorDialog
        objectName: "themeNativeColorDialog"
        title: Translation.tr("Theme color")
        onAccepted: root.colorHex = selectedColor.toString()
    }
    component ThemeRow: RowLayout {
        required property var entry
        Layout.fillWidth: true
        spacing: 8
        Rectangle {
            implicitWidth: 32; implicitHeight: 32; radius: 10
            color: entry.background
            border.color: entry.color
            border.width: 3
        }
        RippleButtonWithIcon {
            objectName: "themeSelect_" + entry.id
            Layout.fillWidth: true
            enabled: !root.busy
            materialIcon: root.catalog.active === entry.id ? "check_circle" : "palette"
            mainText: entry.name
            onClicked: root.run(["select", entry.id])
        }
        RippleButtonWithIcon {
            objectName: "themeFavorite_" + entry.id
            implicitWidth: 44
            enabled: !root.busy
            materialIcon: entry.favorite ? "star" : "star_outline"
            mainText: ""
            onClicked: root.run(["favorite", entry.id, entry.favorite ? "false" : "true"])
        }
        RippleButtonWithIcon {
            objectName: "themeDelete_" + entry.id
            implicitWidth: 44
            enabled: !root.busy && root.catalog.themes.length > 1
            materialIcon: "delete"
            mainText: ""
            onClicked: root.run(["delete", entry.id])
            StyledToolTip {
                text: root.catalog.themes.length <= 1 ? Translation.tr("At least one theme must remain")
                    : Translation.tr("Delete theme")
            }
        }
    }
}
