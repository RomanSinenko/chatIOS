import Foundation

// Событие верхнего уровня, которое приходит из WebSocket.
struct ChatWebSocketEvent: Decodable {
    let type: String
    let message: BackendChatMessage?

    let clientMessageID: String?
    let chatID: Int?
    let messageID: Int?
    let status: String?
    let createdAt: Date?

    let code: String?
    let text: String?

    enum CodingKeys: String, CodingKey {
        case type
        case message
        case clientMessageID = "client_message_id"
        case chatID = "chat_id"
        case messageID = "message_id"
        case status
        case createdAt = "created_at"
        case code
        case text
    }
}
