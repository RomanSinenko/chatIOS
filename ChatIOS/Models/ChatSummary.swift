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
