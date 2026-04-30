import SwiftUI

struct ContentView: View {
    // nil значит, что пользователь ещё не вошёл.
    // Когда здесь появляется имя, показываем экран чатов.
    @State private var currentUser: ChatUser?
    
    // true, пока iOS ждёт ответ от backend при создании пользователя.
    @State private var isCreatingUser = false
    
    // Текст ошибки, который показываем на стартовом экране.
    @State private var authErrorMessage: String?
    
    
    // Клиент для HTTP-запросов к backend.
    private let apiClient = APIClient()
    
    var body: some View {
        // NavigationStack нужен, чтобы дочерние экраны могли открывать следующие экраны.
        NavigationStack {
            if let currentUser {
                ChatsListView(userName: currentUser.userName) {
                    // Выход очищает пользователя, поэтому SwiftUI снова покажет StartView.
                    self.currentUser = nil
                }
            } else {
                StartView(
                    onContinue: { userName in
                        Task {
                            isCreatingUser = true
                            authErrorMessage = nil
                            
                            // Запускаем создание пользователя в backend.
                            do {
                                let user = try await apiClient.createUser(userName: userName)
                                currentUser = user
                            } catch {
                                // Если backend ответил ошибочным HTTP-кодом, показываем текст по status code.
                                if case APIClientError.serverError(let statusCode) = error {
                                    switch statusCode {
                                    case 400:
                                        authErrorMessage = "Имя должно быть от 3 до 30 символов (А-Я,а-я, A-Z, a-z, _, -"
                                    case 409:
                                        authErrorMessage = "Имя пользователя уже занято, выберите другое"
                                    default:
                                        authErrorMessage = "Ошибка сервера: \(statusCode)"
                                    }
                                } else {
                                    authErrorMessage = "Не удалось подключиться к серверу"
                                }
                                
                                print("Create user failed: \(error)")
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
