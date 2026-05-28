import SwiftUI


struct ChatView: View {
    // Контекст чата приходит из списка чатов или с экрана создания нового сообщения.
    let chatContext: ChatScreenContext
    
    // Session token нужен для защищенной загрузки истории сообщений.
    let sessionToken: String
    
    // Позволяет закрыть текущий экран и вернуться назад.
    @Environment(\.dismiss) private var dismiss
    
    // Общая память черновиков для всех чатов.
    @EnvironmentObject private var chatDraftStore: ChatDraftStore
    
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
    
    // Невидимая точка в самом низу списка сообщений.
    private let bottomAnchorID = "chat-bottom-anchor"
    
    // Минимальная высота нижней зоны input.
    private let minimumInputAreaHeight: CGFloat = 72

    // Фактическая высота нижней зоны input.
    @State private var inputAreaHeight: CGFloat = 72

    // Фиксированный зазор между последним сообщением и input.
    private let messageInputGap: CGFloat = 8
    
    // Готовит текст к отправке: убирает пробелы по краям.
    private var trimmedMessageText: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Управляет состоянием кнопки отправки.
    private var canSendMessage: Bool {
        !trimmedMessageText.isEmpty
    }
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if isLoadingMessages {
                            ProgressView("Загружаем сообщения")
                                .padding()
                        } else if messagesErrorMessage != nil {
                            EmptyView()
                        } else if messages.isEmpty {
                            Text("Сообщений пока нет")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(messages) { message in
                                let isMine = message.senderID == chatContext.currentUserID

                                HStack {
                                    if isMine {
                                        Spacer()
                                    }

                                    Text(message.text)
                                        .padding(10)
                                        .background(isMine ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundStyle(isMine ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    if !isMine {
                                        Spacer()
                                    }
                                }
                            }
                        }

                        Color.clear
                            .frame(height: inputAreaHeight + messageInputGap)
                            .id(bottomAnchorID)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
                .onChange(of: messages.count) {
                    scrollToBottom(proxy, animated: false)
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

            // Нижний overlay поверх чата: размывает и высветляет сообщения под полем ввода.
            // Сам input остается кликабельным, потому что этот слой ниже отключает hit testing.
            VStack(spacing: 0) {
                Spacer()

                Rectangle()
                    // Сила системного blur. Можно пробовать .ultraThinMaterial, .thinMaterial, .regularMaterial.
                    .fill(.thinMaterial)
                    // Маска задает, где blur начинается и где становится полностью видимым.
                    .mask(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.85),
                                Color.black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    // Белый градиент поверх blur делает сообщения под input менее читаемыми.
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.45)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    // Высота зоны эффекта зависит от зарезервированной высоты нижнего input.
                    .frame(height: inputAreaHeight)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
            
            // Нижняя панель ввода.
            // Настройки: lineLimit, minHeight, cornerRadius, horizontal/bottom padding.
            HStack(alignment: .bottom, spacing: 8) {
                // Многострочное поле ввода.
                // lineLimit(1...15): input растет вверх до 15 строк, потом текст скроллится внутри поля.
                TextField("Сообщение", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .lineLimit(1...13)
                    .padding(.leading, 16)
                    .padding(.vertical, 11)

                // Кнопка отправки. При росте input остается в нижнем правом углу.
                Button {

                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        // Форма кнопки: width больше height = капсула с круглыми боками.
                        .frame(width: 44, height: 34)
                        .background(canSendMessage ? Color.blue : Color.gray.opacity(0.18))
                        .clipShape(Capsule())
                }
                .disabled(!canSendMessage)
                .opacity(canSendMessage ? 1 : 0)
                .padding(.trailing, 6)
                .padding(.bottom, 7)
            }
            .frame(minHeight: 48)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.18), lineWidth: 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { newHeight in
                inputAreaHeight = max(newHeight, minimumInputAreaHeight)
            }
            .animation(.easeInOut(duration: 0.15), value: canSendMessage)
            
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
            messageText = chatDraftStore.draft(for: chatContext.id)
            loadMessages()
        }
        .onChange(of: messageText) {
            chatDraftStore.setDraft(messageText, for: chatContext.id)
        }
    }
    
    // Скроллит чат к единому нижнему якорю.
    // Используем anchor .bottom, чтобы нижний spacer оказался внизу видимой области.
    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
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
    .environmentObject(ChatDraftStore())
}
