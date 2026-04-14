import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: "#02060a"

    // ═══════════════════════════════════════════════════════════
    //  LAYER 0 — Background image
    // ═══════════════════════════════════════════════════════════
    Image {
        id: bgImage
        anchors.fill: parent
        source: "assets/background.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.35
    }

    // ═══════════════════════════════════════════════════════════
    //  LAYER 1 — Matrix Digital Rain (Canvas)
    // ═══════════════════════════════════════════════════════════
    Canvas {
        id: matrixCanvas
        anchors.fill: parent
        opacity: 0.55

        property var cols: []
        property var drops: []
        property var speeds: []
        property var chars: "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF░▒▓█▄▀"
        property int fontSize: 14
        property int numCols: Math.floor(width / fontSize)

        Component.onCompleted: {
            for (var i = 0; i < numCols; i++) {
                drops[i] = Math.random() * -100
                speeds[i] = 0.3 + Math.random() * 0.7
                cols[i] = Math.floor(Math.random() * 3)  // 0=cyan, 1=purple, 2=dim
            }
            matrixTimer.start()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "rgba(2, 6, 10, 0.08)"
            ctx.fillRect(0, 0, width, height)

            for (var i = 0; i < numCols; i++) {
                var x = i * fontSize
                var y = drops[i] * fontSize
                var char_idx = Math.floor(Math.random() * chars.length)
                var c = chars[char_idx]

                // Lead character — bright
                if (cols[i] === 0) {
                    ctx.fillStyle = drops[i] > 2 ? "rgba(0,243,255,0.9)" : "rgba(180,255,255,1.0)"
                } else if (cols[i] === 1) {
                    ctx.fillStyle = drops[i] > 2 ? "rgba(176,38,255,0.8)" : "rgba(220,150,255,1.0)"
                } else {
                    ctx.fillStyle = drops[i] > 2 ? "rgba(0,243,255,0.35)" : "rgba(0,200,180,0.6)"
                }

                ctx.font = fontSize + "px 'JetBrains Mono'"
                ctx.fillText(c, x, y)

                // Trail fade — a few chars behind
                for (var t = 1; t < 4; t++) {
                    var ty = (drops[i] - t) * fontSize
                    if (ty > 0) {
                        var alpha = (0.5 - t * 0.1)
                        if (cols[i] === 0) ctx.fillStyle = "rgba(0,243,255," + alpha + ")"
                        else if (cols[i] === 1) ctx.fillStyle = "rgba(176,38,255," + alpha + ")"
                        else ctx.fillStyle = "rgba(0,200,150," + (alpha * 0.5) + ")"
                        ctx.fillText(chars[Math.floor(Math.random() * chars.length)], x, ty)
                    }
                }

                drops[i] += speeds[i]
                if (drops[i] * fontSize > height && Math.random() > 0.975) {
                    drops[i] = 0
                    speeds[i] = 0.3 + Math.random() * 0.7
                    cols[i] = Math.floor(Math.random() * 3)
                }
            }
        }

        Timer {
            id: matrixTimer
            interval: 45
            running: false
            repeat: true
            onTriggered: matrixCanvas.requestPaint()
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  LAYER 2 — CRT Scanlines overlay
    // ═══════════════════════════════════════════════════════════
    Canvas {
        anchors.fill: parent
        opacity: 0.07

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "rgba(0,0,0,1)"
            for (var y = 0; y < height; y += 3) {
                ctx.fillRect(0, y, width, 1)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  LAYER 3 — Vignette corners
    // ═══════════════════════════════════════════════════════════
    Canvas {
        anchors.fill: parent
        opacity: 0.7
        Component.onCompleted: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            var grad = ctx.createRadialGradient(width/2, height/2, height*0.3, width/2, height/2, height*0.9)
            grad.addColorStop(0, "rgba(0,0,0,0)")
            grad.addColorStop(1, "rgba(0,0,0,0.85)")
            ctx.fillStyle = grad
            ctx.fillRect(0, 0, width, height)
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  TOP HEADER BAR
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        id: topBar
        anchors.top: parent.top
        width: parent.width
        height: 52
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#08000a0f"
        }

        // Top border glow line
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#00f3ff"
            opacity: glowAnim.opacity
            SequentialAnimation on opacity {
                id: glowAnim
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.3; duration: 1800; easing.type: Easing.InOutSine }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 32

            // Left: status indicators
            Row {
                spacing: 20
                Text {
                    text: "■ BLACKICE_OS"
                    color: "#00f3ff"
                    font.pixelSize: 12
                    font.family: "JetBrains Mono"
                    font.letterSpacing: 1.5
                    SequentialAnimation on opacity {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { to: 1.0; duration: 900 }
                        NumberAnimation { to: 0.5; duration: 900 }
                    }
                }
                Text {
                    text: "// HYPRLAND"
                    color: "#bc00ff"
                    font.pixelSize: 12
                    font.family: "JetBrains Mono"
                    font.letterSpacing: 1
                }
                Text {
                    text: "// ARCH_LINUX"
                    color: "#6272a4"
                    font.pixelSize: 12
                    font.family: "JetBrains Mono"
                    font.letterSpacing: 1
                }
            }

            Item { Layout.fillWidth: true }

            // Center: scrolling status message
            Text {
                id: statusMsg
                color: "#4400f3ff"
                font.pixelSize: 11
                font.family: "JetBrains Mono"
                property var messages: [
                    "INTRUSION DETECTION ACTIVE",
                    "FIREWALL: BLOCKING EXTERNAL TRAFFIC",
                    "ENCRYPTION LAYER: OPERATIONAL",
                    "KERNEL INTEGRITY: VERIFIED",
                    "SECURE BOOT: ENFORCED",
                    "ALL CONNECTIONS MONITORED",
                    "AUDIT LOG: RECORDING"
                ]
                property int msgIdx: 0
                text: "[ " + messages[msgIdx] + " ]"
                Timer {
                    interval: 3500; running: true; repeat: true
                    onTriggered: {
                        fadeOut.start()
                    }
                }
                SequentialAnimation {
                    id: fadeOut
                    NumberAnimation { target: statusMsg; property: "opacity"; to: 0; duration: 300 }
                    ScriptAction { script: { statusMsg.msgIdx = (statusMsg.msgIdx + 1) % statusMsg.messages.length } }
                    NumberAnimation { target: statusMsg; property: "opacity"; to: 1; duration: 300 }
                }
            }

            Item { Layout.fillWidth: true }

            // Right: clock
            Text {
                id: topClock
                color: "#00f3ff"
                font.pixelSize: 22
                font.bold: true
                font.family: "JetBrains Mono"
                text: Qt.formatTime(new Date(), "hh:mm:ss")
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  CENTRAL LOGIN CARD
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        width: 500
        height: 600
        color: "#e600060e"
        radius: 2

        // Animated border via sequential color shift
        border.color: cardBorderAnim.running ? "#00f3ff" : "#bc00ff"
        border.width: 1

        SequentialAnimation {
            id: cardBorderAnim
            running: true; loops: Animation.Infinite
            ColorAnimation { target: loginCard; property: "border.color"; to: "#bc00ff"; duration: 2000 }
            ColorAnimation { target: loginCard; property: "border.color"; to: "#00f3ff"; duration: 2000 }
        }

        // Corner brackets — animated scale
        property real cornerScale: 1.0
        SequentialAnimation on cornerScale {
            running: true; loops: Animation.Infinite
            NumberAnimation { to: 1.08; duration: 1200; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
        }

        // TL corner
        Item {
            x: -2; y: -2
            transform: Scale { origin.x: 0; origin.y: 0; xScale: loginCard.cornerScale; yScale: loginCard.cornerScale }
            Rectangle { width: 24; height: 3; color: "#00f3ff" }
            Rectangle { width: 3; height: 24; color: "#00f3ff" }
        }
        // TR corner
        Item {
            x: loginCard.width - 22; y: -2
            transform: Scale { origin.x: 22; origin.y: 0; xScale: loginCard.cornerScale; yScale: loginCard.cornerScale }
            Rectangle { width: 24; height: 3; color: "#00f3ff" }
            Rectangle { x: 21; width: 3; height: 24; color: "#00f3ff" }
        }
        // BL corner
        Item {
            x: -2; y: loginCard.height - 22
            transform: Scale { origin.x: 0; origin.y: 22; xScale: loginCard.cornerScale; yScale: loginCard.cornerScale }
            Rectangle { y: 21; width: 24; height: 3; color: "#00f3ff" }
            Rectangle { width: 3; height: 24; color: "#00f3ff" }
        }
        // BR corner
        Item {
            x: loginCard.width - 22; y: loginCard.height - 22
            transform: Scale { origin.x: 22; origin.y: 22; xScale: loginCard.cornerScale; yScale: loginCard.cornerScale }
            Rectangle { y: 21; width: 24; height: 3; color: "#00f3ff" }
            Rectangle { x: 21; width: 3; height: 24; color: "#00f3ff" }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width * 0.84
            spacing: 18

            // Header label
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "⬡ SYSTEM IDENTITY REQUIRED ⬡"
                color: "#00f3ff"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2
                font.family: "JetBrains Mono"
                opacity: headerPulse.opacity
                SequentialAnimation on opacity {
                    id: headerPulse
                    running: true; loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 1000 }
                    NumberAnimation { to: 0.5; duration: 1000 }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: "#1a00f3ff"
            }

            // Avatar circle
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 100; height: 100; radius: 50
                color: "transparent"
                border.color: "#bc00ff"
                border.width: 2

                // Outer ring pulse
                Rectangle {
                    anchors.centerIn: parent
                    width: 110; height: 110; radius: 55
                    color: "transparent"
                    border.color: "#3300f3ff"
                    border.width: 1
                    SequentialAnimation on scale {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { to: 1.12; duration: 1500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                    }
                }

                Image {
                    anchors.fill: parent; anchors.margins: 3
                    source: {
                        if (userModel.lastUser)
                            return "file:///var/lib/AccountsService/icons/" + userModel.lastUser
                        return "assets/avatar.png"
                    }
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    // Circular clip via radius
                    onStatusChanged: {
                        if (status === Image.Error) {
                            if (source.toString().indexOf("AccountsService") !== -1 && userModel.lastUser)
                                source = "file:///home/" + userModel.lastUser + "/.face.icon"
                            else
                                source = "assets/avatar.png"
                        }
                    }
                }
            }

            // Username display
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: (userModel.lastUser || "USER").toUpperCase()
                color: "#e0e0e0"
                font.pixelSize: 22
                font.family: "JetBrains Mono"
                font.bold: true
            }

            // Typing animation text
            Text {
                id: typingLabel
                Layout.alignment: Qt.AlignHCenter
                color: "#2200f3ff"
                font.pixelSize: 10
                font.family: "JetBrains Mono"
                property var prompts: [
                    "SCANNING BIOMETRIC_DATA...",
                    "VERIFYING NEURAL_PATTERN...",
                    "CHECKING CLEARANCE_LEVEL...",
                    "LOADING IDENTITY_MATRIX...",
                    "AUTHENTICATING SESSION..."
                ]
                property int idx: 0
                text: prompts[idx]
                Timer {
                    interval: 2200; running: true; repeat: true
                    onTriggered: { typingLabel.idx = (typingLabel.idx + 1) % typingLabel.prompts.length }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: "#1a00f3ff"
            }

            // Username field
            TextField {
                id: usernameField
                Layout.fillWidth: true
                placeholderText: "USER_IDENTITY_"
                text: userModel.lastUser || ""
                color: "#e0e0e0"
                font.pixelSize: 16
                font.family: "JetBrains Mono"
                leftPadding: 12
                background: Rectangle {
                    color: "#15000509"
                    border.color: usernameField.activeFocus ? "#bc00ff" : "#330a0e1a"
                    border.width: 1
                    radius: 2
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }
                onAccepted: passwordField.focus = true
            }

            // Password field
            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "CREDENTIAL_HASH_"
                echoMode: TextInput.Password
                color: "#00f3ff"
                font.pixelSize: 16
                font.family: "JetBrains Mono"
                leftPadding: 12
                background: Rectangle {
                    color: "#15000509"
                    border.color: passwordField.activeFocus ? "#00f3ff" : "#220a0f20"
                    border.width: passwordField.activeFocus ? 2 : 1
                    radius: 2
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }
                onAccepted: sddm.login(usernameField.text, passwordField.text, sessionList.currentIndex)
                focus: true
            }

            // Session selector
            ComboBox {
                id: sessionList
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex !== undefined ? sessionModel.lastIndex : 0
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                contentItem: Text {
                    leftPadding: 12
                    text: sessionList.displayText
                    font: sessionList.font
                    color: "#6272a4"
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: "#10000509"
                    border.color: "#1a00f3ff"
                    border.width: 1
                    radius: 2
                }
            }

            // Auth button
            Button {
                id: authButton
                Layout.fillWidth: true
                Layout.preferredHeight: 52

                property bool isHovered: false

                background: Rectangle {
                    color: authButton.pressed ? "#22ffffff" :
                           authButton.isHovered ? "#1200f3ff" : "transparent"
                    border.color: authButton.pressed ? "#ffffff" :
                                  authButton.isHovered ? "#00f3ff" : "#3300f3ff"
                    border.width: authButton.isHovered ? 2 : 1
                    radius: 2
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                contentItem: Text {
                    text: authButton.pressed ? "[ AUTHENTICATING... ]" : "▶▶  INITIALIZE_AUTH_SESSION  ◀◀"
                    color: authButton.isHovered ? "#00f3ff" : "#4400f3ff"
                    font.bold: true
                    font.pixelSize: 13
                    font.family: "JetBrains Mono"
                    font.letterSpacing: 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                HoverHandler {
                    onHoveredChanged: authButton.isHovered = hovered
                }

                onClicked: sddm.login(usernameField.text, passwordField.text, sessionList.currentIndex)
            }

            // Error message area
            Text {
                id: errorMsg
                Layout.alignment: Qt.AlignHCenter
                color: "#ff5555"
                font.pixelSize: 11
                font.family: "JetBrains Mono"
                text: ""
                visible: text !== ""
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  BOTTOM FOOTER BAR
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 36
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#08000a0f"
        }

        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: "#1500f3ff"
        }

        Text {
            anchors.centerIn: parent
            text: "BLACK-ICE ARCH // ALL ACCESS ATTEMPTS LOGGED // UNAUTHORIZED ACCESS PROHIBITED"
            color: "#1a00f3ff"
            font.pixelSize: 10
            font.family: "JetBrains Mono"
            font.letterSpacing: 1.5
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  SDDM signal handlers
    // ═══════════════════════════════════════════════════════════
    Connections {
        target: sddm

        function onLoginFailed() {
            errorMsg.text = "⚠  ACCESS DENIED — INVALID CREDENTIALS"
            passwordField.text = ""
            passwordField.focus = true
            errorClearTimer.start()
        }
    }

    Timer {
        id: errorClearTimer
        interval: 4000
        onTriggered: errorMsg.text = ""
    }

    // ═══════════════════════════════════════════════════════════
    //  Clock update
    // ═══════════════════════════════════════════════════════════
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: topClock.text = Qt.formatTime(new Date(), "hh:mm:ss")
    }
}
