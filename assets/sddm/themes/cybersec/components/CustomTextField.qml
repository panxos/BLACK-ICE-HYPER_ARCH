import QtQuick 2.0
import QtQuick.Controls 2.0
import QtGraphicalEffects 1.0

TextField {
    id: control
    
    placeholderTextColor: "#555555"
    color: config.accentColor
    font.family: config.fontName
    font.pixelSize: 14
    
    background: Rectangle {
        color: "transparent"
        border.color: "transparent"
        
        Rectangle {
            width: parent.width
            height: 1
            color: control.activeFocus ? config.accentColor : "#333333"
            anchors.bottom: parent.bottom
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        
        // Glitch element on focus
        Rectangle {
            visible: control.activeFocus
            width: 10
            height: 2
            color: config.secondaryColor
            anchors.bottom: parent.bottom
            x: parent.width
            
            NumberAnimation on x {
                from: 0; to: control.width
                duration: 1000
                loops: Animation.Infinite
                running: control.activeFocus
            }
        }
    }
}
