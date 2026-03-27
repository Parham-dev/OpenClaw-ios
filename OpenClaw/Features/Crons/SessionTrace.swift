import Foundation

/// A parsed session history ready for display.
struct SessionTrace: Sendable {
    let sessionKey: String
    let steps: [TraceStep]
    let truncated: Bool
}

/// A single step in the agent execution trace.
struct TraceStep: Sendable, Identifiable {
    let id: String
    let kind: Kind
    let timestamp: Date?
    let model: String?

    enum Kind: Sendable {
        case thinking(text: String)
        case text(text: String)
        case toolCall(callId: String, toolName: String, argsSummary: String)
        case toolResult(callId: String, toolName: String, output: String, isError: Bool)
    }

    var iconName: String {
        switch kind {
        case .thinking:   "brain.head.profile"
        case .text:       "text.bubble"
        case .toolCall:   "terminal"
        case .toolResult: "doc.text"
        }
    }

    var title: String {
        switch kind {
        case .thinking:                    "Thinking"
        case .text:                        "Response"
        case .toolCall(_, let name, _):    name
        case .toolResult(_, let name, _, _): "\(name) result"
        }
    }

    var timestampFormatted: String? {
        guard let timestamp else { return nil }
        return Formatters.absoluteString(for: timestamp)
    }

    /// Parse a full session history DTO into an ordered list of trace steps.
    static func from(dto: SessionHistoryDTO) -> SessionTrace {
        var steps: [TraceStep] = []
        var seq = 0

        for message in dto.messages {
            let ts = message.timestamp.map { Date(timeIntervalSince1970: Double($0) / 1000) }

            switch message.role {
            case "assistant":
                for item in message.content ?? [] {
                    seq += 1
                    let stepId = "\(dto.sessionKey)-\(seq)"

                    switch item.type {
                    case "thinking":
                        if let text = item.thinking, !text.isEmpty {
                            steps.append(TraceStep(id: stepId, kind: .thinking(text: text), timestamp: ts, model: message.model))
                        }
                    case "toolCall":
                        steps.append(TraceStep(
                            id: stepId,
                            kind: .toolCall(
                                callId: item.id ?? "",
                                toolName: item.name ?? "unknown",
                                argsSummary: item.arguments?.summary ?? ""
                            ),
                            timestamp: ts,
                            model: message.model
                        ))
                    case "text":
                        if let text = item.text, !text.isEmpty {
                            steps.append(TraceStep(id: stepId, kind: .text(text: text), timestamp: ts, model: message.model))
                        }
                    default:
                        break
                    }
                }

            case "toolResult":
                seq += 1
                let output = (message.content ?? []).compactMap(\.text).joined(separator: "\n")
                steps.append(TraceStep(
                    id: "\(dto.sessionKey)-\(seq)",
                    kind: .toolResult(
                        callId: message.toolCallId ?? "",
                        toolName: message.toolName ?? "unknown",
                        output: output,
                        isError: message.isError ?? false
                    ),
                    timestamp: ts,
                    model: nil
                ))

            default:
                break
            }
        }

        return SessionTrace(
            sessionKey: dto.sessionKey,
            steps: steps,
            truncated: dto.truncated ?? false
        )
    }
}
