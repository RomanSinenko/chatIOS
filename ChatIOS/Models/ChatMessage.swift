import Foundation

// Legacy-модель старого статического chat-flow.
// Реальный экран чата сейчас использует BackendChatMessage.
struct ChatMessage: Identifiable {
    let id: Int
    let text: String
    let isMine: Bool
}
