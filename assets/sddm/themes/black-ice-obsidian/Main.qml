import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"

Rectangle {
    id: root
    width: 1366
    height: 768
    color: "#080d13"
    property color accent: config.accent || "#27c6ed"
    property color foreground: config.foreground || "#e6edf3"
    property color muted: config.muted || "#a4b5c2"
    property bool compact: width < 1000 || width < height
    property bool busy: false
    property string message: ""
    property string pendingAction: ""
    property string interfaceLanguage: config.language || "es"
    readonly property real unit: Math.max(0.68, Math.min(width / 1366, height / 768, 1.6))

    FontLoader { source: "assets/Rajdhani-Medium.ttf" }
    FontLoader { source: "assets/Rajdhani-SemiBold.ttf" }
    FontLoader { source: config.bodyFontFile || "" }

    function tr(spanish, english) {
        return interfaceLanguage === "en" ? english : spanish;
    }

    function login() {
        var username = users.editText.trim();
        if (busy || !username || !password.text) {
            password.forceActiveFocus();
            return;
        }
        busy = true;
        message = tr("Verificando…", "Verifying…");
        sddm.login(username, password.text, Math.max(0, sessions.currentIndex));
    }
    function finishPower() {
        var action = pendingAction;
        pendingAction = "";
        if (action === "reboot" && sddm.canReboot) sddm.reboot();
        if (action === "off" && sddm.canPowerOff) sddm.powerOff();
    }

    AdaptiveBackground {
        anchors.fill: parent
        background: Qt.resolvedUrl(config.background || "assets/wallpaper.png")
        panorama: config.backgroundPanorama ? Qt.resolvedUrl(config.backgroundPanorama) : ""
        mode: config.backgroundMode || "auto"
        anchor: config.backgroundAnchor || "center"
    }
    Rectangle {
        anchors.fill: parent
        color: "#18040a10"
    }
    Rectangle {
        width: root.compact ? parent.width : parent.width * 0.52
        height: parent.height
        color: root.compact ? "#68080d13" : "#88080d13"
    }

    Item {
        id: form
        width: Math.min(root.width - 48, 330 * root.unit)
        height: Math.min(root.height - 110, fields.implicitHeight)
        x: root.compact ? (root.width - width) / 2 : root.width * 0.065
        anchors.verticalCenter: parent.verticalCenter

        ColumnLayout {
            id: fields
            width: parent.width
            spacing: 14 * root.unit

            Text {
                Layout.fillWidth: true
                text: config.title || "BLACK-ICE"
                color: root.foreground
                font.family: config.font || "Rajdhani"
                font.weight: Font.DemiBold
                font.pixelSize: 48 * root.unit
                font.letterSpacing: 5 * root.unit
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                Layout.topMargin: -15 * root.unit
                text: config.subtitle || "ARCH"
                color: root.accent
                font.family: config.font || "Rajdhani"
                font.pixelSize: 18 * root.unit
                font.letterSpacing: 8 * root.unit
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 12 * root.unit
                text: root.tr("Iniciar sesión", "Sign in")
                color: root.muted
                font.family: config.bodyFont || "Roboto"
                font.pixelSize: 14 * root.unit
                horizontalAlignment: Text.AlignHCenter
            }
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 78 * root.unit
                Layout.preferredHeight: 78 * root.unit
                visible: config.showAvatar !== "false"
                AngularPanel {
                    anchors.fill: parent
                    stroke: root.accent
                    fill: "#e60c1118"
                    cut: 12
                }
                Text {
                    anchors.centerIn: parent
                    text: users.editText ? users.editText.charAt(0).toUpperCase() : ""
                    font.family: config.font || "Rajdhani"
                    font.pixelSize: 40 * root.unit
                    color: root.accent
                    visible: face.status !== Image.Ready
                }
                Image {
                    id: face
                    anchors.fill: parent
                    anchors.margins: 8
                    source: users.editText === users.currentText ? (users.currentValue || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
            }
            AngularCombo {
                id: users
                accent: root.accent
                foreground: root.foreground
                Layout.fillWidth: true
                Layout.preferredHeight: 40 * root.unit
                model: userModel
                textRole: "name"
                valueRole: "icon"
                currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                editable: true
                enabled: !root.busy
                font.family: config.bodyFont || "Roboto"
                font.pixelSize: 14 * root.unit
                onAccepted: password.forceActiveFocus()
                Accessible.name: root.tr("Usuario", "User")
            }
            TextField {
                id: password
                Layout.fillWidth: true
                Layout.preferredHeight: 46 * root.unit
                font.family: config.bodyFont || "Roboto"
                font.pixelSize: 15 * root.unit
                color: root.foreground
                placeholderText: root.tr("Contraseña", "Password")
                placeholderTextColor: root.muted
                echoMode: TextInput.Password
                selectByMouse: true
                leftPadding: 16
                rightPadding: 16
                enabled: !root.busy
                Accessible.name: root.tr("Contraseña", "Password")
                background: AngularPanel {
                    fill: "#ed0c1118"
                    stroke: password.activeFocus ? root.accent : "#536a78"
                    lineWidth: password.activeFocus ? 2 : 1
                }
                onAccepted: root.login()
            }
            Text {
                Layout.fillWidth: true
                text: keyboard.capsLock ? root.tr("Bloq Mayús activado", "Caps Lock is on") : root.message
                color: keyboard.capsLock || !root.busy ? "#ffbd88" : root.muted
                font.family: config.bodyFont || "Roboto"
                font.pixelSize: 12 * root.unit
                wrapMode: Text.WordWrap
                Layout.minimumHeight: 18 * root.unit
                horizontalAlignment: Text.AlignHCenter
                Accessible.role: Accessible.AlertMessage
            }
            ActionButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 44 * root.unit
                text: root.busy ? root.tr("Verificando…", "Verifying…") : root.tr("Entrar", "Sign in")
                highlighted: true
                accent: root.accent
                enabled: !root.busy
                onClicked: root.login()
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: 36 * root.unit
                spacing: 10
                AngularCombo {
                    id: sessions
                    accent: root.accent
                    foreground: root.foreground
                    Layout.fillWidth: true
                    Layout.preferredWidth: 170 * root.unit
                    Layout.preferredHeight: 36 * root.unit
                    model: sessionModel
                    textRole: "name"
                    currentIndex: Math.max(0, sessionModel.lastIndex)
                    enabled: !root.busy
                    font.pixelSize: 12 * root.unit
                    Accessible.name: root.tr("Sesión de escritorio", "Desktop session")
                }
                AngularCombo {
                    accent: root.accent
                    foreground: root.foreground
                    Layout.preferredWidth: 120 * root.unit
                    Layout.preferredHeight: 36 * root.unit
                    model: keyboard.layouts
                    textRole: "shortName"
                    displayText: currentText || root.tr("Teclado", "Keyboard")
                    currentIndex: keyboard.currentLayout
                    enabled: !root.busy && count > 0
                    font.pixelSize: 12 * root.unit
                    Accessible.name: root.tr("Distribución de teclado", "Keyboard layout")
                    onActivated: keyboard.currentLayout = currentIndex
                }
            }
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 28 * root.unit
        AngularCombo {
            accent: root.accent
            foreground: root.foreground
            implicitWidth: 140 * root.unit
            implicitHeight: 36 * root.unit
            model: ["Español", "English"]
            currentIndex: root.interfaceLanguage === "en" ? 1 : 0
            enabled: !root.busy
            Accessible.name: root.tr("Idioma", "Language")
            onActivated: root.interfaceLanguage = currentIndex === 1 ? "en" : "es"
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 28 * root.unit
        spacing: 12
        ActionButton {
            text: root.tr("Reiniciar", "Restart")
            implicitWidth: 100 * root.unit
            accent: root.accent
            visible: sddm.canReboot
            enabled: !root.busy
            onClicked: root.pendingAction = "reboot"
        }
        ActionButton {
            text: root.tr("Apagar", "Power off")
            implicitWidth: 100 * root.unit
            accent: root.accent
            visible: sddm.canPowerOff
            enabled: !root.busy
            onClicked: root.pendingAction = "off"
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: root.pendingAction !== ""
        color: "#dc080d13"
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(380, root.width - 48)
            spacing: 20
            Text {
                Layout.fillWidth: true
                text: root.pendingAction === "off" ? root.tr("¿Apagar el equipo?", "Power off this computer?") : root.tr("¿Reiniciar el equipo?", "Restart this computer?")
                color: root.foreground
                font.family: config.font || "Rajdhani"
                font.pixelSize: 28
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            ActionButton {
                Layout.fillWidth: true
                text: root.tr("Cancelar", "Cancel")
                accent: root.accent
                onClicked: { root.pendingAction = ""; password.forceActiveFocus(); }
            }
            ActionButton {
                Layout.fillWidth: true
                text: root.tr("Confirmar", "Confirm")
                highlighted: true
                accent: root.accent
                onClicked: root.finishPower()
            }
        }
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.message = root.tr("No se pudo iniciar sesión. Revisa tus datos.", "Could not sign in. Check your details.");
            password.text = "";
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { password.text = ""; }
    }
    Component.onCompleted: password.forceActiveFocus()
    Keys.onEscapePressed: { root.pendingAction = ""; password.text = ""; password.forceActiveFocus(); }
}
