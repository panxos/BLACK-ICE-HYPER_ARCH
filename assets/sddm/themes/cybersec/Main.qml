import QtQuick 2.0
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.0

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: "#050a0f"

    // --- BACKGROUND LAYER ---
    Image {
        id: bgImage
        anchors.fill: parent
        source: "assets/background.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.6
    }

    // Interactive tech grid
    Grid {
        anchors.fill: parent
        columns: 48
        rows: 27
        spacing: 0
        opacity: 0.1
        Repeater {
            model: 48 * 27
            Rectangle {
                width: parent.width / 48
                height: parent.height / 27
                color: "transparent"
                border.color: "#00f3ff"
                border.width: 1
            }
        }
    }

    // --- TOP HEADER ---
    Rectangle {
        anchors.top: parent.top
        width: parent.width; height: 60
        color: "#cc000a0f"
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 40; anchors.rightMargin: 40
            
            Text {
                text: "BLACKARCH_OS // NODE_S3TH_ONLINE"
                color: "#00f3ff"; font.pixelSize: 14; font.family: "JetBrains Mono"
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                id: timeLabel
                color: "#00f3ff"; font.pixelSize: 24; font.bold: true; font.family: "JetBrains Mono"
                text: Qt.formatTime(new Date(), "hh:mm:ss")
            }
        }
    }

    // --- LOGIN HUB (Single Component Logic) ---
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        width: 480; height: 580
        color: "#dd00050a"
        border.color: "#00f3ff"
        border.width: 2
        radius: 4

        // Tech corners
        Rectangle { width: 20; height: 3; color: "#00f3ff"; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 3; height: 20; color: "#00f3ff"; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 20; height: 3; color: "#00f3ff"; anchors.bottom: parent.bottom; anchors.right: parent.right }
        Rectangle { width: 3; height: 20; color: "#00f3ff"; anchors.bottom: parent.bottom; anchors.right: parent.right }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width * 0.85
            spacing: 25

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "SYSTEM IDENTITY REQUIRED"
                color: "#00f3ff"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2
            }

            // Avatar
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 120; height: 120; radius: 60
                color: "transparent"
                border.color: "#bc00ff"; border.width: 2
                clip: true // Failsafe circular clipping

                Image {
                    id: userAvatar
                    anchors.fill: parent; anchors.margins: 2
                    source: userModel.lastUser ? "file:///var/lib/AccountsService/icons/" + userModel.lastUser : ""
                    fillMode: Image.PreserveAspectCrop
                    onStatusChanged: {
                        if (status == Image.Error || source == "") {
                            source = "assets/avatar.png"
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: (userModel.lastUser || "faravena").toUpperCase()
                color: "white"; font.pixelSize: 26; font.family: "JetBrains Mono"
            }

            // Input Fields
            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "CREDENTIAL_HASH_"
                echoMode: TextInput.Password
                color: "white"
                font.pixelSize: 18
                background: Rectangle { 
                    color: "#22000000"; border.color: "#00f3ff"; border.width: 1 
                }
                onAccepted: sddm.login(userModel.lastUser, passwordField.text, sessionList.currentIndex)
                focus: true
            }

            ComboBox {
                id: sessionList
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: session.index
            }

            Button {
                id: authButton
                Layout.fillWidth: true; Layout.preferredHeight: 55
                text: ">> INITIALIZE_AUTH_SESSION"
                contentItem: Text {
                    text: authButton.text
                    color: "#00f3ff"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: authButton.pressed ? "#00f3ff" : "transparent"
                    border.color: "#00f3ff"; border.width: 2
                }
                onClicked: sddm.login(userModel.lastUser, passwordField.text, sessionList.currentIndex)
            }
        }
    }

    // --- FOOTER ---
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 30
        color: "#aa00050a"
        Text {
            anchors.centerIn: parent
            text: "NODE_S3TH // ENCRYPTION_ACTIVE // BLACK-ICE_V4"
            color: "#4400f3ff"; font.pixelSize: 9
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: timeLabel.text = Qt.formatTime(new Date(), "hh:mm:ss")
    }
}
