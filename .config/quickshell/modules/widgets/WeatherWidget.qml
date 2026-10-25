import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    required property var cfg
    property var widgetData: ({})

    readonly property string variant: (widgetData && widgetData.variant) ? widgetData.variant : "forecast"
    readonly property string size: (widgetData && widgetData.size) ? widgetData.size : "M"

    radius: (widgetData && widgetData.radius !== undefined) ? widgetData.radius : (root.cfg.widgetRadius || 28)
    color: root.cfg.surfaceContainer
    border.color: root.cfg.outlineVariant
    border.width: 1
    clip: true

    // ==========================================
    // ВАРИАНТ 1: FORECAST (ПРОГНОЗ И ПОДРОБНОСТИ) В СТИЛЕ PIXEL AT A GLANCE
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.size === "S" ? 12 : 16
        spacing: 8
        visible: root.variant === "forecast"

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: root.size === "S" ? 40 : 46
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter
                radius: 14
                color: root.cfg.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: "󰖐"
                    color: root.cfg.onPrimaryContainer
                    font.pixelSize: root.size === "S" ? 22 : 26
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.cfg.weatherText
                    color: root.cfg.textPrimary
                    font.pixelSize: root.size === "S" ? 22 : 28
                    font.bold: true
                    font.family: root.cfg.fontFamily
                }

                Rectangle {
                    height: 20
                    width: cityBadgeText.implicitWidth + 14
                    radius: 10
                    color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.12)
                    border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.22)
                    border.width: 1

                    Text {
                        id: cityBadgeText
                        anchors.centerIn: parent
                        text: root.cfg.weatherCity || "Тюмень"
                        color: root.cfg.accent
                        font.pixelSize: 10
                        font.bold: true
                        font.family: root.cfg.fontFamily
                    }
                }
            }
        }

        // Мини-прогноз на день: мягкие горизонтальные капсулы
        RowLayout {
            Layout.fillWidth: true
            visible: root.size !== "S"
            spacing: 6

            Repeater {
                model: [
                    { time: "Утро", temp: "+12°", icon: "󰖙" },
                    { time: "День", temp: "+18°", icon: "󰖐" },
                    { time: "Вечер", temp: "+14°", icon: "󰼱" }
                ]

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 32
                    radius: 12
                    color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.10)
                    border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.18)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: modelData.icon; color: root.cfg.accent; font.pixelSize: 11 }
                        Text { text: modelData.time + ":"; color: root.cfg.onSurfaceVariant; font.pixelSize: 9 }
                        Text { text: modelData.temp; color: root.cfg.textPrimary; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 2: COMPACT (МИНИМАЛИСТИЧНЫЙ ВИДЖЕТ)
    // ==========================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14
        visible: root.variant === "compact"

        Rectangle {
            Layout.preferredWidth: root.size === "S" ? 44 : 54
            Layout.preferredHeight: Layout.preferredWidth
            radius: Layout.preferredWidth / 2
            color: root.cfg.primaryContainer

            Text {
                anchors.centerIn: parent
                text: "󰖐"
                color: root.cfg.onPrimaryContainer
                font.pixelSize: root.size === "S" ? 24 : 30
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: root.cfg.weatherText
                color: root.cfg.textPrimary
                font.pixelSize: root.size === "S" ? 28 : (root.size === "L" ? 44 : 34)
                font.bold: true
                font.family: root.cfg.fontFamily
            }

            Rectangle {
                height: 22
                width: cityCompactText.implicitWidth + 14
                radius: 11
                color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.12)
                border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.22)
                border.width: 1

                Text {
                    id: cityCompactText
                    anchors.centerIn: parent
                    text: root.cfg.weatherCity || "Тюмень"
                    color: root.cfg.accent
                    font.pixelSize: 10
                    font.bold: true
                    font.family: root.cfg.fontFamily
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 3: DETAILED (ПОЛНАЯ МЕТЕОСВОДКА С ДАТЧИКАМИ)
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.size === "S" ? 12 : 16
        spacing: 8
        visible: root.variant === "detailed"

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: 16
                color: root.cfg.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: "󰖐"
                    color: root.cfg.onPrimaryContainer
                    font.pixelSize: 26
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    spacing: 8
                    Text {
                        text: root.cfg.weatherText
                        color: root.cfg.textPrimary
                        font.pixelSize: 26
                        font.bold: true
                        font.family: root.cfg.fontFamily
                    }

                    Rectangle {
                        height: 20
                        implicitWidth: detCityTxt.implicitWidth + 12
                        radius: 10
                        color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.12)
                        border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.25)
                        border.width: 1
                        Text {
                            id: detCityTxt
                            anchors.centerIn: parent
                            text: root.cfg.weatherCity || "Тюмень"
                            color: root.cfg.accent
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Text {
                    text: (root.cfg.weatherDesc || "Ясно") + " • Ощущается как " + root.cfg.weatherText
                    color: root.cfg.onSurfaceVariant
                    font.pixelSize: 10
                    font.family: root.cfg.fontFamily
                }
            }
        }

        // Капсулы показателей (Влажность, Ветер, Давление)
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 12
                color: root.cfg.surfaceContainerHigh
                border.color: root.cfg.outlineVariant
                border.width: 1
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "󰖌"; color: root.cfg.accent; font.pixelSize: 10 }
                    Text { text: "72%"; color: root.cfg.textPrimary; font.pixelSize: 9; font.bold: true }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 12
                color: root.cfg.surfaceContainerHigh
                border.color: root.cfg.outlineVariant
                border.width: 1
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "󰖝"; color: root.cfg.accent; font.pixelSize: 10 }
                    Text { text: "3.8 м/с"; color: root.cfg.textPrimary; font.pixelSize: 9; font.bold: true }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 12
                color: root.cfg.surfaceContainerHigh
                border.color: root.cfg.outlineVariant
                border.width: 1
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "󰍛"; color: root.cfg.accent; font.pixelSize: 10 }
                    Text { text: "755 мм"; color: root.cfg.textPrimary; font.pixelSize: 9; font.bold: true }
                }
            }
        }
    }

    // ==========================================
    // ВАРИАНТ 4: PILL STRIP (ГОРИЗОНТАЛЬНАЯ СТРИП-ПИЛЮЛЯ)
    // ==========================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        visible: root.variant === "pill_strip"

        Rectangle {
            Layout.preferredWidth: Math.min(parent.height - 16, 52)
            Layout.preferredHeight: Layout.preferredWidth
            radius: Layout.preferredWidth / 2
            color: root.cfg.primaryContainer

            Text {
                anchors.centerIn: parent
                text: "󰖐"
                color: root.cfg.onPrimaryContainer
                font.pixelSize: Math.round(parent.width * 0.5)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                spacing: 8
                Text {
                    text: root.cfg.weatherText
                    color: root.cfg.textPrimary
                    font.pixelSize: root.size === "S" ? 22 : 30
                    font.bold: true
                    font.family: root.cfg.fontFamily
                }

                Rectangle {
                    height: 22
                    implicitWidth: psBadgeTxt.implicitWidth + 12
                    radius: 11
                    color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.12)
                    border.color: Qt.rgba(root.cfg.accent.r, root.cfg.accent.g, root.cfg.accent.b, 0.25)
                    border.width: 1
                    Text {
                        id: psBadgeTxt
                        anchors.centerIn: parent
                        text: "Комфортно"
                        color: root.cfg.accent
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            Text {
                text: (root.cfg.weatherCity || "Тюмень") + " • Облачно с прояснениями"
                color: root.cfg.onSurfaceVariant
                font.pixelSize: 10
                font.family: root.cfg.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
