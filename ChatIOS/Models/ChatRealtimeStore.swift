import Foundation
import Combine

// Хранит realtime-события и счетчики чатов.
final class ChatRealtimeStore: ObservableObject {
    @Published private(set) var latestMessage: BackendChatMessage?
    @Published private(set) var unreadCountsByChatID: [Int: Int] = [:]
    @Published private(set) var activeChatID: Int?

    // Публикует входящее сообщение для подписанных экранов.
    func receiveMessage(_ message: BackendChatMessage) {
        latestMessage = message
    }

    // Возвращает счетчик непрочитанных для конкретного чата.
    func unreadCount(for chatID: Int) -> Int {
        unreadCountsByChatID[chatID, default: 0]
    }

    // Увеличивает счетчик непрочитанных для конкретного чата.
    func incrementUnreadCount(for chatID: Int) {
        unreadCountsByChatID[chatID, default: 0] += 1
    }

    // Сбрасывает счетчик непрочитанных для конкретного чата.
    func markChatAsRead(chatID: Int) {
        unreadCountsByChatID[chatID] = nil
    }
    
    // Запоминает, какой чат сейчас открыт.
    func openChat(chatID: Int) {
        activeChatID = chatID
    }

    // Очищает активный чат при выходе с экрана чата.
    func closeChat(chatID: Int) {
        guard activeChatID == chatID else { return }

        activeChatID = nil
    }

    // Проверяет, открыт ли сейчас конкретный чат.
    func isChatOpen(_ chatID: Int) -> Bool {
        activeChatID == chatID
    }

    // Очищает последнее событие.
    func clearLatestMessage() {
        latestMessage = nil
    }

    // Очищает realtime-состояние при выходе.
    func clearAll() {
        latestMessage = nil
        unreadCountsByChatID = [:]
        activeChatID = nil
    }
}
