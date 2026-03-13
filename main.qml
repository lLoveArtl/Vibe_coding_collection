import Quickshell
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtWebSockets
import QtQuick.Window 

PanelWindow {
    id: rootWindow
    focusable: true 
    
    // Giữ nguyên tỷ lệ đã gọt viền
    implicitWidth: Screen.width * 0.40 
    implicitHeight: implicitWidth * (1267.0 / 1291.0)
    
    anchors.right: true
    anchors.bottom: true
    margins.right: 20
    margins.bottom: 20
    color: "transparent"

    Image {
        id: catImage
        source: "file:///home/loveart/GeminiShell/cat_cropped.png"
        anchors.fill: parent
        fillMode: Image.Stretch 
    }

    // --- 🌟 BỘ NHỚ GIAO DIỆN (LƯU TRỮ TẤT CẢ TIN NHẮN) 🌟 ---
    ListModel { id: chatHistoryModel }

    QtObject {
        id: internal
        function parseMessage(msg) {
            if (msg.startsWith("GEMINI_RESPONSE:")) {
                var content = msg.substring(16);
                // THÊM VÀO DANH SÁCH (Không phải ghi đè)
                chatHistoryModel.append({
                    "sender": "Mèo",
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
        // Tọa độ chuẩn của bạn
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

            // --- KHUNG HIỂN THỊ CÓ THỂ CUỘN ---
            ScrollView {
                id: chatScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                // Quy định thanh cuộn luôn hiện khi cần
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ListView {
                    id: chatListView
                    model: chatHistoryModel
                    width: chatScrollView.width
                    spacing: 10
                    interactive: true
                    
                    // Template cho từng tin nhắn
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
                    
                    // Tự động nhảy xuống tin mới nhất
                    onCountChanged: chatListView.currentIndex = count - 1
                }
            }

            // --- Ô NHẬP LIỆU ---
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
                    placeholderText: "Nhập lệnh meo~..."
                    font.pointSize: 10
                    focus: true 
                    
                    onAccepted: {
                        if (text !== "") {
                            // THÊM TIN NHẮN CỦA BẠN VÀO DANH SÁCH
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
