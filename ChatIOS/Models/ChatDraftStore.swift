import Foundation
import Combine

// Хранит черновики сообщений по chatID.
final class ChatDraftStore: ObservableObject {
    @Published private var drafts: [Int: String] = [:]

    func draft(for chatID: Int) -> String {
        drafts[chatID] ?? ""
    }

    func setDraft(_ text: String, for chatID: Int) {
        drafts[chatID] = text
    }

    func clearDraft(for chatID: Int) {
        drafts[chatID] = nil
    }
}
