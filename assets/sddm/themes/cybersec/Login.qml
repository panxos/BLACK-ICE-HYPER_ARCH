import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0
import "components"

Item {
    id: loginPanel
    width: 500
    height: 600
    
    property var userModel: userModel
    property var sessionModel: sessionModel
    signal login(string user, string password, int sessionIndex)

    // Glass Panel
    Rectangle {
        id: glass
        anchors.fill: parent
        color: "#cc050a0f"
        radius: 4
        border.color: "#3300f3ff"
        border.width: 1

        TechBorder {
            borderColor: "#00f3ff"
            borderWidth: 2
            anchors.fill: parent
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.82
        spacing: 30

        // Identification Header
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "SYSTEM IDENTITY VERIFICATION"
            color: "#00f3ff"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 2
        }

        // Animated Avatar Section
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 140; height: 140
            
            Rectangle {
                anchors.centerIn: parent
                width: 130; height: 130
                radius: 65
                color: "transparent"
                border.color: "#bc00ff"
                border.width: 3
                
                Image {
                    id: avatarImage
                    anchors.fill: parent
                    anchors.margins: 6
                    source: userModel.lastUser ? "file:///var/lib/AccountsService/icons/" + userModel.lastUser : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source != ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "U"
                    color: "white"
                    font.pixelSize: 64
                    visible: avatarImage.status != Image.Ready
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 140; height: 140
                radius: 70
                color: "transparent"
                border.color: "#00f3ff"
                border.width: 1
                border.style: Qt.DashLine
                
                RotationAnimation on rotation {
                    from: 0; to: 360; duration: 15000; loops: Animation.Infinite
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: (userModel.lastUser || "USER").toUpperCase()
            color: "white"
            font.family: "JetBrains Mono"
            font.pixelSize: 26
            font.letterSpacing: 5
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 15

            CustomTextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "ROOT_ACCESS_CODE"
                echoMode: TextInput.Password
                font.pixelSize: 18
                onAccepted: loginPanel.login(userModel.lastUser, passwordField.text, sessionList.currentIndex)
                focus: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Text {
                    text: "SESS:"
                    color: "#bc00ff"
                    font.family: "JetBrains Mono"
                }

                ComboBox {
                    id: sessionList
                    Layout.fillWidth: true
                    model: sessionModel
                    textRole: "name"
                    
                    contentItem: Text {
                        text: sessionList.displayText
                        color: "#00f3ff"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }

                    background: Rectangle {
                        color: "#15000000"
                        border.color: "#00f3ff"
                        border.width: 1
                    }
                }
            }
        }

        CustomButton {
            text: "EXECUTE_LOGIN"
            Layout.fillWidth: true
            Layout.preferredHeight: 55
            glowColor: "#00f3ff"
            onClicked: loginPanel.login(userModel.lastUser, passwordField.text, sessionList.currentIndex)
        }
        
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "SECURE ENCLAVE ACTIVE // ENCRYPTION AES-512"
            color: "#55ffffff"
            font.family: "JetBrains Mono"
            font.pixelSize: 9
        }
    }

    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 25
        spacing: 40

        CustomButton {
            text: "OFF"
            Layout.preferredWidth: 80; Layout.preferredHeight: 30
            glowColor: "#ff0044"
            onClicked: sddm.powerOff()
        }
        CustomButton {
            text: "REBT"
            Layout.preferredWidth: 80; Layout.preferredHeight: 30
            glowColor: "#ffcc00"
            onClicked: sddm.reboot()
        }
    }
}
