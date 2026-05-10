import Foundation


// Данные, с которыми iOS открывает экран чата
struct ChatScreenContext: Identifiable, Hashable {
    // id нужен SwiftUI для navigationDestination(item:).
    // Для экрана чата id равен backend chat id.
    let id: Int
    
    // ID текущего пользователя, чтобы понимать какие сообщения "мои".
    let currentUserID: Int
    
    // ID собеседника в private chat.
    let peerUserID: Int
    
    // Название, которое показываем в заголовке чата.
    let displayName: String
}
