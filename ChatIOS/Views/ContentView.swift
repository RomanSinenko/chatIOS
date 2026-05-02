import SwiftUI

struct ContentView: View {
    // nil значит, что пользователь ещё не вошёл.
    // Когда здесь появляется пользователь, показываем экран чатов.
    @State private var currentUser: ChatUser?
    
    // true, пока iOS ждёт ответ от backend при входе/регистрации.
    @State private var isCreatingUser = false
    
    // Текст ошибки, который показываем на стартовом экране.
    @State private var authErrorMessage: String?
    
    
    // Клиент для HTTP-запросов к backend.
    private let apiClient = APIClient()
    
    var body: some View {
        // NavigationStack нужен, чтобы дочерние экраны могли открывать следующие экраны.
        NavigationStack {
            if let currentUser {
                ChatsListView(userID: currentUser.id) {
                    // Выход очищает пользователя, поэтому SwiftUI снова покажет StartView.
                    self.currentUser = nil
                }
            } else {
                StartView(
                    onContinue: { phone in
                        Task {
                            isCreatingUser = true
                            authErrorMessage = nil
                            
                            // Запускаем временный вход/регистрацию по телефону через backend.
                            do {
                                let loginResponse = try await apiClient.devLogin(phone: phone)
                                currentUser = loginResponse.user
                            } catch {
                                // Если backend ответил ошибочным HTTP-кодом, показываем текст по status code.
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
                            
                            isCreatingUser = false
                        }
                    },
                    isLoading: isCreatingUser,
                    errorMessage: authErrorMessage
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
