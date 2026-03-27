import Foundation

@MainActor
final class SystemHealthViewModel: LoadableViewModel<SystemStats> {
    init(client: GatewayClientProtocol) {
        super.init { try await client.stats("stats/system") }
    }
}
