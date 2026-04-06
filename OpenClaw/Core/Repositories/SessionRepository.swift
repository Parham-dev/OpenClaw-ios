import Foundation
import os

private let logger = Logger(subsystem: "co.uk.appwebdev.openclaw", category: "SessionRepo")

protocol SessionRepository: Sendable {
    @MainActor func fetchSessions(limit: Int) async throws -> [SessionEntry]
    func fetchTrace(sessionKey: String, limit: Int) async throws -> SessionTrace
}

final class RemoteSessionRepository: SessionRepository {
    private let client: GatewayClientProtocol

    init(client: GatewayClientProtocol) {
        self.client = client
    }

    @MainActor
    func fetchSessions(limit: Int) async throws -> [SessionEntry] {
        let body = SessionListToolRequest(args: .init(limit: limit))
        let response: SessionListResponseDTO = try await client.invoke(body)
        logger.debug("fetchSessions OK — \(response.sessions.count) sessions")
        return response.sessions
            .map(SessionEntry.init)
            .sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
    }

    func fetchTrace(sessionKey: String, limit: Int) async throws -> SessionTrace {
        let body = SessionHistoryToolRequest(args: .init(sessionKey: sessionKey, limit: limit, includeTools: true))
        let dto: SessionHistoryDTO = try await client.invoke(body)
        return TraceStep.from(dto: dto)
    }
}
