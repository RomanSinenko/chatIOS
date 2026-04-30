import Foundation

// Последнее сообщение, которое backend возвращает внутри элемента списка чатов
struct LastMessage: Decodable, Identifiable {
    // id последнего сообщения.
    let id: Int
    // id пользователя, который отправил последнее сообщение.
    let senderID: Int
    // Текст последнего сообщения.
    let text: String
    // Тип сообщения, сейчас обычно "text".
    let messageType: String
    // Дата создания сообщения. Пока храним строкой, позже можно распарсить в Date.
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
