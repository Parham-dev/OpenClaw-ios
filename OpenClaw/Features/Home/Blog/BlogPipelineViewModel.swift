import Foundation

@MainActor
final class BlogPipelineViewModel: LoadableViewModel<BlogStats> {
    init(client: GatewayClientProtocol) {
        super.init { try await client.stats("stats/blog") }
    }
}
