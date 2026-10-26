pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

/**
 * Provides extra features not in Quickshell.Services.Notifications:
 *  - Persistent storage
 *  - Popup notifications, with timeout
 *  - Notification groups by app
 */
Singleton {
	id: root
    component Notif: QtObject {
        id: wrapper
        required property int notificationId // Could just be `id` but it conflicts with the default prop in QtObject
        property Notification notification
        property int serverId: notification?.id ?? 0
        property string desktopEntry: notification?.desktopEntry ?? ""
        property list<var> actions: notification?.actions.map((action) => ({
            "identifier": action.identifier,
            "text": root.actionLabel(action.identifier, action.text),
        })) ?? []
        property bool popup: false
        property bool isTransient: notification?.hints.transient ?? false
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property double time
        property string urgency: notification?.urgency.toString() ?? "normal"
        property Timer timer

        onNotificationChanged: {
            if (notification === null) {
                root.discardNotification(notificationId);
            }
        }
    }

    function notifToJSON(notif) {
        return {
            "notificationId": notif.notificationId,
            "serverId": notif.serverId,
            "desktopEntry": notif.desktopEntry,
            "actions": notif.actions,
            "appIcon": notif.appIcon,
            "appName": notif.appName,
            "body": notif.body,
            "image": notif.image,
            "summary": notif.summary,
            "time": notif.time,
            "urgency": notif.urgency,
        }
    }
    function notifToString(notif) {
        return JSON.stringify(notifToJSON(notif), null, 2);
    }

    component NotifTimer: Timer {
        required property int notificationId
        interval: 7000
        running: true
        onTriggered: () => {
            const index = root.list.findIndex((notif) => notif.notificationId === notificationId);
            const notifObject = root.list[index];
            print("[Notifications] Notification timer triggered for ID: " + notificationId + ", transient: " + notifObject?.isTransient);
            if (notifObject) {
                if (notifObject.isTransient) root.discardNotification(notificationId);
                else root.timeoutNotification(notificationId);
            }
            destroy()
        }
    }

    property bool silent: false
    property int unread: 0
    property var filePath: Directories.notificationsPath
    // QObject keeps wrappers compatible across Quickshell's cached QML generations.
    property list<QtObject> list: []
    property var popupList: list.filter((notif) => notif.popup);
    property bool popupInhibited: (GlobalStates?.sidebarRightOpen ?? false) || silent
    property var latestTimeForApp: ({})
    Component {
        id: notifComponent
        Notif {}
    }
    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    function stringifyList(list) {
        return JSON.stringify(list.map((notif) => notifToJSON(notif)), null, 2);
    }
    
    onListChanged: {
        // Update latest time for each app
        root.list.forEach((notif) => {
            if (!root.latestTimeForApp[notif.appName] || notif.time > root.latestTimeForApp[notif.appName]) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time);
            }
        });
        // Remove apps that no longer have notifications
        Object.keys(root.latestTimeForApp).forEach((appName) => {
            if (!root.list.some((notif) => notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => {
            // Sort by time, descending
            return groups[b].time - groups[a].time;
        });
    }

    function groupsForList(list) {
        const groups = {};
        list.forEach((notif) => {
            if (!groups[notif.appName]) {
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    notifications: [],
                    time: 0
                };
            }
            groups[notif.appName].notifications.push(notif);
            // Always set to the latest time in the group
            groups[notif.appName].time = latestTimeForApp[notif.appName] || notif.time;
        });
        return groups;
    }

    property var groupsByAppName: groupsForList(root.list)
    property var popupGroupsByAppName: groupsForList(root.popupList)
    property list<string> appNameList: appNameListForGroups(root.groupsByAppName)
    property list<string> popupAppNameList: appNameListForGroups(root.popupGroupsByAppName)

    // Quickshell's notification IDs starts at 1 on each run, while saved notifications
    // can already contain higher IDs. This is for avoiding id collisions
    property int idOffset
    property bool historyReady: false
    property var pendingNotifications: []
    signal initDone();
    signal notify(notification: var);
    signal discard(id: int);
    signal discardAll();
    signal timeout(id: var);

	NotificationServer {
        id: notifServer
        // actionIconsSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: true
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            if (!root.historyReady) {
                root.pendingNotifications = [...root.pendingNotifications, notification];
                return;
            }
            root.receiveNotification(notification);
        }
    }

    function receiveNotification(notification) {
            const previous = root.list.find(notif => notif.serverId === notification.id
                && (notif.notification !== null || notification.lastGeneration));
            if (previous) {
                previous.timer?.stop();
                root.list = root.list.filter(notif => notif !== previous);
            }
            const newNotifObject = notifComponent.createObject(root, {
                "notificationId": previous?.notificationId ?? (notification.id + root.idOffset),
                "notification": notification,
                "time": previous?.time ?? Date.now(),
            });
			root.list = [...root.list, newNotifObject];

            // Popup
            if (!root.popupInhibited && !notification.lastGeneration) {
                newNotifObject.popup = true;
                if (notification.expireTimeout != 0) {
                    newNotifObject.timer = notifTimerComponent.createObject(root, {
                        "notificationId": newNotifObject.notificationId,
                        "interval": notification.expireTimeout < 0 ? (Config?.options.notifications.timeout ?? 7000) : notification.expireTimeout,
                    });
                }
                root.unread++;
            }
            root.notify(newNotifObject);
            // console.log(notifToString(newNotifObject));
            notifFileView.setText(stringifyList(root.list));
    }

    function finishHistoryLoad() {
        root.idOffset = root.list.reduce((maximum, notif) => Math.max(maximum, notif.notificationId), 0);
        root.historyReady = true;
        const pending = root.pendingNotifications;
        root.pendingNotifications = [];
        pending.forEach(notification => root.receiveNotification(notification));
        root.initDone();
    }

    function markAllRead() {
        root.unread = 0;
    }

    function discardNotification(id) {
        console.log("[Notifications] Discarding notification with ID: " + id);
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        const liveNotification = index !== -1 ? root.list[index].notification : null;
        if (index !== -1) {
            root.list[index].timer?.stop();
            root.list.splice(index, 1);
            notifFileView.setText(stringifyList(root.list));
            triggerListChange()
        }
        if (liveNotification) liveNotification.dismiss();
        root.discard(id); // Emit signal
    }

    function discardAllNotifications() {
        root.list.forEach(notif => notif.timer?.stop());
        root.list = []
        triggerListChange()
        notifFileView.setText(stringifyList(root.list));
        notifServer.trackedNotifications.values.slice().forEach((notif) => {
            notif.dismiss()
        })
        root.discardAll();
    }

    function cancelTimeout(id) {
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        if (root.list[index] != null)
            root.list[index].timer?.stop();
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        if (root.list[index] != null)
            root.list[index].popup = false;
        root.timeout(id);
    }

    function timeoutAll() {
        root.popupList.forEach((notif) => {
            root.timeout(notif.notificationId);
        })
        root.popupList.forEach((notif) => {
            notif.popup = false;
        });
    }

    function attemptInvokeAction(id, notifIdentifier) {
        const notif = root.list.find(item => item.notificationId === id);
        const action = notif?.notification?.actions.find(item => item.identifier === notifIdentifier);
        if (!action) {
            console.warn("[Notifications] Action is no longer available:", id, notifIdentifier);
            return false;
        }
        // invoke() closes non-resident notifications itself. Dismissing here also
        // destroys resident notifications and can race the sender's action handler.
        action.invoke();
        if (["default", "open", "activate"].includes(notifIdentifier.toLowerCase()))
            GlobalStates.sidebarRightOpen = false;
        return true;
    }

    function primaryActions(notif) {
        const actions = notif.actions ?? [];
        const selected = [];
        const opening = root.openingAction(notif);
        const openAction = opening ? actions.find(action => action.identifier === opening.identifier) : null;
        if (openAction) selected.push({kind:"action",identifier:openAction.identifier,text:openAction.text});
        else if ((root.applicationEntry(notif) !== null)) selected.push({kind:"open",identifier:"local_open",text:Translation.tr("Open application")});
        for (const action of actions) {
            if (selected.length === 3) break;
            if (selected.some(item => item.kind === "action" && item.identifier === action.identifier) || ["close", "dismiss"].includes(action.identifier.toLowerCase())
                || ["close", "dismiss"].includes(action.text.trim().toLowerCase())) continue;
            selected.push({kind:"action",identifier:action.identifier,text:action.text});
        }
        if (selected.length < 3 && (notif.body || notif.summary))
            selected.push({kind:"copy",identifier:"local_copy",text:Translation.tr("Copy text")});
        return selected;
    }

    function actionLabel(identifier, text) {
        const label = text.trim().toLowerCase();
        return (identifier === "default" && !label) || ["open", "activate"].includes(label) ? Translation.tr("Open") : text;
    }

    function openingAction(notif) {
        return notif.notification?.actions.find(item => item.identifier === "default")
            ?? notif.notification?.actions.find(item => ["open", "activate"].includes(item.identifier.toLowerCase()));
    }

    function applicationEntry(notif) {
        let entry = notif.desktopEntry ? DesktopEntries.byId(notif.desktopEntry) : null;
        if (!entry) {
            const matches = DesktopEntries.applications.values.filter(app =>
                app.name.toLowerCase() === notif.appName.toLowerCase());
            if (matches.length === 1) entry = matches[0];
        }
        return entry;
    }

    function openNotification(id) {
        const notif = root.list.find(item => item.notificationId === id);
        if (!notif) return false;
        const action = root.openingAction(notif);
        if (action) return root.attemptInvokeAction(id, action.identifier);
        const entry = root.applicationEntry(notif);
        if (!entry) return false;
        entry.execute();
        GlobalStates.sidebarRightOpen = false;
        return true;
    }

    function triggerListChange() {
        root.list = root.list.slice(0)
    }

    function refresh() {
        notifFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: notifFileView
        path: Qt.resolvedUrl(filePath)
        onLoaded: {
            if (root.historyReady) return;
            const fileContents = notifFileView.text()
            let saved = [];
            try {
                const parsed = JSON.parse(fileContents);
                if (Array.isArray(parsed)) saved = parsed;
            } catch (error) {
                console.warn("[Notifications] Could not restore history:", error);
            }
            root.list = saved.map((notif) => {
                return notifComponent.createObject(root, {
                    "notificationId": notif.notificationId,
                    "serverId": notif.serverId ?? 0,
                    "desktopEntry": notif.desktopEntry ?? "",
                    "actions": [], // Notification actions are meaningless if they're not tracked by the server or the sender is dead
                    "appIcon": notif.appIcon,
                    "appName": notif.appName,
                    "body": notif.body,
                    "image": notif.image,
                    "summary": notif.summary,
                    "time": notif.time,
                    "urgency": notif.urgency,
                });
            });
            console.log("[Notifications] File loaded")
            root.finishHistoryLoad();
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[Notifications] File not found, creating new file.")
                root.list = []
                notifFileView.setText(stringifyList(root.list));
            } else {
                console.log("[Notifications] Error loading file: " + error)
            }
            if (!root.historyReady) root.finishHistoryLoad();
        }
    }
}
