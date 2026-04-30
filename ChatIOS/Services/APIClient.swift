import Foundation

struct APIClient {
    // Локальный адрес backend для запуска из iOS Simulator.
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    // Создаёт пользователя через backend и возвращает ChatUser.
    func createUser(userName: String) async throws -> ChatUser {
        let url = baseURL
            .appendingPathComponent("users")
            .appendingPathComponent(userName)
        
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Проверяем, что ответ действительно HTTP-ответ.
        guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIClientError.invalidResponse
        }
        
        // Любой код вне 200...299 считаем backend-ошибкой.
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Превращаем JSON-ответ backend в Swift-модель ChatUser.
        return try JSONDecoder().decode(ChatUser.self, from: data)
    }
}

// Ошибки, которые может вернуть APIClient.
enum APIClientError: Error {
    case invalidResponse
    case serverError(statusCode: Int)
}
