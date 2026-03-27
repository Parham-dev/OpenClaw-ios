import Foundation

// MARK: - Gateway Response Wrapper

/// Actual envelope: {"ok":true,"result":{"content":[{"type":"text","text":"<json string>"}]}}
struct GatewayResponse: Decodable {
    struct Result: Decodable {
        struct Content: Decodable {
            let type: String
            let text: String
        }
        let content: [Content]
    }
    let ok: Bool
    let result: Result
}

// MARK: - Request Bodies

struct ExecToolRequest: Encodable, Sendable {
    let tool: String
    let args: Input

    struct Input: Encodable, Sendable {
        let command: String
    }

    init(args: Input) {
        self.tool = "exec"
        self.args = args
    }
}

struct CronToolRequest: Encodable, Sendable {
    let tool: String
    let args: Input

    struct Input: Encodable, Sendable {
        let action: String
    }

    init(args: Input) {
        self.tool = "cron"
        self.args = args
    }
}

struct CronJobToolRequest: Encodable, Sendable {
    let tool = "cron"
    let args: Args

    struct Args: Encodable, Sendable {
        let action: String
        let jobId: String
    }
}

struct CronRunsToolRequest: Encodable, Sendable {
    let tool = "cron"
    let args: Args

    struct Args: Encodable, Sendable {
        let action = "runs"
        let jobId: String
        let limit: Int
        let offset: Int
    }
}

struct CronUpdateToolRequest: Encodable, Sendable {
    let tool = "cron"
    let args: Args

    struct Args: Encodable, Sendable {
        let action = "update"
        let jobId: String
        let patch: Patch
    }

    struct Patch: Encodable, Sendable {
        let enabled: Bool
    }
}

// MARK: - Errors

// MARK: - Gateway Error Envelope

struct GatewayErrorEnvelope: Decodable {
    struct ErrorDetail: Decodable {
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

enum KeychainError: LocalizedError {
    case unhandledError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            return "Keychain error (OSStatus \(status))."
        }
    }
}
