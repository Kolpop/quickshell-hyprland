import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    required property var cfg
    property var widgetData: ({})

    readonly property string variant: (widgetData && widgetData.variant) ? widgetData.variant : "stacked_duotone"
    readonly property string size: (widgetData && widgetData.size) ? widgetData.size : "M"
    readonly property bool isWide: width >= height * 1.3
    readonly property bool isTransparent: !!(widgetData && widgetData.transparentBg)

    FontLoader {
        id: fontFredokaBold
        source: Qt.resolvedUrl("../../fonts/Fredoka-Bold.ttf")
    }

    FontLoader {
        id: pixelFontGoogle
        source: Qt.resolvedUrl("../../fonts/GoogleSans-Bold.ttf")
    }

    FontLoader {
        id: pixelFontComfortaa
        source: Qt.resolvedUrl("../../fonts/Comfortaa.ttf")
    }

    // Выбор мягкого аутентичного шрифта Fredoka Bold (как на референсе пользователя)
    readonly property string clockFont: fontFredokaBold.name ? fontFredokaBold.name : "Fredoka"
    readonly property string expressiveFont: clockFont
    readonly property int clockFontSize: Math.max(32, Math.min(Math.round(root.height * 0.48), Math.round(root.width * 0.46)))

    // ================= 4. ВЫБОР ЦВЕТА ЧАСОВ (MATERIAL YOU & PASTEL PRESETS) =================
    readonly property string colorPreset: (widgetData && widgetData.clockColor) ? widgetData.clockColor : "lavender"

    readonly property color resolvedPrimaryColor: {
        switch (colorPreset) {
            case "lavender": return "#ede8f5"
            case "monet": return root.cfg.textPrimary
            case "white": return "#ffffff"
            case "mint": return "#d1fae5"
            case "cyan": return "#e0f2fe"
            case "peach": return "#fef3c7"
            case "coral": return "#ffe4e6"
            case "violet": return "#f3e8ff"
            case "gold": return "#fef08a"
            default:
                if (colorPreset.startsWith("#")) return colorPreset
                return "#ede8f5"
        }
    }

    readonly property color resolvedSecondaryColor: {
        switch (colorPreset) {
            case "lavender": return "#e0d7f5"
            case "monet": return root.cfg.accent
            case "white": return "#d1d5db"
            case "mint": return "#6ee7b7"
            case "cyan": return "#38bdf8"
            case "peach": return "#fb923c"
            case "coral": return "#f43f5e"
            case "violet": return "#c084fc"
            case "gold": return "#eab308"
            default:
                if (colorPreset.startsWith("#")) return colorPreset
                return "#e0d7f5"
        }
    }

    radius: (widgetData && widgetData.radius !== undefined) ? widgetData.radius : (root.cfg.widgetRadius || 28)
    color: isTransparent ? "transparent" : root.cfg.surfaceContainer
    border.color: isTransparent ? "transparent" : root.cfg.outlineVariant
    border.width: isTransparent ? 0 : 1
    clip: false

    property date currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    // ==========================================
    // ВАРИАНТ 1: PIXEL СТЕК ДУЭТ (АУТЕНТИЧНЫЕ МЯГКИЕ ЧАСЫ FREDOKA BOLD)
    // ==========================================
    Item {
        id: stackedDuotoneItem
        anchors.fill: parent
        visible: root.variant === "stacked_duotone" || root.variant === "minimal"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -Math.round(root.clockFontSize * 0.16)

            // ЧАСЫ (HH)
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: hhTxt.implicitWidth
                implicitHeight: hhTxt.implicitHeight

                // Мягкая тень для парения над обоями
                Text {
                    x: 0
                    y: 3
                    text: Qt.formatDateTime(root.currentTime, "hh")
                    color: "#55000000"
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }

                Text {
                    id: hhTxt
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(root.currentTime, "hh")
                    color: isTransparent ? root.resolvedPrimaryColor : (root.colorPreset === "monet" ? root.cfg.textPrimary : root.resolvedPrimaryColor)
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }
            }

            // МИНУТЫ (MM)
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: mmTxt.implicitWidth
                implicitHeight: mmTxt.implicitHeight

                // Мягкая тень для парения над обоями
                Text {
                    x: 0
                    y: 3
                    text: Qt.formatDateTime(root.currentTime, "mm")
                    color: "#55000000"
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }

                Text {
                    id: mmTxt
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(root.currentTime, "mm")
                    color: isTransparent ? root.resolvedSecondaryColor : (root.colorPreset === "monet" ? root.cfg.accent : root.resolvedSecondaryColor)
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 2: PIXEL СТЕК МОНО (ЕДИНЫЙ МЯГКИЙ ЦВЕТ)
    // ==========================================
    Item {
        id: stackedMonoItem
        anchors.fill: parent
        visible: root.variant === "stacked_mono"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -Math.round(root.clockFontSize * 0.16)

            // ЧАСЫ (HH)
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: hhMonoTxt.implicitWidth
                implicitHeight: hhMonoTxt.implicitHeight

                Text {
                    x: 0
                    y: 3
                    text: Qt.formatDateTime(root.currentTime, "hh")
                    color: "#55000000"
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }

                Text {
                    id: hhMonoTxt
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(root.currentTime, "hh")
                    color: isTransparent ? root.resolvedPrimaryColor : (root.colorPreset === "monet" ? root.cfg.textPrimary : root.resolvedPrimaryColor)
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }
            }

            // МИНУТЫ (MM)
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: mmMonoTxt.implicitWidth
                implicitHeight: mmMonoTxt.implicitHeight

                Text {
                    x: 0
                    y: 3
                    text: Qt.formatDateTime(root.currentTime, "mm")
                    color: "#55000000"
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }

                Text {
                    id: mmMonoTxt
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(root.currentTime, "mm")
                    color: isTransparent ? root.resolvedPrimaryColor : (root.colorPreset === "monet" ? root.cfg.textPrimary : root.resolvedPrimaryColor)
                    opacity: 0.92
                    font.pixelSize: root.clockFontSize
                    font.bold: true
                    font.family: root.clockFont
                    font.letterSpacing: -1.5
                    lineHeight: 0.80
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 3: M3 EXPRESSIVE (ОРГАНИЧЕСКИЙ ТОНАЛЬНЫЙ КОНТЕЙНЕР ДЛЯ МИНУТ)
    // ==========================================
    Item {
        anchors.fill: parent
        visible: root.variant === "stacked_expressive"

        // Микро-бейджик даты в правом верхнем углу
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 14
            height: 20
            width: exprDateTxt.implicitWidth + 14
            radius: 10
            color: root.cfg.surfaceContainerHigh
            border.color: root.cfg.outlineVariant
            border.width: 1
            visible: root.height >= 120

            Text {
                id: exprDateTxt
                anchors.centerIn: parent
                text: Qt.formatDateTime(root.currentTime, "ddd • d")
                color: root.cfg.onSurfaceVariant
                font.pixelSize: 10
                font.bold: true
                font.family: root.clockFont
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(root.currentTime, "hh")
                color: root.cfg.textPrimary
                font.pixelSize: Math.max(28, Math.min(Math.round(root.height * 0.42), Math.round(root.width * 0.40)))
                font.bold: true
                font.family: root.expressiveFont
                font.letterSpacing: -1.0
                lineHeight: 0.84
            }

            // Мягкая капсула под минуты в стиле M3 tonal pill
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                height: exprMinTxt.implicitHeight + 8
                width: exprMinTxt.implicitWidth + 26
                radius: height / 2
                color: root.cfg.primaryContainer
                border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.3)
                border.width: 1

                Text {
                    id: exprMinTxt
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(root.currentTime, "mm")
                    color: root.cfg.onPrimaryContainer
                    font.pixelSize: Math.max(28, Math.min(Math.round(root.height * 0.42), Math.round(root.width * 0.40)))
                    font.bold: true
                    font.family: root.expressiveFont
                    font.letterSpacing: -1.0
                    lineHeight: 0.84
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 2: BENTO (ЧАСЫ + ДАТА + ПОГОДА)
    // ==========================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: root.size === "S" ? 10 : 16
        spacing: root.size === "S" ? 10 : 16
        visible: root.variant === "bento"

        // Левая часть: Органический Blossom / Squircle шейп с акцентной иконкой
        Item {
            Layout.preferredWidth: Math.max(36, Math.min(Math.round(root.height * 0.52), 74))
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter

            MaterialShape {
                anchors.fill: parent
                color: root.cfg.primaryContainer
                shape: root.cfg.activeShapeStyle === "blossom" ? "blossom" : "circle"
            }

            Text {
                anchors.centerIn: parent
                text: "󰥔"
                color: root.cfg.onPrimaryContainer
                font.pixelSize: Math.round(parent.width * 0.45)
            }
        }

        // Правая часть: Крупное время + Дата + Погода
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.size === "S" ? 2 : 4

            Text {
                text: Qt.formatDateTime(root.currentTime, "hh:mm")
                color: root.cfg.textPrimary
                font.pixelSize: root.size === "S" ? 26 : (root.size === "L" ? 44 : 34)
                font.bold: true
                font.family: root.cfg.fontFamily
            }

            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 12
                color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.12)
                border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.22)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 4

                    Text {
                        text: "󰸗"
                        color: root.cfg.accent
                        font.pixelSize: 11
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(root.currentTime, "d MMMM, dddd")
                        color: root.cfg.textPrimary
                        font.pixelSize: root.size === "S" ? 9 : 10
                        font.bold: true
                        font.family: root.cfg.fontFamily
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 12
                color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.12)
                border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.22)
                border.width: 1
                visible: root.size !== "S"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 4

                    Text { text: "󰖐"; color: root.cfg.accent; font.pixelSize: 11 }
                    Text {
                        Layout.fillWidth: true
                        text: root.cfg.weatherText + " • " + (root.cfg.weatherCity || "Тюмень")
                        color: root.cfg.accent
                        font.pixelSize: 10
                        font.bold: true
                        font.family: root.cfg.fontFamily
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 3: АНАЛОГОВЫЕ ЧАСЫ (PIXEL WATCH DIAL)
    // ==========================================
    Item {
        anchors.fill: parent
        visible: root.variant === "analog"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Циферблат аналоговых часов
            Item {
                Layout.preferredWidth: Math.max(50, Math.min(parent.height - 12, Math.min(parent.width * 0.45, 180)))
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter

                MaterialShape {
                    anchors.fill: parent
                    color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.14)
                    shape: root.cfg.activeShapeStyle === "blossom" ? "blossom" : "circle"
                }

                Canvas {
                    id: clockDialCanvas
                    anchors.fill: parent

                    property int hours: root.currentTime.getHours()
                    property int minutes: root.currentTime.getMinutes()
                    property int seconds: root.currentTime.getSeconds()

                    onHoursChanged: requestPaint()
                    onMinutesChanged: requestPaint()
                    onSecondsChanged: requestPaint()

                    onPaint: {
                        let ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        let cx = width / 2
                        let cy = height / 2
                        let r = Math.min(cx, cy) * 0.82

                        // Часовая стрелка (скругленная пилюля)
                        ctx.save()
                        ctx.translate(cx, cy)
                        let hrAngle = ((hours % 12) + minutes / 60) * (Math.PI / 6)
                        ctx.rotate(hrAngle)
                        ctx.beginPath()
                        ctx.moveTo(0, 4)
                        ctx.lineTo(0, -r * 0.52)
                        ctx.strokeStyle = root.cfg.textPrimary
                        ctx.lineWidth = 4.0
                        ctx.lineCap = "round"
                        ctx.stroke()
                        ctx.restore()

                        // Минутная стрелка (акцентная пилюля)
                        ctx.save()
                        ctx.translate(cx, cy)
                        let minAngle = (minutes + seconds / 60) * (Math.PI / 30)
                        ctx.rotate(minAngle)
                        ctx.beginPath()
                        ctx.moveTo(0, 6)
                        ctx.lineTo(0, -r * 0.78)
                        ctx.strokeStyle = root.cfg.accent
                        ctx.lineWidth = 3.0
                        ctx.lineCap = "round"
                        ctx.stroke()
                        ctx.restore()

                        // Секундная стрелка (тонкая игла)
                        ctx.save()
                        ctx.translate(cx, cy)
                        let secAngle = seconds * (Math.PI / 30)
                        ctx.rotate(secAngle)
                        ctx.beginPath()
                        ctx.moveTo(0, 8)
                        ctx.lineTo(0, -r * 0.88)
                        ctx.strokeStyle = root.cfg.danger
                        ctx.lineWidth = 1.4
                        ctx.lineCap = "round"
                        ctx.stroke()
                        ctx.restore()

                        // Центральная точка
                        ctx.beginPath()
                        ctx.arc(cx, cy, 3.8, 0, 2 * Math.PI)
                        ctx.fillStyle = root.cfg.accent
                        ctx.fill()
                    }
                }
            }

            // Правая часть: цифровое время и дата в M3 капсулах
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Text {
                    text: Qt.formatDateTime(root.currentTime, "hh:mm")
                    color: root.cfg.textPrimary
                    font.pixelSize: root.size === "S" ? 22 : 28
                    font.bold: true
                    font.family: root.cfg.fontFamily
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 12
                    color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.12)
                    border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.22)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 4

                        Text { text: "󰸗"; color: root.cfg.accent; font.pixelSize: 11 }
                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(root.currentTime, "d MMMM")
                            color: root.cfg.textPrimary
                            font.pixelSize: 10
                            font.bold: true
                            font.family: root.cfg.fontFamily
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    text: Qt.formatDateTime(root.currentTime, "dddd")
                    color: root.cfg.onSurfaceVariant
                    font.pixelSize: 10
                    font.family: root.cfg.fontFamily
                    Layout.leftMargin: 4
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 4: PILL HORIZONTAL (ШИРОКАЯ ЭЛЕГАНТНАЯ КАПСУЛА С FREDOKA BOLD)
    // ==========================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14
        visible: root.variant === "pill_horizontal"

        // Время в одну строку крупным Fredoka-Bold
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: Qt.formatDateTime(root.currentTime, "hh")
                color: root.resolvedPrimaryColor
                font.pixelSize: Math.max(28, Math.min(Math.round(root.height * 0.58), 64))
                font.bold: true
                font.family: root.clockFont
                font.letterSpacing: -1.0
            }

            Text {
                text: ":"
                color: root.resolvedSecondaryColor
                font.pixelSize: Math.max(26, Math.min(Math.round(root.height * 0.52), 58))
                font.bold: true
                font.family: root.clockFont
                opacity: (root.currentTime.getSeconds() % 2 === 0) ? 1.0 : 0.4
            }

            Text {
                text: Qt.formatDateTime(root.currentTime, "mm")
                color: root.resolvedSecondaryColor
                font.pixelSize: Math.max(28, Math.min(Math.round(root.height * 0.58), 64))
                font.bold: true
                font.family: root.clockFont
                font.letterSpacing: -1.0
            }
        }

        // Вертикальный мягкий разделитель
        Rectangle {
            Layout.preferredWidth: 2
            Layout.preferredHeight: Math.round(parent.height * 0.6)
            Layout.alignment: Qt.AlignVCenter
            radius: 1
            color: root.cfg.outlineVariant
            opacity: 0.5
        }

        // Правая колонка: День недели, Дата и Погода в капсулах
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                text: Qt.formatDateTime(root.currentTime, "dddd, d MMMM")
                color: root.cfg.textPrimary
                font.pixelSize: 11
                font.bold: true
                font.family: root.cfg.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                height: 22
                Layout.fillWidth: true
                radius: 11
                color: Qt.rgba(root.resolvedSecondaryColor.r, root.resolvedSecondaryColor.g, root.resolvedSecondaryColor.b, 0.14)
                border.color: Qt.rgba(root.resolvedSecondaryColor.r, root.resolvedSecondaryColor.g, root.resolvedSecondaryColor.b, 0.25)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "󰖐"; color: root.resolvedSecondaryColor; font.pixelSize: 11 }
                    Text {
                        text: (root.cfg.weatherText || "+18°") + " • " + (root.cfg.weatherCity || "Тюмень")
                        color: root.resolvedSecondaryColor
                        font.pixelSize: 10
                        font.bold: true
                        font.family: root.cfg.fontFamily
                    }
                }
            }
        }
    }
}
