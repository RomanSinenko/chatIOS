import SwiftUI

struct ChatsListView: View {
    // MARK: - Input

    let userID: Int
    let sessionToken: String
    let onLogout: () -> Void
    
    // MARK: - Environment

    @EnvironmentObject private var chatRealtimeStore: ChatRealtimeStore

    // MARK: - State

    @State private var chats: [ChatSummary] = []
    @State private var isLoadingChats = false
    @State private var chatsErrorMessage: String?
    @State private var isNewMessageScreenOpen = false

    // MARK: - Dependencies

    private let apiClient = APIClient()

    // MARK: - Body

    var body: some View {
        List {
            listContent
        }
        .navigationTitle("Чаты")
        .toolbar {
            chatsToolbar
        }
        .navigationDestination(isPresented: $isNewMessageScreenOpen) {
            NewMessageView(
                currentUserID: userID,
                sessionToken: sessionToken
            )
        }
        .onAppear {
            loadChats()
        }
        .onChange(of: chatRealtimeStore.latestMessage?.id) {
            handleRealtimeMessage()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var listContent: some View {
        if isLoadingChats {
            statusSection("Загрузка", color: .secondary)
        } else if let chatsErrorMessage {
            statusSection(chatsErrorMessage, color: .red)
        } else if chats.isEmpty {
            statusSection("Пока чатов нет", color: .secondary)
        } else {
            chatsSection
        }
    }

    private var chatsSection: some View {
        Section {
            ForEach(chats) { chat in
                NavigationLink {
                    chatDestination(for: chat)
                } label: {
                    chatRow(chat)
                }
            }
        }
    }

    private func statusSection(_ text: String, color: Color) -> some View {
        Section {
            Text(text)
                .foregroundStyle(color)
        }
    }

    private func chatDestination(for chat: ChatSummary) -> some View {
        ChatView(
            chatContext: ChatScreenContext(
                id: chat.id,
                currentUserID: userID,
                peerUserID: chat.peerUserID ?? userID,
                displayName: chat.displayName
            ),
            sessionToken: sessionToken
        )
    }

    private func chatRow(_ chat: ChatSummary) -> some View {
        let unreadCount = chatRealtimeStore.unreadCount(for: chat.id)

        return HStack(spacing: 12) {
            // Текстовая часть строки чата.
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.displayName)
                    .font(.headline)

                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Сообщений пока нет")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Badge непрочитанных сообщений.
            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 24, minHeight: 24)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var chatsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Выйти") {
                onLogout()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isNewMessageScreenOpen = true
            } label: {
                Image(systemName: "square.and.pencil")
            }
        }
    }

    // MARK: - Actions

    // Загружает чаты пользователя при открытии экрана.
    private func loadChats() {
        Task {
            isLoadingChats = true
            chatsErrorMessage = nil

            do {
                chats = try await apiClient.getUserChats(sessionToken: sessionToken)
            } catch {
                chatsErrorMessage = "Не удалось загрузить чаты"
                print("Load chats failed \(error)")
            }

            isLoadingChats = false
        }
    }
    
    // Обновляет список чатов по входящему realtime-сообщению.
    private func handleRealtimeMessage() {
        guard let realtimeMessage = chatRealtimeStore.latestMessage else { return }
        
        if realtimeMessage.senderID != userID,
           !chatRealtimeStore.isChatOpen(realtimeMessage.chatID) {
            chatRealtimeStore.incrementUnreadCount(for: realtimeMessage.chatID)
        }

        if let index = chats.firstIndex(where: { $0.id == realtimeMessage.chatID }) {
            let updatedChat = chatWithUpdatedLastMessage(
                chats[index],
                message: realtimeMessage
            )

            chats.remove(at: index)
            chats.insert(updatedChat, at: 0)
        } else {
            loadChats()
        }
    }

    // Пересобирает ChatSummary с новым lastMessage.
    private func chatWithUpdatedLastMessage(
        _ chat: ChatSummary,
        message: BackendChatMessage
    ) -> ChatSummary {
        ChatSummary(
            id: chat.id,
            chatType: chat.chatType,
            title: chat.title,
            displayName: chat.displayName,
            peerUserID: chat.peerUserID,
            membersCount: chat.membersCount,
            createdAt: chat.createdAt,
            lastMessage: lastMessage(from: message)
        )
    }

    // Конвертирует realtime-сообщение в модель превью для списка чатов.
    private func lastMessage(from message: BackendChatMessage) -> LastMessage {
        LastMessage(
            id: message.id,
            senderID: message.senderID,
            text: message.text,
            messageType: message.messageType,
            createdAt: ISO8601DateFormatter().string(from: message.createdAt)
        )
    }
}

#Preview {
    ChatsListView(
        userID: 1,
        sessionToken: "preview-token"
    ) {
        print("Preview logout")
    }
    .environmentObject(ChatRealtimeStore())
}
