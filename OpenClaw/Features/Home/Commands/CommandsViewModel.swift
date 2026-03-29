import Foundation
import Observation

@Observable
@MainActor
final class CommandsViewModel {
    var isRunning: [String: Bool] = [:]
    var result: CommandResult?
    var isInvestigating = false
    var investigateResponse: ChatCompletionResponse?
    var investigateError: Error?

    private let client: GatewayClientProtocol
    private let cronRepository: CronRepository?
    private let cronDetailRepository: CronDetailRepository?

    init(client: GatewayClientProtocol, cronRepository: CronRepository? = nil, cronDetailRepository: CronDetailRepository? = nil) {
        self.client = client
        self.cronRepository = cronRepository
        self.cronDetailRepository = cronDetailRepository
    }

    func execute(_ command: QuickCommand) async {
        isRunning[command.id] = true
        do {
            let output: String
            switch command.toolName {
            case "stats-exec":
                output = try await executeStatsExec(command)
            case "gateway":
                output = try await executeGateway(command)
            case "pause-all-crons":
                output = try await pauseAllCrons()
            default:
                output = "Unknown tool: \(command.toolName)"
            }
            result = CommandResult(command: command, isSuccess: true, output: output)
            Haptics.shared.success()
        } catch {
            result = CommandResult(command: command, isSuccess: false, output: error.localizedDescription)
            Haptics.shared.error()
        }
        isRunning[command.id] = false
    }

    func isCommandRunning(_ id: String) -> Bool {
        isRunning[id] ?? false
    }

    // MARK: - Executors

    private func executeStatsExec(_ command: QuickCommand) async throws -> String {
        let body = StatsExecRequest(command: command.args["command"] ?? "")
        let response: StatsExecResponse = try await client.statsPost("stats/exec", body: body)
        let combined = [response.stdout, response.stderr]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n---\n\n")
        let isFailure = response.exitCode != 0
        if isFailure && combined.isEmpty {
            return "Command failed with exit code \(response.exitCode ?? -1)"
        }
        return Self.stripAnsi(combined.isEmpty ? "Command completed." : combined)
    }

    private func executeGateway(_ command: QuickCommand) async throws -> String {
        let body = GatewayToolRequest(args: .init(action: command.args["action"] ?? ""))
        let response: GatewayCommandResponse = try await client.invoke(body)
        return response.message ?? response.text ?? "Gateway command completed."
    }

    private func pauseAllCrons() async throws -> String {
        guard let repo = cronRepository else { return "Cron repository not available." }
        guard let detailRepo = cronDetailRepository else { return "Cron detail repository not available." }
        let jobs = try await repo.fetchJobs()
        let enabledJobs = jobs.filter(\.enabled)
        guard !enabledJobs.isEmpty else { return "No enabled cron jobs to pause." }

        var paused = 0
        var failed = 0
        for job in enabledJobs {
            do {
                try await detailRepo.setEnabled(jobId: job.id, enabled: false)
                paused += 1
            } catch {
                failed += 1
            }
        }

        if failed == 0 {
            return "Paused all \(paused) cron jobs."
        } else {
            return "Paused \(paused) jobs, \(failed) failed to pause."
        }
    }

    func investigateResult(_ result: CommandResult) async {
        isInvestigating = true
        investigateError = nil
        investigateResponse = nil

        let prompt = PromptTemplates.investigateCommandResult(
            commandName: result.command.name,
            output: result.output,
            isSuccess: result.isSuccess
        )

        let request = ChatCompletionRequest(system: prompt.system, user: prompt.user)

        do {
            let response = try await client.chatCompletion(request, sessionKey: SessionKeys.main)
            investigateResponse = response
            Haptics.shared.success()
        } catch {
            investigateError = error
            Haptics.shared.error()
        }
        isInvestigating = false
    }

    /// Strip ANSI escape codes from terminal output.
    static func stripAnsi(_ text: String) -> String {
        text.replacingOccurrences(
            of: "\\x1B\\[[0-9;]*[a-zA-Z]",
            with: "",
            options: .regularExpression
        )
        .replacingOccurrences(
            of: "\\x1B\\([a-zA-Z]",
            with: "",
            options: .regularExpression
        )
    }
}

// MARK: - Models

struct CommandResult: Identifiable {
    let id = UUID()
    let command: QuickCommand
    let isSuccess: Bool
    let output: String
}

