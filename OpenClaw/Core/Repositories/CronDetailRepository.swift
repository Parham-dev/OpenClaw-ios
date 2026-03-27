import Foundation

struct CronRunsPage: Sendable {
    let runs: [CronRun]
    let hasMore: Bool
}

protocol CronDetailRepository: Sendable {
    func fetchRuns(jobId: String, limit: Int, offset: Int) async throws -> CronRunsPage
    func triggerRun(jobId: String) async throws
    func setEnabled(jobId: String, enabled: Bool) async throws
}

final class RemoteCronDetailRepository: CronDetailRepository {
    private let client: GatewayClientProtocol

    init(client: GatewayClientProtocol) {
        self.client = client
    }

    func fetchRuns(jobId: String, limit: Int, offset: Int) async throws -> CronRunsPage {
        let body = CronRunsToolRequest(args: .init(jobId: jobId, limit: limit, offset: offset))
        let response: CronRunsResponseDTO = try await client.invoke(body)
        let runs = response.entries.map(CronRun.init)
        return CronRunsPage(runs: runs, hasMore: runs.count >= limit)
    }

    func triggerRun(jobId: String) async throws {
        let body = CronJobToolRequest(args: .init(action: "run", jobId: jobId))
        let _: CronRunTriggerResponse = try await client.invoke(body)
    }

    func setEnabled(jobId: String, enabled: Bool) async throws {
        let body = CronUpdateToolRequest(args: .init(jobId: jobId, patch: .init(enabled: enabled)))
        let _: CronUpdateResponse = try await client.invoke(body)
    }
}

private struct CronRunTriggerResponse: Decodable {
    let ok: Bool?
}

private struct CronUpdateResponse: Decodable {
    let ok: Bool?
}
