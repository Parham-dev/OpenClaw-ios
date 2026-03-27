import Foundation

@MainActor
final class BlogPipelineViewModel: LoadableViewModel<BlogStats> {
    nonisolated init(client: GatewayClientProtocol) {
        super.init { try await client.stats("stats/blog") }
    }
}
