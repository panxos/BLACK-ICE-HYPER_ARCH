import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control
    property color accent: "#27c6ed"
    property color foreground: "#e6edf3"
    implicitHeight: 42
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.45
    contentItem: Text {
        text: control.text
        color: control.highlighted ? control.accent : control.foreground
        font.family: "Noto Sans"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: AngularPanel {
        fill: control.down ? "#303e4d" : control.hovered ? "#1c2a36" : "#e60c1118"
        stroke: control.activeFocus || control.highlighted || control.hovered ? control.accent : "#536a78"
        lineWidth: control.activeFocus ? 2 : 1
        cut: 10
    }
}
