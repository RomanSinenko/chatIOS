import Foundation

// Модель пользователя, которую backend возвращает после создания.
struct ChatUser: Decodable, Identifiable {
    // Внутренний id пользователя из backend.
    let id: Int
    // Имя пользователя в Swift-формате.
    let userName: String

    // Связываем backend поле user_name со Swift свойством userName.
    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
    }
}
