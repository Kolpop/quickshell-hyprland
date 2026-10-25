import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    required property var cfg
    signal closeRequested()
    signal requestWidgetEditor(string mode)

    width: 960
    height: 640
    radius: 24
    color: root.cfg.bgSurface
    border.color: root.cfg.borderCol
    border.width: 1

    property string tab: "bar" // "bar", "dock", "widgets", "side", "themes", "osd", "lock", "system"
    onTabChanged: {
        if (typeof tabFlickable !== "undefined" && tabFlickable) tabFlickable.contentY = 0
    }

    function scrollContent(y) {
        if (typeof tabFlickable !== "undefined" && tabFlickable) {
            tabFlickable.contentY = Math.max(0, Math.min(tabFlickable.contentHeight - tabFlickable.height, y))
        }
    }

    focus: true
    Keys.onEscapePressed: root.closeRequested()
    Shortcut { sequence: "Escape"; onActivated: root.closeRequested() }

    Process { id: settingsSysProc }
    property bool clampToMonitor: false

    Process {
        id: checkClampProc
        running: true
        command: ["python3", "/home/stopnope/.config/quickshell/scripts/vxwm_controller.py", "status"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                try {
                    let st = JSON.parse(data.trim())
                    root.clampToMonitor = st.clampToMonitor === true
                } catch(e) {}
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ВЕРХНЯЯ ШАПКА ОКНА НАСТРОЕК
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 4
            Layout.topMargin: 2
            Layout.bottomMargin: 2

            Text {
                text: "Настройки"
                color: root.cfg.textPrimary
                font.pixelSize: 16
                font.bold: true
                font.family: root.cfg.fontFamily
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: closeBtnMouse.containsMouse ? root.cfg.bgElevated : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closeBtnMouse.containsMouse ? root.cfg.textPrimary : root.cfg.textMuted
                    font.pixelSize: 14
                }
                MouseArea {
                    id: closeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // ОСНОВНОЙ СПЛИТ-ЛЕЙАУТ: НАВИГАЦИЯ СЛЕВА + КОНТЕНТ СПРАВА
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // ЛЕВАЯ ПАНЕЛЬ НАВИГАЦИИ
            Rectangle {
                Layout.preferredWidth: 190
                Layout.fillHeight: true
                radius: 16
                color: root.cfg.bgElevated
                border.color: root.cfg.borderCol
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 3

                    Repeater {
                        model: [
                            { id: "bar", title: "Бар и модули", icon: "󰕮" },
                            { id: "dock", title: "Док-бар", icon: "󰀻" },
                            { id: "widgets", title: "Виджеты", icon: "󰕰" },
                            { id: "side", title: "Шторка", icon: "󰍜" },
                            { id: "themes", title: "Темы", icon: "󰏘" },
                            { id: "osd", title: "Индикаторы OSD", icon: "󰂚" },
                            { id: "lock", title: "Блокировка", icon: "󰌾" },
                            { id: "system", title: "Система", icon: "󰒋" }
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 10

                            readonly property bool isSelected: root.tab === modelData.id
                            color: isSelected
                                   ? Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.15)
                                   : (navMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.04) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: isSelected ? root.cfg.accent : (navMouse.containsMouse ? root.cfg.textPrimary : root.cfg.textMuted)
                                    font.pixelSize: 15
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: isSelected ? root.cfg.accent : (navMouse.containsMouse ? root.cfg.textPrimary : root.cfg.textPrimary)
                                    font.pixelSize: 12
                                    font.bold: isSelected
                                    font.family: root.cfg.fontFamily
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.tab = modelData.id
                                    root.forceActiveFocus()
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ПРАВАЯ РАБОЧАЯ ОБЛАСТЬ
            Rectangle {
                id: mainWorkArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: root.cfg.bgPrimary
                border.color: root.cfg.borderCol
                border.width: 1
                clip: true

                Flickable {
                    id: tabFlickable
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: tabContentItem.implicitHeight + 30
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: wheel => {
                            let step = wheel.angleDelta.y > 0 ? -70 : 70
                            let newY = tabFlickable.contentY + step
                            tabFlickable.contentY = Math.max(0, Math.min(tabFlickable.contentHeight - tabFlickable.height, newY))
                        }
                    }

                    Item {
                        id: tabContentItem
                        width: tabFlickable.width
                        implicitHeight: {
                            if (root.tab === "bar") return barTabCol.implicitHeight
                            if (root.tab === "dock") return dockTabCol.implicitHeight
                            if (root.tab === "side") return sideTabCol.implicitHeight
                            if (root.tab === "widgets") return widgetsTabCol.implicitHeight
                            if (root.tab === "lock") return lockTabCol.implicitHeight
                            if (root.tab === "themes") return themesTabCol.implicitHeight
                            if (root.tab === "osd") return osdTabCol.implicitHeight
                            if (root.tab === "system") return systemTabCol.implicitHeight
                            return 700
                        }

                        // ================= ВКЛАДКА 1: БАР И МОДУЛИ =================
                        ColumnLayout {
                            id: barTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 12
                            visible: root.tab === "bar"

                            function getBarMod(id) {
                                if (!root.cfg || !root.cfg.allBarModules) return { id: id, name: id, icon: "󰍛" }
                                if (typeof id === "string" && id.indexOf("+") !== -1) {
                                    let parts = id.split("+")
                                    let names = []
                                    let icons = []
                                    for (let p of parts) {
                                        let found = root.cfg.allBarModules.find(x => x.id === p)
                                        if (found) {
                                            names.push(found.name)
                                            icons.push(found.icon)
                                        } else {
                                            names.push(p)
                                            icons.push("󰍛")
                                        }
                                    }
                                    return { id: id, name: names.join(" + "), icon: icons.join(" "), isGroup: true, parts: parts }
                                }
                                for (let i = 0; i < root.cfg.allBarModules.length; i++) {
                                    if (root.cfg.allBarModules[i].id === id) return root.cfg.allBarModules[i]
                                }
                                return { id: id, name: id, icon: "󰍛" }
                            }

                            function getUnusedBarMods() {
                                if (!root.cfg || !root.cfg.allBarModules) return []
                                let left = root.cfg.barModulesLeft || []
                                let center = root.cfg.barModulesCenter || []
                                let right = root.cfg.barModulesRight || []
                                let used = []
                                left.concat(center).concat(right).forEach(m => {
                                    if (typeof m === "string" && m.indexOf("+") !== -1) m.split("+").forEach(x => used.push(x))
                                    else used.push(m)
                                })
                                return root.cfg.allBarModules.filter(m => !used.includes(m.id))
                            }

                            // Верхняя строка с кнопками быстрого действия
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Панель задач"
                                    color: root.cfg.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: root.cfg.fontFamily
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    height: 30
                                    implicitWidth: openEdTxt.implicitWidth + 24
                                    radius: 15
                                    color: root.cfg.accent

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "󰕮"; color: root.cfg.accentText; font.pixelSize: 12 }
                                        Text {
                                            id: openEdTxt
                                            text: "Настроить на экране"
                                            color: root.cfg.accentText
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.closeRequested()
                                            root.requestWidgetEditor("bar")
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 30
                                    implicitWidth: 70
                                    radius: 15
                                    color: root.cfg.bgElevated
                                    border.color: root.cfg.borderCol
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Сброс"
                                        color: root.cfg.textMuted
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.cfg.resetBarModules()
                                    }
                                }
                            }

                            // Карточка пресетов
                            Rectangle {
                                Layout.fillWidth: true
                                height: 42
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8

                                    Text { text: "Пресеты:"; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }

                                    Rectangle {
                                        height: 26; implicitWidth: p1Txt.implicitWidth + 16; radius: 13
                                        color: root.cfg.bgSurface; border.color: root.cfg.borderCol; border.width: 1
                                        Text { id: p1Txt; anchors.centerIn: parent; text: "󰘖 Островки"; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.cfg.barStyle = "bubbles"
                                                root.cfg.barModuleBubbles = true
                                                root.cfg.barModulesLeft = ["workspaces", "ram"]
                                                root.cfg.barModulesCenter = ["clock"]
                                                root.cfg.barModulesRight = ["tray", "vol", "lang"]
                                                root.cfg.save()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        height: 26; implicitWidth: pGrTxt.implicitWidth + 16; radius: 13
                                        color: root.cfg.bgSurface; border.color: root.cfg.accent; border.width: 1
                                        Text { id: pGrTxt; anchors.centerIn: parent; text: "󰘖 Островки (Группы)"; color: root.cfg.accent; font.pixelSize: 10; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.cfg.barStyle = "bubbles"
                                                root.cfg.barModuleBubbles = true
                                                root.cfg.barModulesLeft = ["launcher", "workspaces"]
                                                root.cfg.barModulesCenter = ["clock+weather"]
                                                root.cfg.barModulesRight = ["cpu+ram+gpu", "net+bt+vol", "tray"]
                                                root.cfg.save()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        height: 26; implicitWidth: p2Txt.implicitWidth + 16; radius: 13
                                        color: root.cfg.bgSurface; border.color: root.cfg.borderCol; border.width: 1
                                        Text { id: p2Txt; anchors.centerIn: parent; text: "󰛲 Монолит"; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.cfg.barStyle = "monolith"
                                                root.cfg.barOpacity = 0.95
                                                root.cfg.barModuleBubbles = false
                                                root.cfg.barModulesLeft = ["launcher", "workspaces"]
                                                root.cfg.barModulesCenter = ["clock", "weather"]
                                                root.cfg.barModulesRight = ["cpu", "ram", "gpu", "net", "bt", "lang", "vol", "tray"]
                                                root.cfg.save()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        height: 26; implicitWidth: p3Txt.implicitWidth + 16; radius: 13
                                        color: root.cfg.bgSurface; border.color: root.cfg.borderCol; border.width: 1
                                        Text { id: p3Txt; anchors.centerIn: parent; text: "󰀻 Полный"; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.cfg.barModulesLeft = ["launcher", "workspaces", "ram", "weather"]
                                                root.cfg.barModulesCenter = ["clock"]
                                                root.cfg.barModulesRight = ["cpu", "gpu", "net", "bt", "lang", "vol", "tray"]
                                                root.cfg.save()
                                            }
                                        }
                                    }
                                }
                            }

                            // 3 зоны бара (Лево, Центр, Право)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Левая зона
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignTop
                                    radius: 12
                                    color: root.cfg.bgElevated
                                    border.color: root.cfg.borderCol
                                    border.width: 1
                                    implicitHeight: leftZoneCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: leftZoneCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 8
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Левая зона"; color: root.cfg.textPrimary; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }
                                            Text { text: root.cfg.barModulesLeft.length + ""; color: root.cfg.accent; font.pixelSize: 10; font.bold: true }
                                        }

                                        Repeater {
                                            model: root.cfg.barModulesLeft
                                            delegate: Rectangle {
                                                required property var modelData
                                                required property int index
                                                Layout.fillWidth: true
                                                height: 40
                                                radius: 8
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                readonly property var modInfo: barTabCol.getBarMod(modelData)

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 4

                                                    Text { text: modInfo.icon; color: root.cfg.accent; font.pixelSize: 12 }
                                                    Text { text: modInfo.name; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }

                                                    Rectangle {
                                                        visible: !!modInfo.isGroup
                                                        width: 20; height: 18; radius: 4
                                                        color: spltL.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "✂"; color: spltL.containsMouse ? root.cfg.accentText : root.cfg.accent; font.pixelSize: 9 }
                                                        MouseArea { id: spltL; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.splitBarModule("left", index) }
                                                    }

                                                    Rectangle {
                                                        visible: index < root.cfg.barModulesLeft.length - 1
                                                        width: 20; height: 18; radius: 4
                                                        color: combL.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "🔗"; color: combL.containsMouse ? root.cfg.accentText : root.cfg.accent; font.pixelSize: 9 }
                                                        MouseArea { id: combL; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.combineBarModules("left", index) }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 4; color: root.cfg.bgElevated
                                                        opacity: index > 0 ? 1 : 0.3
                                                        Text { anchors.centerIn: parent; text: "◀"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                        MouseArea { anchors.fill: parent; onClicked: { if (index > 0) root.cfg.reorderBarModule("left", index, -1) } }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 4; color: root.cfg.bgElevated
                                                        opacity: index < root.cfg.barModulesLeft.length - 1 ? 1 : 0.3
                                                        Text { anchors.centerIn: parent; text: "▶"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                        MouseArea { anchors.fill: parent; onClicked: { if (index < root.cfg.barModulesLeft.length - 1) root.cfg.reorderBarModule("left", index, 1) } }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 9
                                                        color: delL.containsMouse ? root.cfg.danger : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "✕"; color: delL.containsMouse ? "#ffffff" : root.cfg.textMuted; font.pixelSize: 8 }
                                                        MouseArea { id: delL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.removeBarModule(modelData) }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Центральная зона
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignTop
                                    radius: 12
                                    color: root.cfg.bgElevated
                                    border.color: root.cfg.borderCol
                                    border.width: 1
                                    implicitHeight: centerZoneCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: centerZoneCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 8
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Центр"; color: root.cfg.textPrimary; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }
                                            Text { text: root.cfg.barModulesCenter.length + ""; color: root.cfg.accent; font.pixelSize: 10; font.bold: true }
                                        }

                                        Repeater {
                                            model: root.cfg.barModulesCenter
                                            delegate: Rectangle {
                                                required property var modelData
                                                required property int index
                                                Layout.fillWidth: true
                                                height: 40
                                                radius: 8
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                readonly property var modInfo: barTabCol.getBarMod(modelData)

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 4

                                                    Text { text: modInfo.icon; color: root.cfg.accent; font.pixelSize: 12 }
                                                    Text { text: modInfo.name; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }

                                                    Rectangle {
                                                        visible: !!modInfo.isGroup
                                                        width: 20; height: 18; radius: 4
                                                        color: spltC.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "✂"; color: spltC.containsMouse ? root.cfg.accentText : root.cfg.accent; font.pixelSize: 9 }
                                                        MouseArea { id: spltC; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.splitBarModule("center", index) }
                                                    }

                                                    Rectangle {
                                                        visible: index < root.cfg.barModulesCenter.length - 1
                                                        width: 20; height: 18; radius: 4
                                                        color: combC.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "🔗"; color: combC.containsMouse ? root.cfg.accentText : root.cfg.accent; font.pixelSize: 9 }
                                                        MouseArea { id: combC; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.combineBarModules("center", index) }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 4; color: root.cfg.bgElevated
                                                        opacity: index > 0 ? 1 : 0.3
                                                        Text { anchors.centerIn: parent; text: "◀"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                        MouseArea { anchors.fill: parent; onClicked: { if (index > 0) root.cfg.reorderBarModule("center", index, -1) } }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 4; color: root.cfg.bgElevated
                                                        opacity: index < root.cfg.barModulesCenter.length - 1 ? 1 : 0.3
                                                        Text { anchors.centerIn: parent; text: "▶"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                        MouseArea { anchors.fill: parent; onClicked: { if (index < root.cfg.barModulesCenter.length - 1) root.cfg.reorderBarModule("center", index, 1) } }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 9
                                                        color: delC.containsMouse ? root.cfg.danger : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "✕"; color: delC.containsMouse ? "#ffffff" : root.cfg.textMuted; font.pixelSize: 8 }
                                                        MouseArea { id: delC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.removeBarModule(modelData) }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Правая зона
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignTop
                                    radius: 12
                                    color: root.cfg.bgElevated
                                    border.color: root.cfg.borderCol
                                    border.width: 1
                                    implicitHeight: rightZoneCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: rightZoneCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 8
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Правая зона"; color: root.cfg.textPrimary; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }
                                            Text { text: root.cfg.barModulesRight.length + ""; color: root.cfg.accent; font.pixelSize: 10; font.bold: true }
                                        }

                                        Repeater {
                                            model: root.cfg.barModulesRight
                                            delegate: Rectangle {
                                                required property var modelData
                                                required property int index
                                                Layout.fillWidth: true
                                                height: 40
                                                radius: 8
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                readonly property var modInfo: barTabCol.getBarMod(modelData)

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 4

                                                    Text { text: modInfo.icon; color: root.cfg.accent; font.pixelSize: 12 }
                                                    Text { text: modInfo.name; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }

                                                    Rectangle {
                                                        visible: !!modInfo.isGroup
                                                        width: 20; height: 18; radius: 4
                                                        color: spltR.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "✂"; color: spltR.containsMouse ? root.cfg.accentText : root.cfg.accent; font.pixelSize: 9 }
                                                        MouseArea { id: spltR; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.splitBarModule("right", index) }
                                                    }

                                                    Rectangle {
                                                        visible: index < root.cfg.barModulesRight.length - 1
                                                        width: 20; height: 18; radius: 4
                                                        color: combR.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "🔗"; color: combR.containsMouse ? root.cfg.accentText : root.cfg.accent; font.pixelSize: 9 }
                                                        MouseArea { id: combR; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.combineBarModules("right", index) }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 4; color: root.cfg.bgElevated
                                                        opacity: index > 0 ? 1 : 0.3
                                                        Text { anchors.centerIn: parent; text: "◀"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                        MouseArea { anchors.fill: parent; onClicked: { if (index > 0) root.cfg.reorderBarModule("right", index, -1) } }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 4; color: root.cfg.bgElevated
                                                        opacity: index < root.cfg.barModulesRight.length - 1 ? 1 : 0.3
                                                        Text { anchors.centerIn: parent; text: "▶"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                        MouseArea { anchors.fill: parent; onClicked: { if (index < root.cfg.barModulesRight.length - 1) root.cfg.reorderBarModule("right", index, 1) } }
                                                    }

                                                    Rectangle {
                                                        width: 18; height: 18; radius: 9
                                                        color: delR.containsMouse ? root.cfg.danger : root.cfg.bgElevated
                                                        Text { anchors.centerIn: parent; text: "✕"; color: delR.containsMouse ? "#ffffff" : root.cfg.textMuted; font.pixelSize: 8 }
                                                        MouseArea { id: delR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.removeBarModule(modelData) }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Доступные модули
                            Rectangle {
                                Layout.fillWidth: true
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                visible: barTabCol.getUnusedBarMods().length > 0
                                implicitHeight: warehouseCol.implicitHeight + 20

                                ColumnLayout {
                                    id: warehouseCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Text { text: "Добавить модуль:"; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: barTabCol.getUnusedBarMods()
                                            delegate: Rectangle {
                                                required property var modelData
                                                height: 28
                                                implicitWidth: chipRow.implicitWidth + 16
                                                radius: 14
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                RowLayout {
                                                    id: chipRow
                                                    anchors.centerIn: parent
                                                    spacing: 6

                                                    Text { text: modelData.icon; color: root.cfg.accent; font.pixelSize: 11 }
                                                    Text { text: modelData.name; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true }

                                                    Rectangle {
                                                        height: 18; implicitWidth: addLTxt.implicitWidth + 6; radius: 4
                                                        color: addLM.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { id: addLTxt; anchors.centerIn: parent; text: "+ Л"; color: addLM.containsMouse ? root.cfg.accentText : root.cfg.textMuted; font.pixelSize: 8; font.bold: true }
                                                        MouseArea { id: addLM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.moveBarModule(modelData.id, "left") }
                                                    }

                                                    Rectangle {
                                                        height: 18; implicitWidth: addCTxt.implicitWidth + 6; radius: 4
                                                        color: addCM.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { id: addCTxt; anchors.centerIn: parent; text: "+ Ц"; color: addCM.containsMouse ? root.cfg.accentText : root.cfg.textMuted; font.pixelSize: 8; font.bold: true }
                                                        MouseArea { id: addCM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.moveBarModule(modelData.id, "center") }
                                                    }

                                                    Rectangle {
                                                        height: 18; implicitWidth: addRTxt.implicitWidth + 6; radius: 4
                                                        color: addRM.containsMouse ? root.cfg.accent : root.cfg.bgElevated
                                                        Text { id: addRTxt; anchors.centerIn: parent; text: "+ П"; color: addRM.containsMouse ? root.cfg.accentText : root.cfg.textMuted; font.pixelSize: 8; font.bold: true }
                                                        MouseArea { id: addRM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cfg.moveBarModule(modelData.id, "right") }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Параметры геометрии и стиля
                            Rectangle {
                                Layout.fillWidth: true
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: barCustomCol.implicitHeight + 20

                                ColumnLayout {
                                    id: barCustomCol
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10

                                    Text { text: "Параметры панели:"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }

                                    // Положение панели
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "top", name: "Сверху" },
                                                { id: "bottom", name: "Снизу" },
                                                { id: "left", name: "Слева" },
                                                { id: "right", name: "Справа" }
                                            ]
                                            Rectangle {
                                                required property var modelData
                                                Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 8
                                                color: root.cfg.barPosition === modelData.id ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.name
                                                    color: root.cfg.barPosition === modelData.id ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 11; font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { root.cfg.barPosition = modelData.id; root.cfg.save() }
                                                }
                                            }
                                        }
                                    }

                                    // Капсульный фон для модулей
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Капсульный фон модулей"; color: root.cfg.textPrimary; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }

                                        Rectangle {
                                            width: 42; height: 24; radius: 12
                                            color: root.cfg.barModuleBubbles ? root.cfg.accent : root.cfg.bgSurface
                                            border.color: root.cfg.borderCol; border.width: 1

                                            Rectangle {
                                                width: 18; height: 18; radius: 9
                                                anchors.verticalCenter: parent.verticalCenter
                                                x: root.cfg.barModuleBubbles ? 21 : 3
                                                color: root.cfg.barModuleBubbles ? root.cfg.accentText : root.cfg.textMuted
                                                Behavior on x { NumberAnimation { duration: 140 } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: { root.cfg.barModuleBubbles = !root.cfg.barModuleBubbles; root.cfg.save() }
                                            }
                                        }
                                    }

                                    // Слайдер длины / ширины бара
                                    ColumnLayout {
                                        id: barWidthCol
                                        readonly property bool isVert: root.cfg.barPosition === "left" || root.cfg.barPosition === "right"
                                        Layout.fillWidth: true; spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: barWidthCol.isVert ? "Длина панели (по вертикали)" : "Длина / ширина панели"
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 11
                                                font.bold: true
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                width: 20; height: 20; radius: 10
                                                color: bwMinusM.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Text { anchors.centerIn: parent; text: "−"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                                                MouseArea {
                                                    id: bwMinusM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (barWidthCol.isVert) root.cfg.barVerticalHeight = Math.max(360, root.cfg.barVerticalHeight - 20)
                                                        else root.cfg.barWidth = Math.max(600, root.cfg.barWidth - 20)
                                                        root.cfg.save()
                                                    }
                                                }
                                            }

                                            Text {
                                                text: (barWidthCol.isVert ? root.cfg.barVerticalHeight : root.cfg.barWidth) + " px"
                                                color: root.cfg.accent
                                                font.pixelSize: 11
                                                font.bold: true
                                            }

                                            Rectangle {
                                                width: 20; height: 20; radius: 10
                                                color: bwPlusM.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Text { anchors.centerIn: parent; text: "+"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                                                MouseArea {
                                                    id: bwPlusM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (barWidthCol.isVert) root.cfg.barVerticalHeight = Math.min(1080, root.cfg.barVerticalHeight + 20)
                                                        else root.cfg.barWidth = Math.min(1920, root.cfg.barWidth + 20)
                                                        root.cfg.save()
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.cfg.bgSurface
                                            Rectangle {
                                                width: {
                                                    if (barWidthCol.isVert) return parent.width * Math.max(0, Math.min(1, (root.cfg.barVerticalHeight - 360) / (1080 - 360)))
                                                    else return parent.width * Math.max(0, Math.min(1, (root.cfg.barWidth - 600) / (1920 - 600)))
                                                }
                                                height: parent.height; radius: 3; color: root.cfg.accent
                                            }
                                            MouseArea {
                                                anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                                function update(mx) {
                                                    let ratio = Math.max(0, Math.min(1, mx / width))
                                                    if (barWidthCol.isVert) root.cfg.barVerticalHeight = Math.round((360 + ratio * 720) / 10) * 10
                                                    else root.cfg.barWidth = Math.round((600 + ratio * 1320) / 10) * 10
                                                    root.cfg.save()
                                                }
                                                onPressed: m => update(m.x)
                                                onPositionChanged: m => { if (pressed) update(m.x) }
                                            }
                                        }

                                        // Быстрые пресеты длины
                                        RowLayout {
                                            spacing: 6
                                            Repeater {
                                                model: barWidthCol.isVert
                                                       ? [{ label: "480 px", val: 480 }, { label: "680 px", val: 680 }, { label: "880 px", val: 880 }, { label: "1080 px", val: 1080 }]
                                                       : [{ label: "1200 px", val: 1200 }, { label: "1400 px", val: 1400 }, { label: "1650 px", val: 1650 }, { label: "1900 px", val: 1900 }]
                                                Rectangle {
                                                    required property var modelData
                                                    height: 22
                                                    implicitWidth: pLtxt.implicitWidth + 12
                                                    radius: 11
                                                    readonly property bool isCur: (barWidthCol.isVert ? root.cfg.barVerticalHeight : root.cfg.barWidth) === modelData.val
                                                    color: isCur ? root.cfg.accent : (pLM.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface)
                                                    border.color: isCur ? root.cfg.accent : root.cfg.borderCol
                                                    border.width: 1
                                                    Text {
                                                         id: pLtxt; anchors.centerIn: parent
                                                         text: modelData.label
                                                         color: isCur ? root.cfg.accentText : root.cfg.textPrimary
                                                         font.pixelSize: 9; font.bold: true
                                                    }
                                                    MouseArea {
                                                         id: pLM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                         onClicked: {
                                                             if (barWidthCol.isVert) root.cfg.barVerticalHeight = modelData.val
                                                             else root.cfg.barWidth = modelData.val
                                                             root.cfg.save()
                                                         }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Слайдер скругления подложки модулей / капсул
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Скругление модулей / капсул"; color: root.cfg.textPrimary; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }

                                            Rectangle {
                                                width: 20; height: 20; radius: 10
                                                color: mrMinusM.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Text { anchors.centerIn: parent; text: "−"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                                                MouseArea {
                                                    id: mrMinusM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        let cur = root.cfg.barModuleRadius !== undefined ? root.cfg.barModuleRadius : 16
                                                        root.cfg.barModuleRadius = Math.max(0, cur - 1)
                                                        root.cfg.save()
                                                    }
                                                }
                                            }

                                            Text {
                                                text: {
                                                    let r = root.cfg.barModuleRadius !== undefined ? root.cfg.barModuleRadius : 16
                                                    if (r >= 20 || r < 0) return "Капсула (авто)"
                                                    return r + " px"
                                                }
                                                color: root.cfg.accent; font.pixelSize: 11; font.bold: true
                                            }

                                            Rectangle {
                                                width: 20; height: 20; radius: 10
                                                color: mrPlusM.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Text { anchors.centerIn: parent; text: "+"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                                                MouseArea {
                                                    id: mrPlusM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        let cur = root.cfg.barModuleRadius !== undefined ? root.cfg.barModuleRadius : 16
                                                        root.cfg.barModuleRadius = Math.min(20, cur + 1)
                                                        root.cfg.save()
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.cfg.bgSurface
                                            Rectangle {
                                                width: parent.width * Math.max(0, Math.min(1, ((root.cfg.barModuleRadius !== undefined ? root.cfg.barModuleRadius : 16) / 20)))
                                                height: parent.height; radius: 3; color: root.cfg.accent
                                            }
                                            MouseArea {
                                                anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                                function update(mx) {
                                                    let ratio = Math.max(0, Math.min(1, mx / width))
                                                    root.cfg.barModuleRadius = Math.round(ratio * 20)
                                                    root.cfg.save()
                                                }
                                                onPressed: m => update(m.x)
                                                onPositionChanged: m => { if (pressed) update(m.x) }
                                            }
                                        }

                                        // Пресеты скругления капсул модулей
                                        RowLayout {
                                            spacing: 6
                                            Repeater {
                                                model: [
                                                    { label: "0 px", val: 0 },
                                                    { label: "6 px", val: 6 },
                                                    { label: "12 px", val: 12 },
                                                    { label: "Капсула (авто)", val: 20 }
                                                ]
                                                Rectangle {
                                                    required property var modelData
                                                    height: 22
                                                    implicitWidth: pMRtxt.implicitWidth + 12
                                                    radius: 11
                                                    readonly property bool isCur: (root.cfg.barModuleRadius !== undefined ? root.cfg.barModuleRadius : 16) === modelData.val
                                                    color: isCur ? root.cfg.accent : (pMRm.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface)
                                                    border.color: isCur ? root.cfg.accent : root.cfg.borderCol
                                                    border.width: 1
                                                    Text {
                                                         id: pMRtxt; anchors.centerIn: parent
                                                         text: modelData.label
                                                         color: isCur ? root.cfg.accentText : root.cfg.textPrimary
                                                         font.pixelSize: 9; font.bold: true
                                                    }
                                                    MouseArea {
                                                         id: pMRm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                         onClicked: {
                                                             root.cfg.barModuleRadius = modelData.val
                                                             root.cfg.save()
                                                         }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Слайдер высоты бара
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Высота панели"; color: root.cfg.textMuted; font.pixelSize: 11; Layout.fillWidth: true }
                                            Text { text: root.cfg.barHeight + " px"; color: root.cfg.accent; font.pixelSize: 11; font.bold: true }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.cfg.bgSurface
                                            Rectangle {
                                                width: parent.width * Math.max(0, Math.min(1, (root.cfg.barHeight - 24) / (56 - 24)))
                                                height: parent.height; radius: 3; color: root.cfg.accent
                                            }
                                            MouseArea {
                                                anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                                function update(mx) {
                                                    let ratio = Math.max(0, Math.min(1, mx / width))
                                                    root.cfg.barHeight = Math.round(24 + ratio * 32)
                                                    root.cfg.save()
                                                }
                                                onPressed: m => update(m.x)
                                                onPositionChanged: m => { if (pressed) update(m.x) }
                                            }
                                        }
                                    }

                                    // Слайдер скругления углов панели бара
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Скругление углов панели бара"; color: root.cfg.textPrimary; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }

                                            Rectangle {
                                                width: 20; height: 20; radius: 10
                                                color: brMinusM.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Text { anchors.centerIn: parent; text: "−"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                                                MouseArea {
                                                    id: brMinusM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.cfg.barRadius = Math.max(0, root.cfg.barRadius - 1)
                                                        root.cfg.save()
                                                    }
                                                }
                                            }

                                            Text { text: root.cfg.barRadius + " px"; color: root.cfg.accent; font.pixelSize: 11; font.bold: true }

                                            Rectangle {
                                                width: 20; height: 20; radius: 10
                                                color: brPlusM.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Text { anchors.centerIn: parent; text: "+"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                                                MouseArea {
                                                    id: brPlusM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.cfg.barRadius = Math.min(28, root.cfg.barRadius + 1)
                                                        root.cfg.save()
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.cfg.bgSurface
                                            Rectangle {
                                                width: parent.width * Math.max(0, Math.min(1, root.cfg.barRadius / 28))
                                                height: parent.height; radius: 3; color: root.cfg.accent
                                            }
                                            MouseArea {
                                                anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                                function update(mx) {
                                                    let ratio = Math.max(0, Math.min(1, mx / width))
                                                    root.cfg.barRadius = Math.round(ratio * 28)
                                                    root.cfg.save()
                                                }
                                                onPressed: m => update(m.x)
                                                onPositionChanged: m => { if (pressed) update(m.x) }
                                            }
                                        }

                                        // Пресеты скругления бара
                                        RowLayout {
                                            spacing: 6
                                            Repeater {
                                                model: [
                                                    { label: "0 px", val: 0 },
                                                    { label: "10 px", val: 10 },
                                                    { label: "17 px", val: 17 },
                                                    { label: "28 px", val: 28 }
                                                ]
                                                Rectangle {
                                                    required property var modelData
                                                    height: 22
                                                    implicitWidth: pBRtxt.implicitWidth + 12
                                                    radius: 11
                                                    readonly property bool isCur: root.cfg.barRadius === modelData.val
                                                    color: isCur ? root.cfg.accent : (pBRm.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface)
                                                    border.color: isCur ? root.cfg.accent : root.cfg.borderCol
                                                    border.width: 1
                                                    Text {
                                                        id: pBRtxt; anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: isCur ? root.cfg.accentText : root.cfg.textPrimary
                                                        font.pixelSize: 9; font.bold: true
                                                    }
                                                    MouseArea {
                                                        id: pBRm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                             root.cfg.barRadius = modelData.val
                                                             root.cfg.save()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Слайдер прозрачности
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Прозрачность подложки"; color: root.cfg.textMuted; font.pixelSize: 11; Layout.fillWidth: true }
                                            Text { text: Math.round(root.cfg.barOpacity * 100) + " %"; color: root.cfg.accent; font.pixelSize: 11; font.bold: true }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.cfg.bgSurface
                                            Rectangle {
                                                width: parent.width * Math.max(0, Math.min(1, root.cfg.barOpacity))
                                                height: parent.height; radius: 3; color: root.cfg.accent
                                            }
                                            MouseArea {
                                                anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                                function update(mx) {
                                                    root.cfg.barOpacity = Math.max(0.0, Math.min(1.0, mx / width))
                                                    root.cfg.save()
                                                }
                                                onPressed: m => update(m.x)
                                                onPositionChanged: m => { if (pressed) update(m.x) }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // ================= ВКЛАДКА 2: ДОК-БАР =================
                        ColumnLayout {
                            id: dockTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 14
                            visible: root.tab === "dock"

                            Text {
                                text: "Параметры дока"
                                color: root.cfg.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                font.family: root.cfg.fontFamily
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 14
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: dockSettingsCol.implicitHeight

                                ColumnLayout {
                                    id: dockSettingsCol
                                    anchors.fill: parent
                                    spacing: 0

                                    // Включить док-бар
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "󰀻"; color: root.cfg.accent; font.pixelSize: 15 }
                                            Text {
                                                text: "Отображать док-бар"
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: root.cfg.fontFamily
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                width: 42; height: 24; radius: 12
                                                color: root.cfg.dockEnabled ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Rectangle {
                                                    width: 18; height: 18; radius: 9
                                                    color: root.cfg.dockEnabled ? root.cfg.accentText : root.cfg.textMuted
                                                    x: root.cfg.dockEnabled ? 21 : 3
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    Behavior on x { NumberAnimation { duration: 140 } }
                                                }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { root.cfg.dockEnabled = !root.cfg.dockEnabled; root.cfg.save() }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol; Layout.leftMargin: 14; Layout.rightMargin: 14 }

                                    // Автоскрытие
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "󰍜"; color: root.cfg.textMuted; font.pixelSize: 15 }
                                            Text {
                                                text: "Автоскрытие"
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: root.cfg.fontFamily
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                width: 42; height: 24; radius: 12
                                                color: root.cfg.dockAutohide ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Rectangle {
                                                    width: 18; height: 18; radius: 9
                                                    color: root.cfg.dockAutohide ? root.cfg.accentText : root.cfg.textMuted
                                                    x: root.cfg.dockAutohide ? 21 : 3
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    Behavior on x { NumberAnimation { duration: 140 } }
                                                }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { root.cfg.dockAutohide = !root.cfg.dockAutohide; root.cfg.save() }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol; Layout.leftMargin: 14; Layout.rightMargin: 14 }

                                    // Размер иконок
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "󰏘"; color: root.cfg.textMuted; font.pixelSize: 15 }
                                            Text {
                                                text: "Размер иконок"
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: root.cfg.fontFamily
                                                Layout.fillWidth: true
                                            }

                                            RowLayout {
                                                spacing: 4
                                                Repeater {
                                                    model: [
                                                        { label: "36 px", size: 36 },
                                                        { label: "42 px", size: 42 },
                                                        { label: "48 px", size: 48 }
                                                    ]
                                                    Rectangle {
                                                        required property var modelData
                                                        height: 28
                                                        implicitWidth: szTxt.implicitWidth + 16
                                                        radius: 14
                                                        color: (root.cfg.dockIconSize === modelData.size) ? root.cfg.accent : root.cfg.bgSurface
                                                        border.color: root.cfg.borderCol
                                                        border.width: 1

                                                        Text {
                                                            id: szTxt
                                                            anchors.centerIn: parent
                                                            text: modelData.label
                                                            color: (root.cfg.dockIconSize === modelData.size) ? root.cfg.accentText : root.cfg.textPrimary
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                            onClicked: { root.cfg.dockIconSize = modelData.size; root.cfg.save() }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Закрепленные приложения"
                                color: root.cfg.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                font.family: root.cfg.fontFamily
                                Layout.topMargin: 4
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 14
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: pinnedCardCol.implicitHeight + 24

                                ColumnLayout {
                                    id: pinnedCardCol
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10

                                    // Список закрепленных приложений
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: root.cfg.dockPinnedApps || []

                                            Rectangle {
                                                required property string modelData
                                                height: 30
                                                implicitWidth: chipRow.implicitWidth + 14
                                                radius: 15
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                RowLayout {
                                                    id: chipRow
                                                    anchors.centerIn: parent
                                                    spacing: 6

                                                    Text { text: "󰀻"; color: root.cfg.accent; font.pixelSize: 12 }
                                                    Text {
                                                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                                        color: root.cfg.textPrimary
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                    }

                                                    Rectangle {
                                                        width: 16; height: 16; radius: 8
                                                        color: delChipM.containsMouse ? root.cfg.danger : Qt.rgba(255, 255, 255, 0.08)

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "✕"
                                                            color: delChipM.containsMouse ? "#ffffff" : root.cfg.textMuted
                                                            font.pixelSize: 8
                                                        }

                                                        MouseArea {
                                                            id: delChipM
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.cfg.unpinAppFromDock(modelData)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol }

                                    Text { text: "Быстро добавить:"; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                { id: "firefox", name: "+ Firefox" },
                                                { id: "kitty", name: "+ Kitty" },
                                                { id: "alacritty", name: "+ Alacritty" },
                                                { id: "thunar", name: "+ Файлы" },
                                                { id: "vesktop", name: "+ Discord" },
                                                { id: "telegram", name: "+ Telegram" },
                                                { id: "steam", name: "+ Steam" }
                                            ]

                                            Rectangle {
                                                required property var modelData
                                                readonly property bool alreadyPinned: root.cfg.isAppPinned(modelData.id)
                                                visible: !alreadyPinned
                                                height: 26
                                                implicitWidth: addAppTxt.implicitWidth + 14
                                                radius: 13
                                                color: addAppM.containsMouse ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                Text {
                                                    id: addAppTxt
                                                    anchors.centerIn: parent
                                                    text: modelData.name
                                                    color: addAppM.containsMouse ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: addAppM
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.cfg.pinAppToDock(modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // ================= ВКЛАДКА 3: ВИДЖЕТЫ СТОЛА =================
                        ColumnLayout {
                            id: widgetsTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 12
                            visible: root.tab === "widgets"

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Виджеты рабочего стола"
                                    color: root.cfg.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: root.cfg.fontFamily
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    height: 30
                                    implicitWidth: openWEdTxt.implicitWidth + 24
                                    radius: 15
                                    color: root.cfg.accent

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "󰆣"; color: root.cfg.accentText; font.pixelSize: 12 }
                                        Text {
                                            id: openWEdTxt
                                            text: "Расставить на экране"
                                            color: root.cfg.accentText
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.closeRequested()
                                            root.requestWidgetEditor("widgets")
                                        }
                                    }
                                }
                            }

                            // Отображать виджеты
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 14

                                    Text { text: "Отображать виджеты на рабочем столе"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }

                                    Rectangle {
                                        width: 42; height: 24; radius: 12
                                        color: root.cfg.showDesktopWidgets ? root.cfg.accent : root.cfg.bgSurface
                                        border.color: root.cfg.borderCol; border.width: 1
                                        Rectangle {
                                            width: 18; height: 18; radius: 9
                                            color: root.cfg.showDesktopWidgets ? root.cfg.accentText : root.cfg.textMuted
                                            x: root.cfg.showDesktopWidgets ? 21 : 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            Behavior on x { NumberAnimation { duration: 140 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { root.cfg.showDesktopWidgets = !root.cfg.showDesktopWidgets; root.cfg.save() }
                                        }
                                    }
                                }
                            }

                            // Общее скругление виджетов
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 14

                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true
                                        Text { text: "Скругление углов по умолчанию"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                                        Text { text: "Индивидуально настраивается в предпросмотре у каждого виджета"; color: root.cfg.textMuted; font.pixelSize: 10 }
                                    }

                                    RowLayout {
                                        spacing: 4
                                        Repeater {
                                            model: [
                                                { label: "0", val: 0 },
                                                { label: "12", val: 12 },
                                                { label: "20", val: 20 },
                                                { label: "28", val: 28 },
                                                { label: "36", val: 36 }
                                            ]

                                            Rectangle {
                                                required property var modelData
                                                width: 30
                                                height: 26
                                                radius: 13
                                                readonly property bool isCur: (root.cfg.widgetRadius || 28) === modelData.val
                                                color: isCur ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: isCur ? root.cfg.accent : root.cfg.borderCol
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: isCur ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.cfg.setAllWidgetsRadius(modelData.val)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Добавить виджет
                            Rectangle {
                                Layout.fillWidth: true
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: addWCol.implicitHeight + 20

                                ColumnLayout {
                                    id: addWCol
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text { text: "Добавить виджет:"; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                { type: "clock", label: "󰥔 Часы" },
                                                { type: "weather", label: "󰖐 Погода" },
                                                { type: "vitals", label: "󰍛 Ресурсы" },
                                                { type: "player", label: "󰎆 Плеер" },
                                                { type: "calendar", label: "󰸗 Календарь" },
                                                { type: "notes", label: "󰏫 Заметки" },
                                                { type: "storage", label: "󰋊 Диск" }
                                            ]

                                            Rectangle {
                                                height: 30
                                                implicitWidth: qAddTxt.implicitWidth + 20
                                                radius: 15
                                                color: qAddM.containsMouse ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                Text {
                                                    id: qAddTxt
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: qAddM.containsMouse ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: qAddM
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.cfg.addWidget(modelData.type, 140, 140)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Список активных виджетов
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Активные виджеты (" + root.cfg.desktopWidgets.length + "):"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
                                Rectangle {
                                    height: 24; implicitWidth: 80; radius: 12
                                    color: root.cfg.bgElevated
                                    border.color: root.cfg.borderCol
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: "Сброс"; color: root.cfg.textMuted; font.pixelSize: 10; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.cfg.desktopWidgets = [
                                                { id: "clock-1", type: "clock", x: 60, y: 70, w: 260, h: 140, visible: true },
                                                { id: "weather-1", type: "weather", x: 340, y: 70, w: 220, h: 140, visible: true },
                                                { id: "vitals-1", type: "vitals", x: 60, y: 230, w: 320, h: 120, visible: true },
                                                { id: "player-1", type: "player", x: 400, y: 230, w: 360, h: 140, visible: true }
                                            ]
                                            root.cfg.save()
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: root.cfg.desktopWidgets
                                    delegate: Rectangle {
                                        id: wCardItem
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: wCardCol.implicitHeight + 16
                                        radius: 12
                                        color: root.cfg.bgElevated
                                        border.color: root.cfg.borderCol
                                        border.width: 1

                                        ColumnLayout {
                                            id: wCardCol
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 10
                                            spacing: 6

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    text: {
                                                        let t = wCardItem.modelData.type
                                                        if (t === "clock") return "󰥔"
                                                        if (t === "weather") return "󰖐"
                                                        if (t === "vitals") return "󰍛"
                                                        if (t === "player") return "󰎆"
                                                        if (t === "calendar") return "󰸗"
                                                        if (t === "notes") return "󰏫"
                                                        if (t === "storage") return "󰋊"
                                                        return "󰕰"
                                                    }
                                                    color: root.cfg.accent
                                                    font.pixelSize: 14
                                                }

                                                Text {
                                                    text: {
                                                        let t = wCardItem.modelData.type
                                                        if (t === "clock") return "Часы и дата"
                                                        if (t === "weather") return "Погода"
                                                        if (t === "vitals") return "Ресурсы"
                                                        if (t === "player") return "Медиаплеер"
                                                        if (t === "calendar") return "Календарь"
                                                        if (t === "notes") return "Заметки"
                                                        if (t === "storage") return "Диск"
                                                        return t
                                                    }
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                }

                                                // Кнопка смены вида
                                                Rectangle {
                                                    height: 24
                                                    implicitWidth: varBtnTxt.implicitWidth + 14
                                                    radius: 12
                                                    color: root.cfg.bgSurface
                                                    border.color: root.cfg.borderCol
                                                    border.width: 1

                                                    Text {
                                                        id: varBtnTxt
                                                        anchors.centerIn: parent
                                                        text: "Вид: " + (wCardItem.modelData.variant || "стандарт")
                                                        color: root.cfg.accent
                                                        font.pixelSize: 9
                                                        font.bold: true
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.cfg.cycleWidgetVariant(wCardItem.modelData.id)
                                                    }
                                                }

                                                // Кнопка удаления
                                                Rectangle {
                                                    width: 24; height: 24; radius: 12
                                                    color: delBtnM.containsMouse ? root.cfg.danger : root.cfg.bgSurface
                                                    border.color: root.cfg.borderCol
                                                    border.width: 1
                                                    Text { anchors.centerIn: parent; text: "✕"; color: delBtnM.containsMouse ? "#ffffff" : root.cfg.textMuted; font.pixelSize: 9 }
                                                    MouseArea {
                                                        id: delBtnM
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.cfg.removeWidget(wCardItem.modelData.id)
                                                    }
                                                }
                                            }

                                            // Выбор цвета для часов
                                            RowLayout {
                                                visible: wCardItem.modelData.type === "clock"
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text { text: "Цвет:"; color: root.cfg.textMuted; font.pixelSize: 10 }

                                                Repeater {
                                                    model: ["theme", "#ffffff", "#a8c7fa", "#d0bcff", "#a6e3a1", "#ffb4a2", "#fabd2f", "#f38ba8"]
                                                    Rectangle {
                                                        required property string modelData
                                                        width: 18; height: 18; radius: 9
                                                        color: modelData === "theme" ? root.cfg.accent : modelData
                                                        border.color: (wCardItem.modelData.clockColor || "theme") === modelData ? "#ffffff" : "transparent"
                                                        border.width: 1.5

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                root.cfg.setWidgetProperty(wCardItem.modelData.id, "clockColor", modelData)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // ================= ВКЛАДКА 4: ШТОРКА УПРАВЛЕНИЯ =================
                        ColumnLayout {
                            id: sideTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 12
                            visible: root.tab === "side"

                            function getSideSec(id) {
                                if (!root.cfg || !root.cfg.allSideSections) return { id: id, name: id, icon: "󰕮" }
                                for (let i = 0; i < root.cfg.allSideSections.length; i++) {
                                    if (root.cfg.allSideSections[i].id === id) return root.cfg.allSideSections[i]
                                }
                                return { id: id, name: id, icon: "󰕮" }
                            }

                            function getUnusedSideSecs() {
                                if (!root.cfg || !root.cfg.allSideSections) return []
                                let active = root.cfg.sidePanelOrder || []
                                return root.cfg.allSideSections.filter(s => !active.includes(s.id))
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Шторка управления"
                                    color: root.cfg.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: root.cfg.fontFamily
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    height: 30
                                    implicitWidth: liveSideBtnTxt.implicitWidth + 24
                                    radius: 15
                                    color: root.cfg.accent

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "󰍹"; color: root.cfg.accentText; font.pixelSize: 12 }
                                        Text { id: liveSideBtnTxt; text: "Открыть шторку"; color: root.cfg.accentText; font.pixelSize: 11; font.bold: true }
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.closeRequested()
                                            settingsSysProc.command = ["quickshell", "ipc", "call", "shell", "toggleSide"]
                                            settingsSysProc.running = true
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 30
                                    implicitWidth: 80
                                    radius: 15
                                    color: root.cfg.bgElevated
                                    border.color: root.cfg.borderCol
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: "Сброс"; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.cfg.sidePanelOrder = ["tiles", "sliders", "gauges", "media", "notifications", "power"]
                                            root.cfg.save()
                                        }
                                    }
                                }
                            }

                            // Активные секции шторки
                            Rectangle {
                                Layout.fillWidth: true
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: actSecCol.implicitHeight + 16

                                ColumnLayout {
                                    id: actSecCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    Text { text: "Порядок секций:"; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }

                                    Repeater {
                                        model: root.cfg.sidePanelOrder
                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index
                                            Layout.fillWidth: true
                                            height: 38
                                            radius: 8
                                            color: root.cfg.bgSurface
                                            border.color: root.cfg.borderCol
                                            border.width: 1

                                            readonly property var secInfo: sideTabCol.getSideSec(modelData)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                spacing: 8

                                                Text { text: secInfo.icon; color: root.cfg.accent; font.pixelSize: 13 }
                                                Text {
                                                    text: secInfo.name
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                Rectangle {
                                                    width: 22; height: 22; radius: 4
                                                    color: root.cfg.bgElevated
                                                    opacity: index > 0 ? 1 : 0.35
                                                    Text { anchors.centerIn: parent; text: "▲"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                        onClicked: { if (index > 0) root.cfg.reorderSideSection(index, -1) }
                                                    }
                                                }

                                                Rectangle {
                                                    width: 22; height: 22; radius: 4
                                                    color: root.cfg.bgElevated
                                                    opacity: index < root.cfg.sidePanelOrder.length - 1 ? 1 : 0.35
                                                    Text { anchors.centerIn: parent; text: "▼"; color: root.cfg.textPrimary; font.pixelSize: 8 }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: index < root.cfg.sidePanelOrder.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                        onClicked: { if (index < root.cfg.sidePanelOrder.length - 1) root.cfg.reorderSideSection(index, 1) }
                                                    }
                                                }

                                                Rectangle {
                                                    width: 22; height: 22; radius: 11
                                                    color: sHideM.containsMouse ? root.cfg.danger : root.cfg.bgElevated
                                                    Text { anchors.centerIn: parent; text: "✕"; color: sHideM.containsMouse ? "#ffffff" : root.cfg.textMuted; font.pixelSize: 8 }
                                                    MouseArea {
                                                        id: sHideM
                                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.cfg.toggleSideSection(modelData)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Скрытые секции шторки
                            Rectangle {
                                Layout.fillWidth: true
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                visible: sideTabCol.getUnusedSideSecs().length > 0
                                implicitHeight: unusedSecCol.implicitHeight + 16

                                ColumnLayout {
                                    id: unusedSecCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    Text { text: "Скрытые секции:"; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: sideTabCol.getUnusedSideSecs()
                                            delegate: Rectangle {
                                                required property var modelData
                                                height: 28
                                                implicitWidth: flowSecRow.implicitWidth + 14
                                                radius: 14
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                RowLayout {
                                                    id: flowSecRow
                                                    anchors.centerIn: parent
                                                    spacing: 6

                                                    Text { text: modelData.icon; color: root.cfg.accent; font.pixelSize: 11 }
                                                    Text { text: modelData.name; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true }
                                                    Text { text: "+"; color: root.cfg.accent; font.pixelSize: 11; font.bold: true }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.cfg.toggleSideSection(modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Слайдер ширины шторки
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 3
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Ширина шторки"; color: root.cfg.textMuted; font.pixelSize: 11; Layout.fillWidth: true }
                                    Text { text: root.cfg.sidePanelWidth + " px"; color: root.cfg.accent; font.pixelSize: 11; font.bold: true }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.cfg.bgElevated
                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, (root.cfg.sidePanelWidth - 320) / (500 - 320)))
                                        height: parent.height; radius: 3; color: root.cfg.accent
                                    }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                        function update(mx) {
                                            let ratio = Math.max(0, Math.min(1, mx / width))
                                            root.cfg.sidePanelWidth = Math.round(320 + ratio * 180)
                                            root.cfg.save()
                                        }
                                        onPressed: m => update(m.x)
                                        onPositionChanged: m => { if (pressed) update(m.x) }
                                    }
                                }
                            }

                            // Форма кнопок и волна плеера
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 10
                                    color: root.cfg.activeShapeStyle === "blossom" ? root.cfg.accent : root.cfg.bgElevated
                                    border.color: root.cfg.borderCol; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰄛 Blossom (органика)"
                                        color: root.cfg.activeShapeStyle === "blossom" ? root.cfg.accentText : root.cfg.textPrimary
                                        font.pixelSize: 11; font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.cfg.activeShapeStyle = "blossom"; root.cfg.save() }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 10
                                    color: root.cfg.activeShapeStyle === "circle" ? root.cfg.accent : root.cfg.bgElevated
                                    border.color: root.cfg.borderCol; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰝥 Круг"
                                        color: root.cfg.activeShapeStyle === "circle" ? root.cfg.accentText : root.cfg.textPrimary
                                        font.pixelSize: 11; font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.cfg.activeShapeStyle = "circle"; root.cfg.save() }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true; spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 10
                                    color: root.cfg.playerProgressStyle === "wavy" ? root.cfg.accent : root.cfg.bgElevated
                                    border.color: root.cfg.borderCol; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰎆 Волна плеера"
                                        color: root.cfg.playerProgressStyle === "wavy" ? root.cfg.accentText : root.cfg.textPrimary
                                        font.pixelSize: 11; font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.cfg.playerProgressStyle = "wavy"; root.cfg.save() }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 10
                                    color: root.cfg.playerProgressStyle === "flat" ? root.cfg.accent : root.cfg.bgElevated
                                    border.color: root.cfg.borderCol; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰓛 Прямая полоса"
                                        color: root.cfg.playerProgressStyle === "flat" ? root.cfg.accentText : root.cfg.textPrimary
                                        font.pixelSize: 11; font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.cfg.playerProgressStyle = "flat"; root.cfg.save() }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // ================= ВКЛАДКА 5: ТЕМЫ =================
                        ColumnLayout {
                            id: themesTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 16
                            visible: root.tab === "themes"

                            // 1. ГОТОВЫЕ ЦВЕТОВЫЕ ТЕМЫ (24 ПАЛИТРЫ)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Готовые темы оформления"
                                        color: root.cfg.textPrimary
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: root.cfg.fontFamily
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "24 палитры"
                                        color: root.cfg.textMuted
                                        font.pixelSize: 11
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 6
                                    columnSpacing: 6

                                    Repeater {
                                        model: [
                                            { id: "Monet Blue", color: "#a8c7fa" },
                                            { id: "Pixel Lavender", color: "#d0bcff" },
                                            { id: "Emerald Mint", color: "#a6e3a1" },
                                            { id: "Graphite White", color: "#c8ccd8" },
                                            { id: "AMOLED Peach", color: "#ffb4a2" },
                                            { id: "Nordic Slate", color: "#88c0d0" },
                                            { id: "Sunset Terracotta", color: "#e07a5f" },
                                            { id: "Cyberpunk Cyan", color: "#00f0ff" },
                                            { id: "Tokyo Night", color: "#7aa2f7" },
                                            { id: "Rose Gold Pine", color: "#ebbcba" },
                                            { id: "Gruvbox Amber", color: "#fabd2f" },
                                            { id: "Catppuccin Mocha", color: "#cba6f7" },
                                            { id: "Catppuccin Macchiato", color: "#8aadf4" },
                                            { id: "Dracula Purple", color: "#bd93f9" },
                                            { id: "Sakura Blossom", color: "#f5bde6" },
                                            { id: "Synthwave Neon", color: "#ff2a85" },
                                            { id: "Crimson Ruby", color: "#ff5555" },
                                            { id: "Electric Violet", color: "#a855f7" },
                                            { id: "Matcha Forest", color: "#859900" },
                                            { id: "Sunburst Gold", color: "#facc15" },
                                            { id: "Solarized Cyan", color: "#2aa198" },
                                            { id: "One Dark Pro", color: "#61afef" },
                                            { id: "Monokai Pro", color: "#ffd866" },
                                            { id: "Deep Abyss", color: "#2dd4bf" }
                                        ]

                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            radius: 10
                                            color: root.cfg.currentTheme === modelData.id ? Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.15) : root.cfg.bgElevated
                                            border.color: root.cfg.currentTheme === modelData.id ? root.cfg.accent : root.cfg.borderCol
                                            border.width: 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 8

                                                Rectangle {
                                                    Layout.preferredWidth: 14
                                                    Layout.preferredHeight: 14
                                                    radius: 7
                                                    color: modelData.color
                                                    border.color: Qt.rgba(1, 1, 1, 0.2)
                                                    border.width: 1
                                                }

                                                Text {
                                                    text: modelData.id
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: root.cfg.currentTheme === modelData.id
                                                    font.family: root.cfg.fontFamily
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    visible: root.cfg.currentTheme === modelData.id
                                                    text: "✓"
                                                    color: root.cfg.accent
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.cfg.applyTheme(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }

                            // 2. СОХРАНЁННЫЕ ПОЛЬЗОВАТЕЛЬСКИЕ ТЕМЫ
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: root.cfg.customThemes && root.cfg.customThemes.length > 0

                                Text {
                                    text: "Ваши собственные темы"
                                    color: root.cfg.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: root.cfg.fontFamily
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 6
                                    columnSpacing: 6

                                    Repeater {
                                        model: root.cfg.customThemes
                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            radius: 10
                                            color: root.cfg.currentTheme === modelData.name ? Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.15) : root.cfg.bgElevated
                                            border.color: root.cfg.currentTheme === modelData.name ? root.cfg.accent : root.cfg.borderCol
                                            border.width: 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 6
                                                spacing: 8

                                                Rectangle {
                                                    Layout.preferredWidth: 14
                                                    Layout.preferredHeight: 14
                                                    radius: 7
                                                    color: modelData.accent
                                                    border.color: Qt.rgba(1, 1, 1, 0.2)
                                                    border.width: 1
                                                }

                                                Text {
                                                    text: modelData.name
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: root.cfg.currentTheme === modelData.name
                                                    font.family: root.cfg.fontFamily
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    visible: root.cfg.currentTheme === modelData.name
                                                    text: "✓"
                                                    color: root.cfg.accent
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }

                                                Rectangle {
                                                    width: 24
                                                    height: 24
                                                    radius: 12
                                                    color: delCustomM.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.25) : "transparent"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "✕"
                                                        color: delCustomM.containsMouse ? (root.cfg.danger || "#ef4444") : root.cfg.textMuted
                                                        font.pixelSize: 10
                                                    }
                                                    MouseArea {
                                                        id: delCustomM
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.cfg.removeCustomTheme(modelData.name)
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.rightMargin: 30
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.cfg.applyCustomTheme(modelData.name)
                                            }
                                        }
                                    }
                                }
                            }

                            // 3. СТУДИЯ КАСТОМИЗАЦИИ С ПОЛНОЙ RGB НАСТРОЙКОЙ
                            Rectangle {
                                id: customStudioCard
                                Layout.fillWidth: true
                                radius: 14
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: studioCol.implicitHeight + 28

                                property int redVal: 255
                                property int greenVal: 42
                                property int blueVal: 133
                                property string currentHex: "#ff2a85"
                                property int selectedToneIdx: 1
                                property bool updatingInternally: false

                                function syncRgbToHex() {
                                    if (updatingInternally) return
                                    updatingInternally = true
                                    let rH = Math.max(0, Math.min(255, redVal)).toString(16)
                                    let gH = Math.max(0, Math.min(255, greenVal)).toString(16)
                                    let bH = Math.max(0, Math.min(255, blueVal)).toString(16)
                                    if (rH.length < 2) rH = "0" + rH
                                    if (gH.length < 2) gH = "0" + gH
                                    if (bH.length < 2) bH = "0" + bH
                                    currentHex = "#" + rH + gH + bH
                                    hexInput.text = currentHex
                                    updatingInternally = false
                                }

                                function syncHexToRgb(hText) {
                                    if (updatingInternally) return
                                    let clean = hText.replace("#", "").trim()
                                    if (clean.length === 3) {
                                        clean = clean[0] + clean[0] + clean[1] + clean[1] + clean[2] + clean[2]
                                    }
                                    if (clean.length === 6) {
                                        let r = parseInt(clean.substring(0, 2), 16)
                                        let g = parseInt(clean.substring(2, 4), 16)
                                        let b = parseInt(clean.substring(4, 6), 16)
                                        if (!isNaN(r) && !isNaN(g) && !isNaN(b)) {
                                            updatingInternally = true
                                            redVal = r
                                            greenVal = g
                                            blueVal = b
                                            currentHex = "#" + clean.toLowerCase()
                                            updatingInternally = false
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: studioCol
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Создать свою тему (RGB палитра)"
                                            color: root.cfg.textPrimary
                                            font.pixelSize: 13
                                            font.bold: true
                                            font.family: root.cfg.fontFamily
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            height: 22
                                            width: 70
                                            radius: 6
                                            color: Qt.rgba(customStudioCard.redVal/255.0, customStudioCard.greenVal/255.0, customStudioCard.blueVal/255.0, 0.2)
                                            border.color: customStudioCard.currentHex
                                            border.width: 1
                                            Text {
                                                anchors.centerIn: parent
                                                text: customStudioCard.currentHex.toUpperCase()
                                                color: customStudioCard.currentHex
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }
                                    }

                                    // Живое превью темы
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 52
                                        radius: 10
                                        color: {
                                            if (customStudioCard.selectedToneIdx === 0) return "#0c0d10"
                                            if (customStudioCard.selectedToneIdx === 2) return "#161924"
                                            if (customStudioCard.selectedToneIdx === 3) return "#1e1a19"
                                            return "#1a1c22"
                                        }
                                        border.color: Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            // Превью иконки
                                            Rectangle {
                                                width: 32
                                                height: 32
                                                radius: 16
                                                color: customStudioCard.currentHex
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰏘"
                                                    color: "#ffffff"
                                                    font.pixelSize: 14
                                                }
                                            }

                                            // Превью акцентного бейджа
                                            Rectangle {
                                                height: 26
                                                implicitWidth: 84
                                                radius: 13
                                                color: Qt.rgba(customStudioCard.redVal/255.0, customStudioCard.greenVal/255.0, customStudioCard.blueVal/255.0, 0.25)
                                                border.color: customStudioCard.currentHex
                                                border.width: 1
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Акцент"
                                                    color: customStudioCard.currentHex
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }

                                            // Превью кнопки
                                            Rectangle {
                                                height: 26
                                                implicitWidth: 90
                                                radius: 8
                                                color: customStudioCard.currentHex
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Кнопка"
                                                    color: (customStudioCard.redVal*0.299 + customStudioCard.greenVal*0.587 + customStudioCard.blueVal*0.114) > 160 ? "#111116" : "#ffffff"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }

                                            Item { Layout.fillWidth: true }

                                            Text {
                                                text: "Превью стиля"
                                                color: root.cfg.textMuted
                                                font.pixelSize: 10
                                            }
                                        }
                                    }

                                    // Поле названия темы
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "Название:"
                                            color: root.cfg.textMuted
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 65
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 32
                                            radius: 8
                                            color: root.cfg.bgSurface
                                            border.color: root.cfg.borderCol
                                            border.width: 1

                                            TextInput {
                                                id: customNameInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 11
                                                font.family: root.cfg.fontFamily
                                                text: "Мой стиль"
                                            }
                                        }
                                    }

                                    // Выбор базового тона фона
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "Тон фона:"
                                            color: root.cfg.textMuted
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 65
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Repeater {
                                                model: [
                                                    { id: 0, title: "AMOLED", col: "#0c0d10" },
                                                    { id: 1, title: "Material", col: "#1a1c22" },
                                                    { id: 2, title: "Индиго", col: "#161924" },
                                                    { id: 3, title: "Кофе", col: "#1e1a19" }
                                                ]

                                                Rectangle {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    height: 28
                                                    radius: 8
                                                    color: customStudioCard.selectedToneIdx === modelData.id ? Qt.rgba(customStudioCard.redVal/255.0, customStudioCard.greenVal/255.0, customStudioCard.blueVal/255.0, 0.15) : root.cfg.bgSurface
                                                    border.color: customStudioCard.selectedToneIdx === modelData.id ? customStudioCard.currentHex : root.cfg.borderCol
                                                    border.width: 1

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 6
                                                        Rectangle {
                                                            width: 10; height: 10; radius: 5
                                                            color: modelData.col
                                                            border.color: Qt.rgba(1, 1, 1, 0.3)
                                                            border.width: 1
                                                        }
                                                        Text {
                                                            text: modelData.title
                                                            color: customStudioCard.selectedToneIdx === modelData.id ? customStudioCard.currentHex : root.cfg.textPrimary
                                                            font.pixelSize: 10
                                                            font.bold: customStudioCard.selectedToneIdx === modelData.id
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: customStudioCard.selectedToneIdx = modelData.id
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Быстрые готовые цвета
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "Пресеты:"
                                            color: root.cfg.textMuted
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 65
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Repeater {
                                                model: ["#ff5555", "#ff7597", "#ff9e64", "#facc15", "#a6e3a1", "#2dd4bf", "#00f0ff", "#7aa2f7", "#a855f7", "#ffffff"]

                                                Rectangle {
                                                    required property string modelData
                                                    Layout.fillWidth: true
                                                    height: 22
                                                    radius: 6
                                                    color: modelData
                                                    border.color: customStudioCard.currentHex === modelData ? "#ffffff" : "transparent"
                                                    border.width: 2

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: customStudioCard.syncHexToRgb(modelData)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // RGB ПОЛЗУНКИ
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        // Ползунок R (Red)
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: "R"
                                                color: "#ff5555"
                                                font.pixelSize: 11
                                                font.bold: true
                                                Layout.preferredWidth: 16
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                height: 22

                                                Rectangle {
                                                    id: rTrack
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 8
                                                    radius: 4
                                                    color: Qt.rgba(1, 1, 1, 0.08)

                                                    Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                        width: Math.max(8, Math.min(rTrack.width, rTrack.width * (customStudioCard.redVal / 255.0)))
                                                        radius: 4
                                                        color: "#ff5555"
                                                    }
                                                }

                                                Rectangle {
                                                    x: Math.max(0, Math.min(rTrack.width - width, (rTrack.width - width) * (customStudioCard.redVal / 255.0)))
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "#ffffff"
                                                    border.color: Qt.rgba(0, 0, 0, 0.4)
                                                    border.width: 1
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    function setVal(mx) {
                                                        let ratio = Math.max(0, Math.min(1.0, mx / width))
                                                        customStudioCard.redVal = Math.round(ratio * 255)
                                                        customStudioCard.syncRgbToHex()
                                                    }
                                                    onPressed: mouse => setVal(mouse.x)
                                                    onPositionChanged: mouse => { if (pressed) setVal(mouse.x) }
                                                }
                                            }

                                            Rectangle {
                                                width: 38
                                                height: 22
                                                radius: 6
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: customStudioCard.redVal.toString()
                                                    color: "#ff5555"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        // Ползунок G (Green)
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: "G"
                                                color: "#50fa7b"
                                                font.pixelSize: 11
                                                font.bold: true
                                                Layout.preferredWidth: 16
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                height: 22

                                                Rectangle {
                                                    id: gTrack
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 8
                                                    radius: 4
                                                    color: Qt.rgba(1, 1, 1, 0.08)

                                                    Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                        width: Math.max(8, Math.min(gTrack.width, gTrack.width * (customStudioCard.greenVal / 255.0)))
                                                        radius: 4
                                                        color: "#50fa7b"
                                                    }
                                                }

                                                Rectangle {
                                                    x: Math.max(0, Math.min(gTrack.width - width, (gTrack.width - width) * (customStudioCard.greenVal / 255.0)))
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "#ffffff"
                                                    border.color: Qt.rgba(0, 0, 0, 0.4)
                                                    border.width: 1
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    function setVal(mx) {
                                                        let ratio = Math.max(0, Math.min(1.0, mx / width))
                                                        customStudioCard.greenVal = Math.round(ratio * 255)
                                                        customStudioCard.syncRgbToHex()
                                                    }
                                                    onPressed: mouse => setVal(mouse.x)
                                                    onPositionChanged: mouse => { if (pressed) setVal(mouse.x) }
                                                }
                                            }

                                            Rectangle {
                                                width: 38
                                                height: 22
                                                radius: 6
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: customStudioCard.greenVal.toString()
                                                    color: "#50fa7b"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        // Ползунок B (Blue)
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: "B"
                                                color: "#8be9fd"
                                                font.pixelSize: 11
                                                font.bold: true
                                                Layout.preferredWidth: 16
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                height: 22

                                                Rectangle {
                                                    id: bTrack
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 8
                                                    radius: 4
                                                    color: Qt.rgba(1, 1, 1, 0.08)

                                                    Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                        width: Math.max(8, Math.min(bTrack.width, bTrack.width * (customStudioCard.blueVal / 255.0)))
                                                        radius: 4
                                                        color: "#8be9fd"
                                                    }
                                                }

                                                Rectangle {
                                                    x: Math.max(0, Math.min(bTrack.width - width, (bTrack.width - width) * (customStudioCard.blueVal / 255.0)))
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "#ffffff"
                                                    border.color: Qt.rgba(0, 0, 0, 0.4)
                                                    border.width: 1
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    function setVal(mx) {
                                                        let ratio = Math.max(0, Math.min(1.0, mx / width))
                                                        customStudioCard.blueVal = Math.round(ratio * 255)
                                                        customStudioCard.syncRgbToHex()
                                                    }
                                                    onPressed: mouse => setVal(mouse.x)
                                                    onPositionChanged: mouse => { if (pressed) setVal(mouse.x) }
                                                }
                                            }

                                            Rectangle {
                                                width: 38
                                                height: 22
                                                radius: 6
                                                color: root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: customStudioCard.blueVal.toString()
                                                    color: "#8be9fd"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }
                                        }
                                    }

                                    // HEX ввод и кнопка "Сохранить и применить"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: "HEX код:"
                                            color: root.cfg.textMuted
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 65
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 100
                                            height: 32
                                            radius: 8
                                            color: root.cfg.bgSurface
                                            border.color: root.cfg.borderCol
                                            border.width: 1

                                            TextInput {
                                                id: hexInput
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 11
                                                font.bold: true
                                                font.family: root.cfg.fontFamily
                                                text: customStudioCard.currentHex
                                                onTextEdited: customStudioCard.syncHexToRgb(text)
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            height: 32
                                            implicitWidth: saveThemeBtnText.implicitWidth + 28
                                            radius: 8
                                            color: customStudioCard.currentHex

                                            Text {
                                                id: saveThemeBtnText
                                                anchors.centerIn: parent
                                                text: "Сохранить и применить"
                                                color: (customStudioCard.redVal*0.299 + customStudioCard.greenVal*0.587 + customStudioCard.blueVal*0.114) > 160 ? "#111116" : "#ffffff"
                                                font.pixelSize: 11
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let n = customNameInput.text.trim()
                                                    if (!n) n = "Мой стиль"
                                                    let hex = customStudioCard.currentHex
                                                    let surf = "#1a1c22"
                                                    let prim = "#131418"
                                                    let elev = "#252730"
                                                    if (customStudioCard.selectedToneIdx === 0) {
                                                        surf = "#0c0d10"; prim = "#050608"; elev = "#16181f"
                                                    } else if (customStudioCard.selectedToneIdx === 2) {
                                                        surf = "#161924"; prim = "#0f121a"; elev = "#222738"
                                                    } else if (customStudioCard.selectedToneIdx === 3) {
                                                        surf = "#1e1a19"; prim = "#141110"; elev = "#2c2625"
                                                    }
                                                    let cont = Qt.darker(hex, 2.0).toString()
                                                    root.cfg.addCustomTheme(n, hex, surf, prim, elev, cont)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // ================= ВКЛАДКА 6: ИНДИКАТОРЫ OSD =================
                        ColumnLayout {
                            id: osdTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 12
                            visible: root.tab === "osd"

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Индикатор OSD"
                                    color: root.cfg.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: root.cfg.fontFamily
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    height: 30
                                    implicitWidth: osdLiveBtnTxt.implicitWidth + 24
                                    radius: 15
                                    color: root.cfg.accent

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "󰆣"; color: root.cfg.accentText; font.pixelSize: 12 }
                                        Text { id: osdLiveBtnTxt; text: "Настроить на экране"; color: root.cfg.accentText; font.pixelSize: 11; font.bold: true }
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.closeRequested()
                                            root.requestWidgetEditor("osd")
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: 12
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 10

                                    Text {
                                        text: "󰆣"
                                        color: root.cfg.accent
                                        font.pixelSize: 16
                                    }

                                    Text {
                                        text: "Положение OSD настраивается интерактивно прямо на экране (кнопка выше) или пресетами:"
                                        color: root.cfg.textPrimary
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Пресеты положения
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6

                                Repeater {
                                    model: [
                                        { name: "Снизу (120 px)", by: 120, lx: 840 },
                                        { name: "По центру", by: 518, lx: 840 },
                                        { name: "Слева", by: 120, lx: 40 },
                                        { name: "Справа", by: 120, lx: 1640 },
                                        { name: "Вверху", by: 960, lx: 840 }
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        Layout.preferredHeight: 24
                                        Layout.preferredWidth: pText.implicitWidth + 14
                                        radius: 12
                                        color: (root.cfg.osdBottomMargin === modelData.by && Math.abs(root.cfg.osdLeftMargin - modelData.lx) < 20) ? root.cfg.accent : root.cfg.bgElevated
                                        border.color: root.cfg.borderCol
                                        border.width: 1

                                        Text {
                                            id: pText
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            color: (root.cfg.osdBottomMargin === modelData.by && Math.abs(root.cfg.osdLeftMargin - modelData.lx) < 20) ? root.cfg.accentText : root.cfg.textPrimary
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.cfg.osdBottomMargin = modelData.by
                                                root.cfg.osdLeftMargin = modelData.lx
                                                root.cfg.save()
                                            }
                                        }
                                    }
                                }
                            }

                            // Тумблеры OSD
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 6
                                columnSpacing: 6

                                Repeater {
                                    model: [
                                        { name: "Громкость", prop: "osdVolume" },
                                        { name: "Раскладка клавиатуры", prop: "osdLang" },
                                        { name: "Caps Lock", prop: "osdCaps" },
                                        { name: "Режим «Не беспокоить»", prop: "dndMode" }
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        radius: 10
                                        color: root.cfg.bgElevated
                                        border.color: root.cfg.borderCol
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 10

                                            Text { text: modelData.name; color: root.cfg.textPrimary; font.pixelSize: 11; Layout.fillWidth: true }

                                            Rectangle {
                                                Layout.preferredWidth: 36; Layout.preferredHeight: 20; radius: 10
                                                color: root.cfg[modelData.prop] ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Rectangle {
                                                    width: 14; height: 14; radius: 7; y: 2
                                                    x: root.cfg[modelData.prop] ? 18 : 2
                                                    color: root.cfg[modelData.prop] ? root.cfg.accentText : root.cfg.textMuted
                                                    Behavior on x { NumberAnimation { duration: 140 } }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.cfg[modelData.prop] = !root.cfg[modelData.prop]
                                                root.cfg.save()
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // ================= ВКЛАДКА 7: БЛОКИРОВКА =================
                        ColumnLayout {
                            id: lockTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 14
                            visible: root.tab === "lock"

                            Text {
                                text: "Параметры входа"
                                color: root.cfg.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                font.family: root.cfg.fontFamily
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 14
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: lockFieldsCol.implicitHeight

                                ColumnLayout {
                                    id: lockFieldsCol
                                    anchors.fill: parent
                                    spacing: 0

                                    // PIN
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 46

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "Аварийный PIN:"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 160 }

                                            Rectangle {
                                                Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 6
                                                color: root.cfg.bgSurface
                                                border.color: pinInp.activeFocus ? root.cfg.accent : root.cfg.borderCol
                                                border.width: 1

                                                TextInput {
                                                    id: pinInp
                                                    anchors.fill: parent; anchors.margins: 6
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 11; font.bold: true
                                                    text: root.cfg.lockPin
                                                    onTextEdited: { root.cfg.lockPin = text; root.cfg.save() }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol; Layout.leftMargin: 14; Layout.rightMargin: 14 }

                                    // Город погоды
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 46

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "Город прогноза:"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 160 }

                                            Rectangle {
                                                Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 6
                                                color: root.cfg.bgSurface
                                                border.color: cityInp.activeFocus ? root.cfg.accent : root.cfg.borderCol
                                                border.width: 1

                                                TextInput {
                                                    id: cityInp
                                                    anchors.fill: parent; anchors.margins: 6
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    text: root.cfg.weatherCity
                                                    onTextEdited: { root.cfg.weatherCity = text; root.cfg.save() }
                                                    onAccepted: root.cfg.refreshWeather()
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol; Layout.leftMargin: 14; Layout.rightMargin: 14 }

                                    // Путь к аватарке
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 46

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "Файл аватарки:"; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 160 }

                                            Rectangle {
                                                Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 6
                                                color: root.cfg.bgSurface
                                                border.color: avatarInp.activeFocus ? root.cfg.accent : root.cfg.borderCol
                                                border.width: 1

                                                TextInput {
                                                    id: avatarInp
                                                    anchors.fill: parent; anchors.margins: 6
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    text: root.cfg.avatarPath
                                                    onTextEdited: { root.cfg.avatarPath = text; root.cfg.save() }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Элементы экрана"
                                color: root.cfg.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                font.family: root.cfg.fontFamily
                                Layout.topMargin: 4
                            }

                            GridLayout {
                                Layout.fillWidth: true; columns: 2; rowSpacing: 6; columnSpacing: 6
                                Repeater {
                                    model: [
                                        { name: "Аватарка", prop: "lockShowAvatar" },
                                        { name: "Датчики ресурсов", prop: "lockShowGauges" },
                                        { name: "Погода", prop: "lockShowWeather" },
                                        { name: "Дата", prop: "lockShowDate" }
                                    ]
                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true; Layout.preferredHeight: 38; radius: 10
                                        color: root.cfg.bgElevated; border.color: root.cfg.borderCol; border.width: 1
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10
                                            Text { text: modelData.name; color: root.cfg.textPrimary; font.pixelSize: 11; Layout.fillWidth: true }
                                            Rectangle {
                                                Layout.preferredWidth: 36; Layout.preferredHeight: 20; radius: 10
                                                color: root.cfg[modelData.prop] ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol; border.width: 1
                                                Rectangle {
                                                    width: 14; height: 14; radius: 7; y: 2
                                                    x: root.cfg[modelData.prop] ? 18 : 2
                                                    color: root.cfg[modelData.prop] ? root.cfg.accentText : root.cfg.textMuted
                                                    Behavior on x { NumberAnimation { duration: 140 } }
                                                }
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { root.cfg[modelData.prop] = !root.cfg[modelData.prop]; root.cfg.save() }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 18
                                color: root.cfg.accent
                                Layout.topMargin: 4

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰌾"; color: root.cfg.accentText; font.pixelSize: 13 }
                                    Text { text: "Заблокировать экран"; color: root.cfg.accentText; font.pixelSize: 12; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.closeRequested(); root.cfg.isLocked = true }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // ================= ВКЛАДКА 8: СИСТЕМА =================
                        ColumnLayout {
                            id: systemTabCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 14
                            visible: root.tab === "system"

                            Text {
                                text: "Окружение"
                                color: root.cfg.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                font.family: root.cfg.fontFamily
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 14
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                implicitHeight: envGroupCol.implicitHeight

                                ColumnLayout {
                                    id: envGroupCol
                                    anchors.fill: parent
                                    spacing: 0

                                    // Перезагрузка Hyprland
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "󰑐"; color: root.cfg.accent; font.pixelSize: 15 }
                                            Text {
                                                text: "Перезагрузить Hyprland"
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: root.cfg.fontFamily
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                height: 28
                                                implicitWidth: 100
                                                radius: 14
                                                color: rldM.containsMouse ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Перезагрузить"
                                                    color: rldM.containsMouse ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    id: rldM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        settingsSysProc.command = ["sh", "-c", "hyprctl reload"]
                                                        settingsSysProc.running = true
                                                        root.cfg.pushNotification("Hyprland", "Конфигурация перезагружена")
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol; Layout.leftMargin: 14; Layout.rightMargin: 14 }

                                    // Очистить историю уведомлений
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "󰂚"; color: root.cfg.textMuted; font.pixelSize: 15 }
                                            Text {
                                                text: "Очистить историю уведомлений"
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: root.cfg.fontFamily
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                height: 28
                                                implicitWidth: 80
                                                radius: 14
                                                color: clrNotifM.containsMouse ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Очистить"
                                                    color: clrNotifM.containsMouse ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    id: clrNotifM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.cfg.clearNotifications()
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol; Layout.leftMargin: 14; Layout.rightMargin: 14 }

                                    // Сохранить настройки
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "󰜉"; color: root.cfg.textMuted; font.pixelSize: 15 }
                                            Text {
                                                text: "Сохранить конфигурацию"
                                                color: root.cfg.textPrimary
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: root.cfg.fontFamily
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                height: 28
                                                implicitWidth: 80
                                                radius: 14
                                                color: saveCfgM.containsMouse ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Сохранить"
                                                    color: saveCfgM.containsMouse ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    id: saveCfgM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.cfg.save()
                                                        root.cfg.pushNotification("Quickshell", "Конфигурация сохранена")
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cfg.borderCol; Layout.leftMargin: 14; Layout.rightMargin: 14 }

                                    // Автообновление конфигурации
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 14

                                            Text { text: "󰚰"; color: root.cfg.accent; font.pixelSize: 15 }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    text: "Обновление конфигурации"
                                                    color: root.cfg.textPrimary
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    font.family: root.cfg.fontFamily
                                                }
                                                Text {
                                                    text: "Синхронизация с GitHub (StopNope/dotfile-Hyprland)"
                                                    color: root.cfg.textMuted
                                                    font.pixelSize: 10
                                                    font.family: root.cfg.fontFamily
                                                }
                                            }

                                            Rectangle {
                                                height: 28
                                                implicitWidth: 90
                                                radius: 14
                                                color: updCfgM.containsMouse ? root.cfg.accent : root.cfg.bgSurface
                                                border.color: root.cfg.borderCol
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Обновить"
                                                    color: updCfgM.containsMouse ? root.cfg.accentText : root.cfg.textPrimary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    id: updCfgM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        settingsSysProc.command = ["bash", "/home/stopnope/.config/quickshell/scripts/updater.sh"]
                                                        settingsSysProc.running = true
                                                        root.cfg.pushNotification("Обновление", "Запущена проверка обновлений из GitHub...")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Бесконечный рабочий стол"
                                color: root.cfg.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                font.family: root.cfg.fontFamily
                                Layout.topMargin: 4
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 14
                                color: root.cfg.bgElevated
                                border.color: root.cfg.borderCol
                                border.width: 1
                                Layout.preferredHeight: 50

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 14

                                    Text { text: "󰹑"; color: root.cfg.accent; font.pixelSize: 16 }
                                    Text {
                                        text: "Ограничивать окна текущим монитором"
                                        color: root.cfg.textPrimary
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: root.cfg.fontFamily
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: 42; height: 24; radius: 12
                                        color: root.clampToMonitor ? root.cfg.accent : root.cfg.bgSurface
                                        border.color: root.cfg.borderCol; border.width: 1
                                        Rectangle {
                                            width: 18; height: 18; radius: 9
                                            color: root.clampToMonitor ? root.cfg.accentText : root.cfg.textMuted
                                            x: root.clampToMonitor ? 21 : 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            Behavior on x { NumberAnimation { duration: 140 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.clampToMonitor = !root.clampToMonitor
                                                settingsSysProc.command = ["python3", "/home/stopnope/.config/quickshell/scripts/vxwm_controller.py", "toggle_clamp"]
                                                settingsSysProc.running = true
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // Скроллбар
                Item {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    width: 4
                    visible: tabFlickable.contentHeight > tabFlickable.height

                    Rectangle {
                        id: scrollThumb
                        anchors.right: parent.right
                        width: 4
                        radius: 2
                        color: root.cfg.accent
                        opacity: 0.65
                        height: Math.max(28, (tabFlickable.height / tabFlickable.contentHeight) * tabFlickable.height)
                        y: Math.max(0, Math.min(parent.height - height, (tabFlickable.contentY / Math.max(1, tabFlickable.contentHeight - tabFlickable.height)) * (parent.height - height)))
                    }
                }
            }
        }
    }
}
