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
    
    // Невидимая точка в самом низу списка сообщений.
    // Позже все автоскроллы будут идти именно к ней, а не к последнему сообщению.
    private let bottomAnchorID = "chat-bottom-anchor"
    
    // Высота будущей нижней зоны ввода.
    // Пока input старый, но ленту сообщений уже готовим под floating input.
    private let reservedInputAreaHeight: CGFloat = 72

    // Фиксированный зазор между последним сообщением и input.
    // Это расстояние должно быть одинаковым при первом входе, автоскролле и ручном скролле вниз.
    private let messageInputGap: CGFloat = 8
    
    
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
                            .frame(height: reservedInputAreaHeight + messageInputGap)
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
                    .frame(height: reservedInputAreaHeight)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
            
            HStack {
                TextField("Сообщение", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)

                Button {

                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            
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
}
