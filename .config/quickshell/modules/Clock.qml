import QtQuick

Text {
    id: clockText
    color: "#e1e2e8"
    font.pixelSize: 14
    font.bold: true

    function update() {
        clockText.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
    }

    Component.onCompleted: update()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.update()
    }
}
