import Foundation

// Модель пользователя, которую backend возвращает после создания.
struct ChatUser: Decodable, Identifiable {
    // Внутренний id пользователя из backend.
    let id: Int
    // Уникальный публичный идентификатор пользователя, например user_a1b2c3d4 или roman.
    let username: String
    // Отображаемое имя. Оно не уникальное: "Роман", "Alena", "Магазин колес".
    let displayName: String?
    // true, если пользователь сам поменял дефолтный username.
    let isUsernameCustom: Bool
    // true после SMS/OTP подтверждения.
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
// user содержит данные пользователя, created показывает, был пользователь создан сейчас или найден по телефону.
struct DevLoginResponse: Decodable {
    let user: ChatUser
    let created: Bool
}
