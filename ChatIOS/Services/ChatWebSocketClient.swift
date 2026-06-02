import Foundation
import Combine

final class ChatWebSocketClient: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private let decoder = JSONDecoder.backendMessageDecoder()

    // Открывает WebSocket-соединение с Authorization.
    func connect(sessionToken: String, realtimeStore: ChatRealtimeStore) {
        disconnect()

        guard let url = URL(string: "ws://127.0.0.1:8000/ws") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")

        let socketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask = socketTask
        socketTask.resume()

        receiveTask = Task { [weak self] in
            await self?.receiveLoop(
                socketTask: socketTask,
                realtimeStore: realtimeStore
            )
        }
    }

    // Закрывает WebSocket и останавливает прием сообщений.
    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    // Постоянно слушает входящие события WebSocket.
    private func receiveLoop(
        socketTask: URLSessionWebSocketTask,
        realtimeStore: ChatRealtimeStore
    ) async {
        while !Task.isCancelled {
            do {
                let socketMessage = try await socketTask.receive()
                handleSocketMessage(
                    socketMessage,
                    realtimeStore: realtimeStore
                )
            } catch {
                guard !Task.isCancelled else { return }

                print("WebSocket receive failed: \(error)")
                return
            }
        }
    }

    // Разбирает JSON-событие и передает новое сообщение в store.
    private func handleSocketMessage(
        _ socketMessage: URLSessionWebSocketTask.Message,
        realtimeStore: ChatRealtimeStore
    ) {
        guard case .string(let text) = socketMessage else { return }
        guard let data = text.data(using: .utf8) else { return }

        do {
            let event = try decoder.decode(ChatWebSocketEvent.self, from: data)

            if event.type == "message", let message = event.message {
                realtimeStore.receiveMessage(message)
            }
        } catch {
            print("Decode WebSocket event failed: \(error)")
        }
    }
}
