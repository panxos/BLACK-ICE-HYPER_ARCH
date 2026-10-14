import QtQuick 2.15
import QtQuick.Shapes 1.15

Shape {
    id: panel
    property color fill: "#e60c1118"
    property color stroke: "#536a78"
    property real cut: 10
    property real lineWidth: 1
    antialiasing: true
    ShapePath {
        strokeColor: panel.stroke
        strokeWidth: panel.lineWidth
        fillColor: panel.fill
        joinStyle: ShapePath.MiterJoin
        startX: panel.cut
        startY: 1
        PathLine { x: panel.width - 1; y: 1 }
        PathLine { x: panel.width - 1; y: panel.height - panel.cut }
        PathLine { x: panel.width - panel.cut; y: panel.height - 1 }
        PathLine { x: 1; y: panel.height - 1 }
        PathLine { x: 1; y: panel.cut }
        PathLine { x: panel.cut; y: 1 }
    }
}
