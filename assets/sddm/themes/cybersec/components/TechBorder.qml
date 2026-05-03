import QtQuick 2.0

Item {
    id: root
    property color borderColor: "#00f3ff"
    property real borderWidth: 1
    property real glowRadius: 10
    
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: root.borderColor
        border.width: root.borderWidth
        opacity: 0.8
        
        Rectangle { width: 12; height: 2; color: root.borderColor; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 2; height: 12; color: root.borderColor; anchors.top: parent.top; anchors.left: parent.left }
        
        Rectangle { width: 12; height: 2; color: root.borderColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
        Rectangle { width: 2; height: 12; color: root.borderColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
    }
}
