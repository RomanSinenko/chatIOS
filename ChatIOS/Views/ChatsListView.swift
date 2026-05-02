import SwiftUI

struct ChatsListView: View {
    
    let userID: Int
    // Действие выхода приходит снаружи, потому что состояние входа хранит ContentView.
    let onLogout: () -> Void
    
    // Список чатов, загруженный с backend.
    @State private var chats: [ChatSummary] = []
    // true, пока ждём ответ от backend.
    @State private var isLoadingChats = false
    // Текст ошибки загрузки чатов, если запрос не удался.
    @State private var chatsErrorMessage: String?
    
    private let apiClient = APIClient()
    
    var body: some View {
        List {
            if isLoadingChats {
                Section {
                    Text("Загрузка")
                        .foregroundStyle(.secondary)
                }
            } else if let chatsErrorMessage {
                Section{
                    Text(chatsErrorMessage)
                        .foregroundStyle(.red)
                }
            } else if chats.isEmpty {
                Section {
                    Text("Пока чатов нет")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(chats) { chat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chat.displayName)
                                .font(.headline)
                            
                            if let lastMessage = chat.lastMessage {
                                Text(lastMessage.text)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Сообщений пока нету")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Чаты")
        .toolbar{
            ToolbarItem(placement: .topBarLeading) {
                Button("Выйти") {
                    onLogout()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                // Карандаш открывает экран контактов перед созданием/открытием чата.
                NavigationLink {
                    ContactsView()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        // Когда экран появился, сразу запрашиваем чаты пользователя.
        .onAppear {
            loadChats()
        }
    }
    
    // Загружает чаты пользователя при открытии экрана.
    private func loadChats() {
        Task {
            isLoadingChats = true
            chatsErrorMessage = nil
            
            do {
                chats = try await apiClient.getUserChats(userID: userID)
            } catch {
                chatsErrorMessage = "Не удалось загрузить чаты"
                print("Load chats failed \(error)")
            }
            
            isLoadingChats = false
        }
    }
}

#Preview {
    ChatsListView(userID: 1){
        print("Preview logout")
    }
}
