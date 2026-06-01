import Foundation
import Combine

// Хранит последнюю scroll-позицию отдельно для каждого чата.
final class ChatScrollPositionStore: ObservableObject {
    enum Position {
        case bottom
        case message(id: Int)
    }

    private var positions: [Int: Position] = [:]

    func position(for chatID: Int) -> Position? {
        positions[chatID]
    }

    func setPosition(_ position: Position, for chatID: Int) {
        positions[chatID] = position
    }
}
