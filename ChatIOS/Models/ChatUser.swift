import Foundation

// MARK: - Auth

// Модель пользователя из backend auth-flow.
struct ChatUser: Decodable, Identifiable {
    let id: Int
    let username: String
    let displayName: String?
    let isUsernameCustom: Bool
    let phoneVerified: Bool

    // Связываем snake_case поля из backend с camelCase свойствами в Swift.
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case isUsernameCustom = "is_username_custom"
        case phoneVerified = "phone_verified"
    }
}

// Ответ backend на dev-login.
struct DevLoginResponse: Decodable {
    let user: ChatUser
    let sessionToken: String
    let created: Bool
    
    enum CodingKeys: String, CodingKey {
        case user
        case sessionToken = "session_token"
        case created
    }
}

// MARK: - Search

// Пользователь, найденный через экран "Написать сообщение".
struct UserSearchResult: Decodable, Identifiable {
    let id: Int
    let username: String
    let displayName: String?
    let isUsernameCustom: Bool

    // Backend отдаёт snake_case, Swift-код использует camelCase.
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case isUsernameCustom = "is_username_custom"
    }
}
