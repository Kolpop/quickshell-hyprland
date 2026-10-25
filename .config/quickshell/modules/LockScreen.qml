import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Rectangle {
    id: root

    required property var cfg

    // Полупрозрачный глубокий фон под блюр Hyprland (Frosted Glass)
    color: Qt.rgba(0.06, 0.07, 0.09, 0.50)

    property bool wrongPass: false
    property bool isAuthenticating: false
    property string authMessage: ""

    // ================= PAM СИСТЕМНАЯ АУТЕНТИФИКАЦИЯ =================
    PamContext {
        id: pam
        config: "hyprlock"
        user: Quickshell.env("USER") || "stopnope"

        onCompleted: (result) => {
            root.isAuthenticating = false
            if (result === PamResult.Success) {
                root.wrongPass = false
                root.authMessage = ""
                pinInput.text = ""
                root.cfg.isLocked = false
            } else {
                root.wrongPass = true
                root.authMessage = "Неверный пароль"
                pinInput.text = ""
                shakeTimer.restart()
                pam.start()
            }
        }

        onError: (err) => {
            root.isAuthenticating = false
            root.wrongPass = true
            root.authMessage = "Ошибка PAM: " + PamError.toString(err)
            shakeTimer.restart()
            pam.start()
        }
    }

    Process {
        id: switchLangLock
        command: ["sh", "-c", "hyprctl switchxkblayout all next"]
    }

    function grabInputFocus() {
        pinInput.forceActiveFocus()
    }

    Component.onCompleted: {
        grabInputFocus()
        if (root.cfg.isLocked) pam.start()
    }

    Connections {
        target: root.cfg
        function onIsLockedChanged() {
            if (root.cfg.isLocked) {
                pinInput.text = ""
                root.wrongPass = false
                root.isAuthenticating = false
                root.authMessage = ""
                pam.start()
                pinInput.forceActiveFocus()
            } else {
                pam.abort()
            }
        }
    }

    // Клик в любое место возвращает фокус в поле ввода
    MouseArea {
        anchors.fill: parent
        onClicked: pinInput.forceActiveFocus()
    }

    // Скрытое нативное поле ввода (поддерживает все символы, Backspace, смену языка)
    TextInput {
        id: pinInput
        opacity: 0
        width: 1
        height: 1
        focus: true
        echoMode: TextInput.Password
        onTextChanged: {
            if (text.length > 0) {
                root.wrongPass = false
                root.authMessage = ""
            }
        }
        Keys.onReturnPressed: root.tryUnlock()
        Keys.onEnterPressed: root.tryUnlock()
        Keys.onEscapePressed: {
            pinInput.text = ""
            root.wrongPass = false
            root.authMessage = ""
        }
    }

    function tryUnlock() {
        if (pinInput.text.length === 0 || root.isAuthenticating) return

        // Поддержка запасного PIN (если совпадает - моментальный анлок)
        if (root.cfg.lockPin && pinInput.text === root.cfg.lockPin) {
            pinInput.text = ""
            root.wrongPass = false
            root.authMessage = ""
            root.cfg.isLocked = false
            return
        }

        root.isAuthenticating = true
        root.authMessage = "Проверка..."

        if (pam.responseRequired) {
            pam.respond(pinInput.text)
        } else {
            // Если PAM не успел запросить, запускаем и передаем
            pam.start()
            pamTimer.restart()
        }
    }

    Timer {
        id: pamTimer
        interval: 150
        onTriggered: {
            if (pam.responseRequired && root.isAuthenticating) {
                pam.respond(pinInput.text)
            }
        }
    }

    Timer {
        id: shakeTimer
        interval: 1200
        onTriggered: {
            root.wrongPass = false
            root.authMessage = ""
        }
    }

    // Анимация тряски при ошибке ввода
    property real shakeOffset: 0
    SequentialAnimation {
        id: shakeAnim
        running: root.wrongPass
        loops: 1
        NumberAnimation { target: root; property: "shakeOffset"; to: -10; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 10; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: -8; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.OutQuad }
    }

    // ================= ОСНОВНОЙ КОНТЕНТ MATERIAL YOU =================
    ColumnLayout {
        anchors.centerIn: parent
        x: (parent.width - width) / 2 + root.shakeOffset
        spacing: 24

        // 1. БОЛЬШИЕ ЧАСЫ И ДАТА
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                id: bigClock
                Layout.alignment: Qt.AlignHCenter
                color: root.cfg.textPrimary
                font.pixelSize: 68
                font.weight: Font.DemiBold
                text: Qt.formatDateTime(new Date(), "hh:mm")
                Timer {
                    interval: 1000
                    running: root.cfg.isLocked
                    repeat: true
                    onTriggered: bigClock.text = Qt.formatDateTime(new Date(), "hh:mm")
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Rectangle {
                    visible: root.cfg.lockShowDate
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: dateText.implicitWidth + 20
                    radius: 14
                    color: root.cfg.bgPrimary
                    border.color: root.cfg.borderCol
                    border.width: 1

                    Text {
                        id: dateText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(new Date(), "d MMMM, dddd")
                        color: root.cfg.textMuted
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    visible: root.cfg.lockShowWeather
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: weatherText.implicitWidth + 20
                    radius: 14
                    color: root.cfg.bgPrimary
                    border.color: root.cfg.borderCol
                    border.width: 1

                    RowLayout {
                        id: weatherText
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰖐"; color: root.cfg.accent; font.pixelSize: 12 }
                        Text { text: root.cfg.weatherText; color: root.cfg.textPrimary; font.pixelSize: 12; font.bold: true }
                    }
                }
            }
        }

        // 2. ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            // Аватарка
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 84
                Layout.preferredHeight: 84
                radius: 42
                color: root.cfg.bgPrimary
                border.color: root.cfg.accent
                border.width: 2
                clip: true
                visible: root.cfg.lockShowAvatar

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: (root.cfg.avatarPath && root.cfg.avatarPath !== "" && root.cfg.avatarPath !== "/home/stopnope/.face") ? ("file://" + root.cfg.avatarPath) : ""
                    fillMode: Image.PreserveAspectCrop
                }

                Text {
                    anchors.centerIn: parent
                    visible: avatarImg.status !== Image.Ready
                    text: "󰀉"
                    color: root.cfg.accent
                    font.pixelSize: 38
                }
            }

            // Имя пользователя
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Quickshell.env("USER") || "Пользователь"
                color: root.cfg.textPrimary
                font.pixelSize: 16
                font.bold: true
            }
        }

        // 3. ПОЛЕ ПАРОЛЯ (Material You Capsule)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 340
            Layout.preferredHeight: 46
            radius: 23
            color: root.cfg.bgSurface
            border.color: root.wrongPass ? root.cfg.danger : (root.isAuthenticating ? root.cfg.accent : (pinInput.text.length > 0 ? root.cfg.accent : root.cfg.borderCol))
            border.width: root.wrongPass || pinInput.text.length > 0 || root.isAuthenticating ? 2 : 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 10
                spacing: 10

                // Иконка замка или статус аутентификации
                Text {
                    text: root.wrongPass ? "󰅖" : (root.isAuthenticating ? "󰑐" : "󰌾")
                    color: root.wrongPass ? root.cfg.danger : (root.isAuthenticating ? root.cfg.accent : root.cfg.textMuted)
                    font.pixelSize: 16
                    rotation: root.isAuthenticating ? 360 : 0
                    Behavior on rotation { NumberAnimation { duration: 800; loops: Animation.Infinite } }
                }

                // Отображение точек пароля / подсказки
                Text {
                    Layout.fillWidth: true
                    text: {
                        if (root.authMessage !== "") return root.authMessage
                        if (pinInput.text.length > 0) return "•".repeat(pinInput.text.length)
                        return "Системный пароль (PAM)..."
                    }
                    color: root.wrongPass ? root.cfg.danger : (pinInput.text.length > 0 ? root.cfg.textPrimary : root.cfg.textMuted)
                    font.pixelSize: pinInput.text.length > 0 && root.authMessage === "" ? 18 : 12
                    font.bold: pinInput.text.length > 0
                    elide: Text.ElideRight
                }

                // Кнопка очистки
                Rectangle {
                    visible: pinInput.text.length > 0 && !root.isAuthenticating
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: root.cfg.bgElevated

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: root.cfg.textMuted
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pinInput.text = ""
                            pinInput.forceActiveFocus()
                        }
                    }
                }

                // Индикатор раскладки клавиатуры
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 26
                    radius: 13
                    color: root.cfg.bgPrimary
                    border.color: root.cfg.borderCol
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.cfg.currentLang
                        color: root.cfg.textPrimary
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            switchLangLock.running = true
                            pinInput.forceActiveFocus()
                        }
                    }
                }

                // Кнопка подтверждения разблокировки (Enter)
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: pinInput.text.length > 0 ? root.cfg.accent : root.cfg.bgElevated
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        color: pinInput.text.length > 0 ? root.cfg.accentText : root.cfg.textMuted
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: pinInput.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.tryUnlock()
                    }
                }
            }
        }

        // 4. ДАТЧИКИ СИСТЕМЫ (CPU / RAM / GPU в M3 стиле)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: root.cfg.lockShowGauges
            spacing: 12

            Repeater {
                model: [
                    { label: "CPU", icon: "", val: root.cfg.cpuVal },
                    { label: "RAM", icon: "󰘚", val: root.cfg.ramVal },
                    { label: "GPU", icon: "󰢮", val: root.cfg.gpuVal }
                ]

                Rectangle {
                    required property var modelData
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 52
                    radius: 14
                    color: root.cfg.bgSurface
                    border.color: root.cfg.borderCol
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4
                            Text { text: modelData.icon; color: root.cfg.accent; font.pixelSize: 12 }
                            Text { text: modelData.label; color: root.cfg.textMuted; font.pixelSize: 11; font.bold: true }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.val + "%"
                            color: root.cfg.textPrimary
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    // ================= НИЖНЯЯ ПАНЕЛЬ ПИТАНИЯ =================
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 32
        spacing: 16

        Process { id: lockPowerProc }

        Repeater {
            model: [
                { icon: "󰒲", label: "Сон", cmd: "systemctl suspend || loginctl suspend" },
                { icon: "󰜉", label: "Перезагрузка", cmd: "systemctl reboot || loginctl reboot" },
                { icon: "󰐥", label: "Выключение", cmd: "systemctl poweroff || loginctl poweroff" }
            ]

            Rectangle {
                required property var modelData
                Layout.preferredHeight: 34
                Layout.preferredWidth: 120
                radius: 17
                color: pBtnMouse.containsMouse ? root.cfg.bgElevated : root.cfg.bgSurface
                border.color: root.cfg.borderCol
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: modelData.icon; color: root.cfg.textMuted; font.pixelSize: 13 }
                    Text { text: modelData.label; color: root.cfg.textPrimary; font.pixelSize: 11; font.bold: true }
                }

                MouseArea {
                    id: pBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        lockPowerProc.command = ["sh", "-c", modelData.cmd]
                        lockPowerProc.running = true
                    }
                }
            }
        }
    }
}
