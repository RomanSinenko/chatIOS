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
    
    
    // Загружает историю сообщений конкретного чата.
    func fetchMessages(
        chatID: Int,
        userID: Int
    ) async throws -> [BackendChatMessage] {
        let url = baseURL
            .appendingPathComponent("chats")
            .appendingPathComponent(String(chatID))
            .appendingPathComponent("messages")
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: String(userID)),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        guard let fullURL = components?.url else {
            throw APIClientError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: fullURL)
        
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
            // Для поля Date decoder получает одно JSON-значение: строку created_at.
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Первый форматтер читает даты с долями секунды, например .081.
            let formatterWithFractionalSeconds = ISO8601DateFormatter()
            formatterWithFractionalSeconds.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]
            
            if let date = formatterWithFractionalSeconds.date(from: dateString) {
                return date
            }
            
            // Второй форматтер нужен как запасной вариант для даты без миллисекунд.
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Если оба формата не подошли, явно падаем с понятным описанием.
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        
        return try decoder.decode([BackendChatMessage].self, from: data)
    }
    
    
    // Ищет пользователя по точному public/custom username.
    func searchUsers(query: String) async throws -> [UserSearchResult] {
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
        
        let (data, response) = try await URLSession.shared.data(from: fullURL)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([UserSearchResult].self, from: data)
    }
    
    // Создает или получает private chat между текущим пользователем и найденным пользователем.
    func getOrCreatePrivateChat(
        currentUserID: Int,
        peerUserID: Int
    ) async throws -> PrivateChatResponse {
        let url = baseURL
            .appendingPathComponent("private-chats")
            .appendingPathComponent(String(currentUserID))
            .appendingPathComponent(String(peerUserID))
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        print("POST private chat url: \(url)")
        
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
