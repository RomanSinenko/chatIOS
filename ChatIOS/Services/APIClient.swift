import Foundation

struct APIClient {
    // Локальный адрес backend для запуска из iOS Simulator.
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    // Временный вход/регистрация по телефону без SMS.
    func devLogin(phone: String) async throws -> DevLoginResponse {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("dev-login")
        
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "+&=")
        
        guard let encodedPhone = phone.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
            throw APIClientError.invalidResponse
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = "phone=\(encodedPhone)"
        
        guard let fullURL = components?.url else {
            throw APIClientError.invalidResponse
        }
        
        var request = URLRequest(url: fullURL)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(DevLoginResponse.self, from: data)
    }

    
    // Загружает список чатов пользователя.
    func getUserChats(userID: Int) async throws -> [ChatSummary] {
        let url = baseURL
            .appendingPathComponent("users")
            .appendingPathComponent(String(userID))
            .appendingPathComponent("chats")
        
        // Для GET-запроса достаточно URL, отдельный URLRequest не нужен.
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Backend возвращает JSON-массив, поэтому декодируем [ChatSummary].
        return try JSONDecoder().decode([ChatSummary].self, from: data)
    }
}

// Ошибки, которые может вернуть APIClient.
enum APIClientError: Error {
    case invalidResponse
    case serverError(statusCode: Int)
}
