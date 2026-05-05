import Foundation

// Короткая модель чата для экрана списка чатов
struct ChatSummary: Decodable, Identifiable {
    let id: Int
    let chatType: String
    let title: String?
    let displayName: String
    let membersCount: Int
    let createdAt: String
    let lastMessage: LastMessage?

    // Backend отдаёт поля в snake_case, а в Swift используем camelCase.
    enum CodingKeys: String, CodingKey {
        case id
        case chatType = "chat_type"
        case title
        case displayName = "display_name"
        case membersCount = "members_count"
        case createdAt = "created_at"
        case lastMessage = "last_message"
    }
}

// Ответ backend на создание или получение private chat.
struct PrivateChatResponse: Decodable {
    // Внутренний id чата из backend.
    let id: Int
    // Тип чата. Backend всегда должен вернуть значение: private, self, group и т.д.
    let chatType: String
    // id собеседника, которого выбрали в поиске.
    let peerUserID: Int
    // true, если backend создал новый чат; false, если вернул существующий.
    let created: Bool
    
    // Связываем snake_case из backend с camelCase в Swift.
    enum CodingKeys: String, CodingKey {
        case id
        case chatType = "chat_type"
        case peerUserID = "peer_user_id"
        case created
    }
}
