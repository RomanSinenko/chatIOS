import SwiftUI

struct ContentView: View {
    // MARK: - State

    @State private var currentUser: ChatUser?
    @State private var sessionToken: String?
    @State private var isCreatingUser = false
    @State private var authErrorMessage: String?

    // MARK: - Dependencies

    private let apiClient = APIClient()

    // MARK: - Shared Stores

    @StateObject private var chatDraftStore = ChatDraftStore()
    @StateObject private var chatScrollPositionStore = ChatScrollPositionStore()
    @StateObject private var chatRealtimeStore = ChatRealtimeStore()
    @StateObject private var chatWebSocketClient = ChatWebSocketClient()
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            rootContent
        }
        .environmentObject(chatDraftStore)
        .environmentObject(chatScrollPositionStore)
        .environmentObject(chatRealtimeStore)
    }

    // MARK: - Content

    @ViewBuilder
    private var rootContent: some View {
        if let currentUser, let sessionToken {
            ChatsListView(
                userID: currentUser.id,
                sessionToken: sessionToken,
                onLogout: logout
            )
        } else {
            StartView(
                onContinue: login,
                isLoading: isCreatingUser,
                errorMessage: authErrorMessage
            )
        }
    }

    // MARK: - Actions

    // Выполняет временный вход по телефону.
    private func login(phone: String) {
        Task {
            isCreatingUser = true
            authErrorMessage = nil

            do {
                let loginResponse = try await apiClient.devLogin(phone: phone)
                currentUser = loginResponse.user
                sessionToken = loginResponse.sessionToken

                chatWebSocketClient.connect(
                    sessionToken: loginResponse.sessionToken,
                    realtimeStore: chatRealtimeStore
                )
            } catch {
                handleLoginError(error)
            }

            isCreatingUser = false
        }
    }

    // Очищает локальное состояние авторизации.
    private func logout() {
        chatWebSocketClient.disconnect()
        chatRealtimeStore.clearLatestMessage()

        currentUser = nil
        sessionToken = nil
    }

    // Преобразует ошибку входа в текст для StartView.
    private func handleLoginError(_ error: Error) {
        if case APIClientError.serverError(let statusCode) = error {
            switch statusCode {
            case 400, 422:
                authErrorMessage = "Проверьте телефон"
            default:
                authErrorMessage = "Ошибка сервера: \(statusCode)"
            }
        } else {
            authErrorMessage = "Не удалось подключиться к серверу"
        }

        print("Dev login failed: \(error)")
    }
}

#Preview {
    ContentView()
}
