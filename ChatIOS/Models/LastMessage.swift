import Foundation

// Последнее сообщение, которое backend возвращает внутри элемента списка чатов.
struct LastMessage: Decodable, Identifiable {
    let id: Int
    let senderID: Int
    let text: String
    let messageType: String
    let createdAt: String

    // Связываем snake_case из backend с camelCase в Swift.
    enum CodingKeys: String, CodingKey {
        case id
        case senderID = "sender_id"
        case text
        case messageType = "message_type"
        case createdAt = "created_at"
    }
}
