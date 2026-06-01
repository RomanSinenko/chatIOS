import SwiftUI

struct ChatView: View {
    // MARK: - Input

    let chatContext: ChatScreenContext
    let sessionToken: String

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chatDraftStore: ChatDraftStore
    @EnvironmentObject private var chatScrollPositionStore: ChatScrollPositionStore

    // MARK: - State

    @State private var messageText = ""
    @State private var messages: [BackendChatMessage] = []
    @State private var isLoadingMessages = false
    @State private var messagesErrorMessage: String?

    @State private var inputAreaHeight: CGFloat = 72

    @State private var isAtBottom = true
    @State private var hasOpenedInitialPosition = false
    @State private var newIncomingMessagesCount = 0

    @State private var scrollViewportHeight: CGFloat = 0
    @State private var bottomAnchorMaxY: CGFloat = 0

    // MARK: - Dependencies

    private let apiClient = APIClient()

    // MARK: - Layout Settings

    private let bottomAnchorID = "chat-bottom-anchor"
    private let minimumInputAreaHeight: CGFloat = 72
    private let messageInputGap: CGFloat = 8
    private let bottomDetectionTolerance: CGFloat = 12

    // MARK: - Computed Properties

    // Готовит текст к отправке: убирает пробелы по краям.
    private var trimmedMessageText: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Управляет состоянием кнопки отправки.
    private var canSendMessage: Bool {
        !trimmedMessageText.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            messagesScrollView
            errorOverlay
            bottomMaterialOverlay
            inputBar
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            chatToolbar
        }
        .onAppear {
            handleAppear()
        }
        .onChange(of: messageText) {
            saveDraft()
        }
    }

    // MARK: - Messages

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    messagesContent
                    bottomSpacer
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .onChange(of: isLoadingMessages) {
                openInitialScrollPosition(proxy)
            }
            .onScrollTargetVisibilityChange(idType: Int.self) { visibleIDs in
                updateVisibleMessages(visibleIDs)
            }
            .overlay(alignment: .bottomTrailing) {
                scrollDownButton(proxy)
            }
            .animation(.easeInOut(duration: 0.1), value: isAtBottom)
        }
    }

    @ViewBuilder
    private var messagesContent: some View {
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
                messageRow(message)
                    .id(message.id)
            }
        }
    }

    private func messageRow(_ message: BackendChatMessage) -> some View {
        let isMine = message.senderID == chatContext.currentUserID

        return HStack {
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

    private var bottomSpacer: some View {
        Color.clear
            .frame(height: inputAreaHeight + messageInputGap)
            .id(bottomAnchorID)
    }

    // MARK: - Overlays

    @ViewBuilder
    private var errorOverlay: some View {
        if messagesErrorMessage != nil {
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
    }

    // Нижний blur/material поверх сообщений.
    private var bottomMaterialOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            Rectangle()
                .fill(.thinMaterial)
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
                .frame(height: inputAreaHeight)
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }

    // MARK: - Input

    // Нижняя панель ввода.
    // Настройки: lineLimit, minHeight, cornerRadius, horizontal/bottom padding.
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Поле ввода.
            TextField("Сообщение", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .lineLimit(1...13)
                .padding(.leading, 16)
                .padding(.vertical, 11)

            // Кнопка отправки.
            sendButton
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
    
    // Кнопка быстрого перехода к последнему сообщению.
    @ViewBuilder
    private func scrollDownButton(_ proxy: ScrollViewProxy) -> some View {
        if !isAtBottom {
            Button {
                scrollToBottom(proxy)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44) // Размер кнопки.
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, inputAreaHeight + 8) // Отступ от верхней границы input.
            .transition(.opacity)
        }
    }

    private var sendButton: some View {
        Button {

        } label: {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 34)
                .background(canSendMessage ? Color.blue : Color.gray.opacity(0.18))
                .clipShape(Capsule())
        }
        .disabled(!canSendMessage)
        .opacity(canSendMessage ? 1 : 0)
        .padding(.trailing, 6)
        .padding(.bottom, 7)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var chatToolbar: some ToolbarContent {
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

        ToolbarItem(placement: .principal) {
            Text(chatContext.displayName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.black)
                .lineLimit(1)
        }
    }

    // MARK: - Actions

    private func handleAppear() {
        messageText = chatDraftStore.draft(for: chatContext.id)
        loadMessages()
    }

    private func saveDraft() {
        chatDraftStore.setDraft(messageText, for: chatContext.id)
    }

    // Открывает чат после первой загрузки истории.
    private func openInitialScrollPosition(_ proxy: ScrollViewProxy) {
        guard !hasOpenedInitialPosition else { return }
        guard !isLoadingMessages else { return }
        guard !messages.isEmpty else { return }

        hasOpenedInitialPosition = true

        DispatchQueue.main.async {
            switch chatScrollPositionStore.position(for: chatContext.id) {
            case .message(let messageID):
                proxy.scrollTo(messageID, anchor: .bottom)

            case .bottom, nil:
                chatScrollPositionStore.setPosition(.bottom, for: chatContext.id)
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        }
    }

    // Обновляет флаг нижней позиции по положению bottom anchor.
    private func updateIsAtBottom() {
        guard scrollViewportHeight > 0 else { return }

        isAtBottom = bottomAnchorMaxY <= scrollViewportHeight + bottomDetectionTolerance

        if isAtBottom {
            newIncomingMessagesCount = 0
        }
    }
    
    // Обновляет scroll-позицию по видимым сообщениям.
    private func updateVisibleMessages(_ visibleIDs: [Int]) {
        guard hasOpenedInitialPosition else { return }

        let lastMessageID = messages.last?.id
        let isLastMessageVisible = lastMessageID.map { visibleIDs.contains($0) } ?? false

        isAtBottom = isLastMessageVisible

        if isLastMessageVisible {
            newIncomingMessagesCount = 0
            chatScrollPositionStore.setPosition(.bottom, for: chatContext.id)
            return
        }

        if let messageID = visibleIDs.last {
            chatScrollPositionStore.setPosition(.message(id: messageID), for: chatContext.id)
        }
    }
    
    // Скроллит чат вниз по нажатию кнопки.
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }

        chatScrollPositionStore.setPosition(.bottom, for: chatContext.id)
        isAtBottom = true
        newIncomingMessagesCount = 0
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
    .environmentObject(ChatScrollPositionStore())
}
