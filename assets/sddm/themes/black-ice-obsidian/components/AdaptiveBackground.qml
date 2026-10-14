import QtQuick 2.15
import QtQuick.Window 2.15
import "WallpaperGeometry.js" as Geometry

Item {
    id: root
    clip: true
    property url background
    property url panorama
    property string mode: "auto"
    property string anchor: "center"
    property var screens: Qt.application.screens
    property string outputName: Screen.name
    readonly property var viewport: Geometry.region(screens, outputName, mode, panorama.toString().length > 0)
    readonly property bool spanning: viewport.canvasWidth > viewport.width || viewport.canvasHeight > viewport.height

    Image {
        id: wallpaper
        objectName: "adaptiveWallpaper"
        source: root.viewport.panorama ? root.panorama : root.background
        readonly property real cover: Math.max(root.viewport.canvasWidth / Math.max(1, sourceSize.width),
                                               root.viewport.canvasHeight / Math.max(1, sourceSize.height))
        readonly property real scaleX: root.width / root.viewport.width
        readonly property real scaleY: root.height / root.viewport.height
        width: sourceSize.width * cover * scaleX
        height: sourceSize.height * cover * scaleY
        x: -(root.viewport.x + (sourceSize.width * cover - root.viewport.canvasWidth) / 2) * scaleX
        y: -(root.viewport.y + (root.anchor === "top" && root.spanning ? 0
             : (sourceSize.height * cover - root.viewport.canvasHeight) / 2)) * scaleY
        fillMode: Image.Stretch
        asynchronous: true
        cache: true
    }
}
