import Foundation
import Observation

@Observable
@MainActor
final class AdminViewModel {
    var modelsConfig: ModelsConfig?
    var agents: [AgentInfo] = []
    var channelsStatus: ChannelsStatus?
    var isLoading = false
    var error: Error?

    private let client: GatewayClientProtocol

    init(client: GatewayClientProtocol) {
        self.client = client
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        async let m = fetchModels()
        async let a = fetchAgents()
        async let c = fetchChannels()

        let (models, agentList, channels) = await (m, a, c)
        modelsConfig = models
        agents = agentList
        channelsStatus = channels
    }

    // MARK: - Fetchers (nonisolated for parallelism)

    private nonisolated func fetchModels() async -> ModelsConfig? {
        do {
            let response: StatsExecResponse = try await client.statsPost(
                "stats/exec", body: StatsExecRequest(command: "models-status")
            )
            guard let data = response.stdout?.data(using: .utf8) else { return nil }
            return ModelsConfig(dto: try JSONDecoder().decode(ModelsStatusDTO.self, from: data))
        } catch {
            return nil
        }
    }

    private nonisolated func fetchAgents() async -> [AgentInfo] {
        do {
            let response: StatsExecResponse = try await client.statsPost(
                "stats/exec", body: StatsExecRequest(command: "agents-list")
            )
            guard let data = response.stdout?.data(using: .utf8) else { return [] }
            return try JSONDecoder().decode([AgentDTO].self, from: data).map(AgentInfo.init)
        } catch {
            return []
        }
    }

    private nonisolated func fetchChannels() async -> ChannelsStatus? {
        do {
            let response: StatsExecResponse = try await client.statsPost(
                "stats/exec", body: StatsExecRequest(command: "channels-list")
            )
            guard let data = response.stdout?.data(using: .utf8) else { return nil }
            return ChannelsStatus(dto: try JSONDecoder().decode(ChannelsListDTO.self, from: data))
        } catch {
            return nil
        }
    }
}
