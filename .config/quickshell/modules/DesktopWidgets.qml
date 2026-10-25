import QtQuick
import Quickshell.Io
import "./widgets"

Item {
    id: root

    required property var cfg
    property var currentScreen: null

    anchors.fill: parent
    visible: root.cfg.showDesktopWidgets

    // Определение смещения текущего монитора в общем глобальном пространстве Hyprland
    readonly property var screenOffset: root.cfg.getScreenOffset(root.currentScreen ? root.currentScreen.name : "")
    readonly property int monX: screenOffset ? screenOffset.x : 0
    readonly property int monY: screenOffset ? screenOffset.y : 0
    readonly property int monW: screenOffset ? screenOffset.w : (root.currentScreen ? root.currentScreen.width : 1920)
    readonly property int monH: screenOffset ? screenOffset.h : (root.currentScreen ? root.currentScreen.height : 1080)

    // =========================================================================
    // ПАНОРАМИРОВАНИЕ ХОЛСТА МЫШЬЮ (1:1 LOSSLESS ACCUMULATOR)
    // =========================================================================
    property int queueDx: 0
    property int queueDy: 0

    function dispatchPan() {
        if (panProc.running) return;
        if (queueDx === 0 && queueDy === 0) return;

        let curDx = queueDx;
        let curDy = queueDy;
        queueDx = 0;
        queueDy = 0;

        panProc.command = [
            "/home/stopnope/.config/quickshell/scripts/vxwm_controller.py",
            "pan",
            curDx.toString(),
            curDy.toString()
        ];
        panProc.running = true;
    }

    MouseArea {
        id: bgCanvasDragArea
        anchors.fill: parent
        z: 0 // Ниже всех виджетов
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: isDragging ? Qt.ClosedHandCursor : Qt.ArrowCursor

        property real lastX: 0
        property real lastY: 0
        property bool isDragging: false

        onPressed: mouse => {
            isDragging = true
            lastX = mouse.x
            lastY = mouse.y
        }

        onPositionChanged: mouse => {
            if (isDragging) {
                let dx = Math.round(mouse.x - lastX)
                let dy = Math.round(mouse.y - lastY)
                if (dx !== 0 || dy !== 0) {
                    lastX = mouse.x
                    lastY = mouse.y
                    root.queueDx += dx
                    root.queueDy += dy
                    root.dispatchPan()
                }
            }
        }

        onReleased: {
            isDragging = false
            root.dispatchPan()
        }
    }

    Process {
        id: panProc
        running: false
        onExited: {
            if (root.queueDx !== 0 || root.queueDy !== 0) {
                root.dispatchPan()
            }
        }
    }

    // =========================================================================
    // ОТОБРАЖЕНИЕ ВИДЖЕТОВ НА ДАННОМ ЭКРАНЕ
    // =========================================================================
    Repeater {
        model: root.cfg.desktopWidgets

        Item {
            id: widgetContainer
            required property var modelData
            z: 10 // Выше зоны перетаскивания фона

            readonly property int gwX: modelData.x !== undefined ? modelData.x : 100
            readonly property int gwY: modelData.y !== undefined ? modelData.y : 100
            readonly property int gwW: modelData.w || 260
            readonly property int gwH: modelData.h || 130

            // Переводим глобальные координаты в локальные координаты текущего монитора
            readonly property int localX: gwX - root.monX
            readonly property int localY: gwY - root.monY

            // Проверяем видимость: виджет отображается только если попадает в область данного монитора
            readonly property bool isInScreen: (localX + gwW > 0) && (localX < root.monW) && (localY + gwH > 0) && (localY < root.monH)

            x: localX
            y: localY
            width: gwW
            height: gwH
            visible: (modelData.visible !== false) && isInScreen

            // Загрузка нужного виджета по типу с передачей данных
            Loader {
                id: wLoader
                anchors.fill: parent
                property var itemData: widgetContainer.modelData

                sourceComponent: {
                    let t = widgetContainer.modelData.type
                    if (t === "clock") return clockComp
                    if (t === "weather") return weatherComp
                    if (t === "vitals") return vitalsComp
                    if (t === "player") return playerComp
                    if (t === "calendar") return calendarComp
                    if (t === "notes") return notesComp
                    if (t === "storage") return storageComp
                    return clockComp
                }
            }
        }
    }

    Component { id: clockComp; ClockWidget { cfg: root.cfg; widgetData: parent.itemData || ({}) } }
    Component { id: weatherComp; WeatherWidget { cfg: root.cfg; widgetData: parent.itemData || ({}) } }
    Component { id: vitalsComp; VitalsWidget { cfg: root.cfg; widgetData: parent.itemData || ({}) } }
    Component { id: playerComp; MediaWidget { cfg: root.cfg; widgetData: parent.itemData || ({}) } }
    Component { id: calendarComp; CalendarWidget { cfg: root.cfg; widgetData: parent.itemData || ({}) } }
    Component { id: notesComp; NotesWidget { cfg: root.cfg; widgetData: parent.itemData || ({}) } }
    Component { id: storageComp; StorageWidget { cfg: root.cfg; widgetData: parent.itemData || ({}) } }
}
