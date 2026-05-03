import QtQuick 2.0

Item {
    id: root
    anchors.fill: parent

    // Main Asset-based background
    Image {
        id: bgImage
        anchors.fill: parent
        source: "assets/background.png
        fillMode: Image.PreserveAspectCrop
        mipmap: true
    }

    // Darkening / Tech Overlay
    Rectangle {
        anchors.fill: parent
        color: "#aa000000
        opacity: 0.4
    }

    // Subtle Grid Overlay (Integrated with asset)
    Grid {
        anchors.fill: parent
        columns: parent.width / 80
        rows: parent.height / 80
        spacing: 0
        opacity: 0.1
        Repeater {
            model: (parent.width / 80) * (parent.height / 80)
            Rectangle {
                width: 80; height: 80
                color: "transparent
                border.color: "#00f3ff
                border.width: 1
            }
        }
    }
}
