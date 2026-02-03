import QtQuick 2.0
import QtQuick.Controls 2.0

Button {
    id: control
    property color glowColor: config.accentColor
    
    contentItem: Text {
        text: control.text
        font.family: config.fontName
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? "#000000" : control.glowColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 40
        color: control.down ? control.glowColor : "transparent"
        border.color: control.glowColor
        border.width: 1
        
        Rectangle {
            anchors.fill: parent
            color: control.glowColor
            opacity: control.hovered && !control.down ? 0.1 : 0
        }
    }
}
