import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
    id: control
    property color accent: "#27c6ed"
    property color foreground: "#e6edf3"
    implicitHeight: 36
    implicitWidth: 140
    leftPadding: 12
    rightPadding: 28
    palette {
        window: "#0c1118"
        windowText: control.foreground
        base: "#0c1118"
        text: control.foreground
        button: "#101923"
        buttonText: control.foreground
        highlight: control.accent
        highlightedText: "#080d13"
        mid: "#536a78"
        light: "#536a78"
        dark: "#080d13"
    }
    background: AngularPanel {
        stroke: control.activeFocus ? control.accent : "#536a78"
        fill: "#ed0c1118"
        cut: 8
    }
}
