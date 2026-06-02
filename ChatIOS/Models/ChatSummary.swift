import Foundation

// MARK: - Chat List

// Короткая модель чата для экрана списка чатов.
struct ChatSummary: Decodable, Identifiable {
    let id: Int
    let chatType: String
    let title: String?
    let displayName: String
    let peerUserID: Int?
    let membersCount: Int
    let createdAt: String
    let lastMessage: LastMessage?

    // Backend отдаёт поля в snake_case, а в Swift используем camelCase.
    enum CodingKeys: String, CodingKey {
        case id
        case chatType = "chat_type"
        case title
        case displayName = "display_name"
        case peerUserID = "peer_user_id"
        case membersCount = "members_count"
        case createdAt = "created_at"
        case lastMessage = "last_message"
    }
}

// MARK: - Private Chat

// Ответ backend на создание или получение private chat.
struct PrivateChatResponse: Decodable {
    let id: Int
    let chatType: String
    let peerUserID: Int
    let created: Bool

    // Связываем snake_case из backend с camelCase в Swift.
    enum CodingKeys: String, CodingKey {
        case id
        case chatType = "chat_type"
        case peerUserID = "peer_user_id"
        case created
    }
}
