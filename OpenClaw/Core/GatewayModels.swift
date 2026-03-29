import Foundation

/// App-level constants — agent name will be dynamic in the future.
enum AppConstants {
    static let agentId = "orchestrator"
    static let workspaceRoot = "~/.openclaw/workspace/\(agentId)/"
}

/// Well-known session keys.
enum SessionKeys {
    static let main = "agent:\(AppConstants.agentId):main"
    static let cronPrefix = "agent:\(AppConstants.agentId):cron:"
    static let subagentPrefix = "agent:\(AppConstants.agentId):subagent:"
}

// MARK: - Gateway Response Wrapper

/// Actual envelope: {"ok":true,"result":{"content":[{"type":"text","text":"<json string>"}]}}
struct GatewayResponse: Decodable, Sendable {
    struct Result: Decodable, Sendable {
        struct Content: Decodable, Sendable {
            let type: String
            let text: String
        }
        let content: [Content]
    }
    let ok: Bool
    let result: Result
}

// MARK: - Gateway Tool Request

struct GatewayToolRequest: Encodable, Sendable {
    let tool = "gateway"
    let args: Args

    struct Args: Encodable, Sendable {
        let action: String
    }
}

// MARK: - Error Types

struct GatewayErrorEnvelope: Decodable, Sendable {
    struct ErrorDetail: Decodable, Sendable {
        let type: String
        let message: String
    }
    let ok: Bool
    let error: ErrorDetail?
}

enum GatewayError: LocalizedError {
    case noToken
    case invalidResponse
    case httpError(Int, body: String)
    case serverError(Int, type: String, message: String)
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No authentication token. Tap Configure to add your Bearer token."
        case .invalidResponse:
            return "Invalid response from gateway."
        case .httpError(let code, let body):
            return "Gateway HTTP \(code). Response: \(body.isEmpty ? "(empty)" : body)"
        case .serverError(let code, _, let message):
            return "Gateway HTTP \(code): \(message)"
        case .emptyContent:
            return "Gateway returned an empty response."
        }
    }
}

// MARK: - Gateway Command Response

/// Response from a gateway tool command (e.g. restart).
struct GatewayCommandResponse: Decodable, Sendable {
    let message: String?
    let text: String?
}
