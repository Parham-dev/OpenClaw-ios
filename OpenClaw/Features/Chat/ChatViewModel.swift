import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var isStreaming = false
    var isLoadingHistory = false
    var error: Error?

    private let client: GatewayClientProtocol
    private let sessionKey = "agent:orchestrator:main"
    private var streamTask: Task<Void, Never>?
    private var historyLoaded = false
    private var hasPendingSend = false

    init(client: GatewayClientProtocol) {
        self.client = client
    }

    // MARK: - Load History

    func loadHistory() async {
        guard !historyLoaded else { return }
        historyLoaded = true
        isLoadingHistory = true

        do {
            let body = SessionHistoryToolRequest(args: .init(sessionKey: sessionKey, limit: 50, includeTools: false))
            let dto: SessionHistoryDTO = try await client.invoke(body)

            var loaded: [ChatMessage] = []
            for message in dto.messages {
                switch message.role {
                case "user":
                    let text = (message.content ?? []).compactMap(\.text).joined(separator: "\n")
                    if !text.isEmpty {
                        loaded.append(ChatMessage(role: .user, content: text))
                    }
                case "assistant":
                    let text = (message.content ?? [])
                        .filter { $0.type == "text" }
                        .compactMap(\.text)
                        .joined(separator: "\n")
                    if !text.isEmpty {
                        loaded.append(ChatMessage(role: .assistant, content: text))
                    }
                default:
                    break
                }
            }

            if !hasPendingSend {
                messages = loaded
            }
        } catch {
            self.error = error
        }
        isLoadingHistory = false
    }

    // MARK: - Send

    func send(_ text: String) {
        hasPendingSend = true

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        let assistantMessage = ChatMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        let assistantId = assistantMessage.id

        isStreaming = true
        error = nil

        streamTask = Task {
            do {
                let stream = client.streamChat(message: text, sessionKey: sessionKey)
                for try await delta in stream {
                    guard let idx = messages.firstIndex(where: { $0.id == assistantId }) else { break }
                    messages[idx].content += delta
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
                Haptics.shared.success()
            } catch is CancellationError {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
            } catch {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                    if messages[idx].content.isEmpty {
                        messages.remove(at: idx)
                    }
                }
                self.error = error
                Haptics.shared.error()
            }
            isStreaming = false
            hasPendingSend = false
        }
    }

    func reloadHistory() {
        historyLoaded = false
        hasPendingSend = false
        messages = []
        Task { await loadHistory() }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
    }
}
