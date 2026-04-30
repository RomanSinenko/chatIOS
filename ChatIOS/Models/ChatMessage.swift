import Foundation

// Временная модель - заглушка одного сообщение - статический экран
struct ChatMessage: Identifiable {
    // Уникальный id нужен, чтобы ForEach мог отличать сообщения друг от друга.
    let id: Int
    // Текст сообщения, который показываем в пузыре.
    let text: String
    // true — моё сообщение, false — сообщение собеседника.
    let isMine: Bool
}
