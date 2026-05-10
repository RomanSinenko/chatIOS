import Foundation

// Сообщение, которое приходит из backend history endpoint.
struct BackendChatMessage: Decodable, Identifiable {
    let id: Int
    let chatID: Int
    let senderID: Int
    let text: String
    let messageType: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case chatID = "chat_id"
        case senderID = "sender_id"
        case text
        case messageType = "message_type"
        case createdAt = "created_at"
    }
}
