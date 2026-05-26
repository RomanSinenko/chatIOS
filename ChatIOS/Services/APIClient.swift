import Foundation


// Тело запроса для временного входа по телефону.
private struct DevLoginRequest: Encodable {
    let phone: String
}


// Тело запроса для создания или получения private chat.
// Собеседника отправляем в body, а текущего пользователя backend берёт из token.
private struct PrivateChatRequest: Encodable {
    let peerUserID: Int
    
    enum CodingKeys: String, CodingKey {
        case peerUserID = "peer_user_id"
    }
}


struct APIClient {
    // Локальный адрес backend для запуска из iOS Simulator.
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    // Временный вход/регистрация по телефону без SMS.
    func devLogin(phone: String) async throws -> DevLoginResponse {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("dev-login")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = DevLoginRequest(phone: phone)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(DevLoginResponse.self, from: data)
    }

    
    // Загружает список чатов текущего пользователя.
    // Backend определяет пользователя по Authorization token.
    func getUserChats(sessionToken: String) async throws -> [ChatSummary] {
        let url = baseURL
            .appendingPathComponent("users")
            .appendingPathComponent("me")
            .appendingPathComponent("chats")
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([ChatSummary].self, from: data)
    }
    
    
    // Загружает историю сообщений конкретного чата.
    // Backend определяет текущего пользователя по Authorization token.
    func fetchMessages(
        chatID: Int,
        sessionToken: String
    ) async throws -> [BackendChatMessage] {
        let url = baseURL
            .appendingPathComponent("chats")
            .appendingPathComponent(String(chatID))
            .appendingPathComponent("messages")
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: "0")
        ]
        
        guard let fullURL = components?.url else {
            throw APIClientError.invalidResponse
        }
        
        var request = URLRequest(url: fullURL)
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // История сообщений содержит даты, поэтому настраиваем decoder отдельно.
        // Backend может вернуть ISO-дату как с миллисекундами, так и без них.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatterWithFractionalSeconds = ISO8601DateFormatter()
            formatterWithFractionalSeconds.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]
            
            if let date = formatterWithFractionalSeconds.date(from: dateString) {
                return date
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        
        return try decoder.decode([BackendChatMessage].self, from: data)
    }

    
    // Ищет пользователя по точному public/custom username.
    // Backend проверяет текущего пользователя по Authorization token.
    func searchUsers(
        query: String,
        sessionToken: String
    ) async throws -> [UserSearchResult] {
        let url = baseURL
            .appendingPathComponent("users")
            .appendingPathComponent("search")
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let fullURL = components?.url else {
            throw APIClientError.invalidResponse
        }
        
        var request = URLRequest(url: fullURL)
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([UserSearchResult].self, from: data)
    }

    
    // Создает или получает private chat между текущим пользователем и найденным пользователем.
    // Текущий пользователь определяется по Authorization token.
    func getOrCreatePrivateChat(
        peerUserID: Int,
        sessionToken: String
    ) async throws -> PrivateChatResponse {
        let url = baseURL
            .appendingPathComponent("private-chats")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        let body = PrivateChatRequest(peerUserID: peerUserID)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(PrivateChatResponse.self, from: data)
    }
}

// Ошибки, которые может вернуть APIClient.
enum APIClientError: Error {
    case invalidResponse
    case serverError(statusCode: Int)
}
