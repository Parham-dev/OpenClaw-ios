import Foundation

@MainActor
final class CronSummaryViewModel: LoadableViewModel<[CronJob]> {
    init(client: GatewayClientProtocol) {
        super.init {
            let body = CronToolRequest(args: .init(action: "list"))
            let response: CronJobListResponse = try await client.invoke(body)
            return response.jobs
        }
    }
}
