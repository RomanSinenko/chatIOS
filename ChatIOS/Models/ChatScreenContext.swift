import Foundation

// Данные, с которыми iOS открывает экран чата.
struct ChatScreenContext: Identifiable, Hashable {
    let id: Int
    let currentUserID: Int
    let peerUserID: Int
    let displayName: String
}
