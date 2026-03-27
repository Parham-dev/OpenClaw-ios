import Foundation

@MainActor
final class OutreachStatsViewModel: LoadableViewModel<OutreachStats> {
    init(client: GatewayClientProtocol) {
        super.init { try await client.stats("stats/outreach") }
    }
}
