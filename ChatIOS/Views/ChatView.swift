import SwiftUI


struct ChatView: View {
    // Контекст чата приходит из списка чатов или с экрана создания нового сообщения.
    let chatContext: ChatScreenContext
    
    // Session token нужен для защищенной загрузки истории сообщений.
    let sessionToken: String
    
    // Позволяет закрыть текущий экран и вернуться назад.
    @Environment(\.dismiss) private var dismiss
    
    // Текст, который пользователь вводит в нижнем поле.
    @State private var messageText = ""
    
    // Сообщения, загруженные из backend history endpoint.
    @State private var messages: [BackendChatMessage] = []
    
    // true, пока iOS ждёт историю сообщений от backend.
    @State private var isLoadingMessages = false
    
    // Текст ошибки загрузки истории.
    @State private var messagesErrorMessage: String?
    
    // HTTP-клиент для запросов к backend.
    private let apiClient = APIClient()
    
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                if isLoadingMessages {
                    HStack {
                        Spacer()
                        ProgressView("Загружаем сообщения")
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else if messagesErrorMessage != nil {
                    // Ошибку показываем ниже отдельным блоком с кнопкой повторной загрузки.
                    EmptyView()
                } else if messages.isEmpty {
                    
                    HStack {
                        Spacer()
                        Text("Сообщений пока нет")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    
                } else {
                    ForEach(messages) { message in
                        // Сообщение считается моим, если sender_id совпал с текущим пользователем.
                        let isMine = message.senderID == chatContext.currentUserID
                        
                        HStack {
                            // Spacer перед текстом прижимает моё сообщение вправо.
                            if isMine {
                                Spacer()
                            }
                            
                            Text(message.text)
                                .padding(10)
                                .background(isMine ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundStyle(isMine ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            // Spacer после текста оставляет сообщение собеседника слева.
                            if !isMine {
                                Spacer()
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            if messagesErrorMessage != nil {
                // Блок виден только если загрузка истории завершилась ошибкой.
                VStack(spacing: 8) {
                    Text("Упс, что то не так с загрузкой")
                        .foregroundStyle(.secondary)
                    
                    Button {
                        loadMessages()
                    } label: {
                        Label("Обновить", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            // Отправку сообщений реализуем отдельным шагом.
            // Пока показываем заблокированное поле, чтобы не создавать ложное поведение.
            HStack {
                TextField("Отправка сообщений будет добавлена позже", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                
                Button {
                    
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(true)
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            // Кастомная кнопка назад: скрываем системную кнопку и рисуем свою,
            // чтобы управлять размером, прозрачностью и цветом круглого контейнера.
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(width: 24, height: 24)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                        }
                }
                .buttonStyle(.plain)
            }

            // Кастомный title чата: имя собеседника показывается в центре navigation bar
            // в контейнере-капсуле, который сам подстраивается под длину имени.
            ToolbarItem(placement: .principal) {
                Text(chatContext.displayName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
            }
        }
        .onAppear {
            loadMessages()
        }
    }
    
    // Загружает историю сообщении текущего чата.
    private func loadMessages() {
        Task {
            isLoadingMessages = true
            messagesErrorMessage = nil
            
            do {
                messages = try await apiClient.fetchMessages(
                    chatID: chatContext.id,
                    sessionToken: sessionToken
                )
            } catch {
                messagesErrorMessage = "Не удалось загрузить сообщения"
                print("Load message failed: \(error)")
            }
            
            isLoadingMessages = false
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(
            chatContext: ChatScreenContext(
                id: 1,
                currentUserID: 1,
                peerUserID: 2,
                displayName: "Alena"
            ),
            sessionToken: "preview-token"
        )
    }
}
