import SwiftUI

struct ContentView: View {
    // nil значит, что пользователь ещё не вошёл.
    // Когда здесь появляется имя, показываем экран чатов.
    @State private var currentUserName: String?
    
    var body: some View {
        // NavigationStack нужен, чтобы дочерние экраны могли открывать следующие экраны.
        NavigationStack {
            if let currentUserName {
                ChatsListView(userName: currentUserName) {
                    // Выход очищает пользователя, поэтому SwiftUI снова покажет StartView.
                    self.currentUserName = nil
                }
            } else {
                StartView{ userName in
                        // StartView отдаёт введённое имя сюда через onContinue.
                        currentUserName = userName
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
