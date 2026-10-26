import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true
    property int blurSize: 14
    property int blurPasses: 3
    property bool blurReady: false
    Process {
        running: true
        command: ["hyprctl","getoption","decoration:blur:size","-j"]
        stdout: StdioCollector { onStreamFinished: { try { blurSize=JSON.parse(text).int; } catch(e) {} } }
    }
    Process {
        running: true
        command: ["hyprctl","getoption","decoration:blur:passes","-j"]
        stdout: StdioCollector { onStreamFinished: { try { blurPasses=JSON.parse(text).int; } catch(e) {} blurReady=true; } }
    }
    ThemeConfig {}
    ContentSection {
        icon: "wallpaper"
        title: Translation.tr("Wallpaper")
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: Translation.tr("Wallpaper and panel transparency")
        }
        StyledImage {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            source: Config.options.background.wallpaperPath
            fillMode: Image.PreserveAspectCrop
            cache: false
        }
        RippleButtonWithIcon {
            materialIcon: "wallpaper"
            mainText: Translation.tr("Choose wallpaper · Ctrl+Super+T")
            onClicked: Quickshell.execDetached(["qs", "ipc", "--path", Quickshell.shellPath("shell.qml"), "call", "wallpaperSelector", "toggle"])
        }
        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: Translation.tr("Panel transparency")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: Config.options.appearance.transparency.enable=checked
            StyledToolTip {
                text: Translation.tr("Makes panel backgrounds translucent so the wallpaper or windows behind them can show through. Background blur is controlled separately.")
            }
        }
    }
    ContentSection {
        icon: "blur_on"
        title: Translation.tr("System blur")
        ConfigSpinBox {
            icon: "blur_on";text: Translation.tr("Blur size")
            value: blurSize;from: 1;to: 20;stepSize: 1
            onValueChanged: {if(blurReady && value!==blurSize){blurSize=value;HyprlandConfig.set("decoration:blur:size",value);}}
        }
        ConfigSpinBox {
            icon: "layers";text: Translation.tr("Blur passes")
            value: blurPasses;from: 1;to: 4;stepSize: 1
            onValueChanged: {if(blurReady && value!==blurPasses){blurPasses=value;HyprlandConfig.set("decoration:blur:passes",value);}}
        }
        StyledText {
            Layout.fillWidth: true;wrapMode: Text.WordWrap
            text: Translation.tr("Adds a frosted-glass blur behind translucent apps (like Firefox, Spotify, or terminals) and system panels. Size controls how wide the blur spreads, and Passes make it smoother.")
        }
    }
}
