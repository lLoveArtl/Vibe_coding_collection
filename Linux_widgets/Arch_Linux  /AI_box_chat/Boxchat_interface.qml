import Quickshell
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtWebSockets
import QtQuick.Window 

PanelWindow {
    id: rootWindow
    focusable: true 
    
    //delete picture outline
    implicitWidth: Screen.width * 0.40 
    implicitHeight: implicitWidth * (1267.0 / 1291.0)
    
    anchors.right: true
    anchors.bottom: true
    margins.right: 20
    margins.bottom: 20
    color: "transparent"

    Image {
        id: catImage
        source: "your_picture"
        anchors.fill: parent
        fillMode: Image.Stretch 
    }

    // --- 🌟 memory appearance(help to the history chat always appear when using 🌟 ---
    ListModel { id: chatHistoryModel }

    QtObject {
        id: internal
        function parseMessage(msg) {
            if (msg.startsWith("CHATBOT_RESPONSE:")) {
                var content = msg.substring(16);
                // add list 
                chatHistoryModel.append({
                    "sender": "Anynomous",
                    "message": content,
                    "isUser": false
                });
            }
        }
    }

    WebSocket {
        id: socket
        url: "ws://localhost:8080"
        active: true
        onTextMessageReceived: (message) => internal.parseMessage(message)
    }

    Rectangle {
        id: chatBox
        // standard x,y
        x: parent.width * 0.09
        y: parent.height * 0.52
        width: parent.width * 0.68
        height: parent.height * 0.43 
        
        color: "#1e1e2e" 
        radius: 12
        border.color: "#cba6f7"
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // --- scrolling aprearance ---
            ScrollView {
                id: chatScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                // scrolling rule
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ListView {
                    id: chatListView
                    model: chatHistoryModel
                    width: chatScrollView.width
                    spacing: 10
                    interactive: true
                    
                    // Template for each chat
                    delegate: Rectangle {
                        width: chatListView.width * 0.92
                        height: msgText.implicitHeight + 20
                        color: model.isUser ? "#313244" : "#45475a"
                        radius: 10
                        anchors.right: model.isUser ? parent.right : undefined
                        anchors.left: model.isUser ? undefined : parent.left

                        Text {
                            id: msgText
                            text: "<b>" + model.sender + ":</b> " + model.message
                            color: "#BAC2DE"
                            anchors.fill: parent
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            font.pointSize: 9
                        }
                    }
                    
                    // automactic jump to new reply
                    onCountChanged: chatListView.currentIndex = count - 1
                }
            }

            // --- chat input ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                color: "#11111b"
                radius: 8

                TextField {
                    id: inputField
                    anchors.fill: parent
                    anchors.margins: 5
                    background: null
                    color: "#BAC2DE"
                    placeholderText: "Please type hear~..."
                    font.pointSize: 10
                    focus: true 
                    
                    onAccepted: {
                        if (text !== "") {
                            // add your text to memory
                            chatHistoryModel.append({
                                "sender": "Bạn",
                                "message": text,
                                "isUser": true
                            });
                            
                            socket.sendTextMessage("SEND_PROMPT\n" + text);
                            text = "";
                        }
                    }
                }
            }
        }
    }
}
