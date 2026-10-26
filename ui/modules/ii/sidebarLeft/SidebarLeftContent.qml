import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 0
    anchors.fill: parent
    property bool aiChatEnabled: false
    property bool opaqueWeb: true
    readonly property bool intelligenceLoaded: webChatPage?.active ?? false
    readonly property color webPanelColor: swipeView.currentItem && swipeView.currentItem.panelColor ? swipeView.currentItem.panelColor : Appearance.colors.colLayer0Base
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property var tabButtonList: [
        {"icon": "neurology", "name": "Intelligence"},
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": "Gemini API"}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property int tabCount: swipeView.count
    property bool pagesReady: false
    property Item webChatPage: null
    property Item aiChatPage: null
    property Item translatorPage: null
    property Item animePage: null
    property Item placeholderPage: null

    // Construct tabs outside the contentChildren binding. createObject() inside a
    // binding captures initialization dependencies and can leak parentless web panels.
    function syncPages() {
        if (!pagesReady) return;
        if (!webChatPage) webChatPage=webChat.createObject(root);
        function optionalPage(current, enabled, component) {
            if (enabled) return current || component.createObject(root);
            if (current) current.destroy();
            return null;
        }
        aiChatPage=optionalPage(aiChatPage,aiChatEnabled,aiChat);
        translatorPage=optionalPage(translatorPage,translatorEnabled,translator);
        animePage=optionalPage(animePage,animeEnabled,anime);
        const showPlaceholder=tabButtonList.length===0 || (!aiChatEnabled && !translatorEnabled && animeCloset);
        placeholderPage=optionalPage(placeholderPage,showPlaceholder,placeholder);
        const desired=[webChatPage,aiChatPage,translatorPage,placeholderPage,animePage].filter(item=>item!==null);
        for (let i=swipeView.count-1;i>=0;i--) {
            const item=swipeView.itemAt(i);
            if (desired.indexOf(item)<0) swipeView.removeItem(item);
        }
        for (let i=0;i<desired.length;i++) {
            if (swipeView.itemAt(i)===desired[i]) continue;
            let previous=-1;
            for (let j=i;j<swipeView.count;j++) if (swipeView.itemAt(j)===desired[i]) {previous=j;break;}
            if (previous<0) swipeView.insertItem(i,desired[i]);
            else swipeView.moveItem(previous,i);
        }
    }
    onAiChatEnabledChanged: Qt.callLater(syncPages)
    onTranslatorEnabledChanged: Qt.callLater(syncPages)
    onAnimeEnabledChanged: Qt.callLater(syncPages)
    onAnimeClosetChanged: Qt.callLater(syncPages)
    Component.onCompleted: { pagesReady=true;Qt.callLater(syncPages); }

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Toolbar {
            visible: false
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            id: contentFrame
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: "transparent"
            // Release the offscreen texture when the panel is hidden.
            layer.enabled: GlobalStates.sidebarLeftOpen
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: contentFrame.width
                    height: contentFrame.height
                    radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
                }
            }

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex

                clip: true


            }
        }

        Component {
            id: webChat
            Loader {
                id: intelligenceLoader
                objectName: "steelIntelligenceLoader"
                readonly property bool requested: GlobalStates.sidebarLeftOpen
                readonly property color panelColor: item?.panelColor ?? Appearance.colors.colLayer0Base
                property bool keepLoaded: false
                property bool pendingTransfers: false
                active: keepLoaded || pendingTransfers
                function hasTransfers() {
                    return (item?.preparingDownload ?? false) || (item?.waitingDownload ?? false) || ((item?.downloadQueue?.length ?? 0) > 0) || ((item?.activeDownloads ?? 0) > 0);
                }
                function releaseTransfers() { pendingTransfers=hasTransfers(); }
                function syncTransfers() {
                    if (hasTransfers()) pendingTransfers=true;
                    // Debrid callbacks may clear busy before enqueuing their result.
                    // Recheck after the callback so that the profile stays alive.
                    else Qt.callLater(releaseTransfers);
                }
                Component.onCompleted: keepLoaded = requested
                onItemChanged: syncTransfers()
                onRequestedChanged: {
                    if (requested) {
                        releaseDelay.stop();
                        keepLoaded = true;
                    } else if (keepLoaded) releaseDelay.restart();
                }
                onActiveFocusChanged: if (activeFocus && item) item.forceActiveFocus()
                sourceComponent: WebChat {}
                Connections {
                    target: intelligenceLoader.item
                    function onWaitingDownloadChanged() { intelligenceLoader.syncTransfers(); }
                    function onDownloadQueueChanged() { intelligenceLoader.syncTransfers(); }
                    function onActiveDownloadsChanged() { intelligenceLoader.syncTransfers(); }
                    function onPreparingDownloadChanged() { intelligenceLoader.syncTransfers(); }
                }
                Timer { id: releaseDelay; interval: 3000; onTriggered: intelligenceLoader.keepLoaded = false }
            }
        }
        Component {
            id: aiChat
            AiChat {}
        }
        Component {
            id: translator
            Translator {}
        }
        Component {
            id: anime
            Anime {}
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
