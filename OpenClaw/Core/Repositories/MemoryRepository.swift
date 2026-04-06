import Foundation
import os

private let logger = Logger(subsystem: "co.uk.appwebdev.openclaw", category: "MemoryRepo")

protocol MemoryRepository: Sendable {
    func listFiles() async throws -> [MemoryFile]
    func listSkills() async throws -> [SkillFile]
    func listSkillFiles(skillId: String) async throws -> [SkillFileEntry]
    func readFile(path: String) async throws -> MemoryFileContent
    func readSkillFile(skillId: String, relativePath: String) async throws -> String
}

final class RemoteMemoryRepository: MemoryRepository {
    private let client: GatewayClientProtocol
    private let sessionKey: String
    private let workspaceRoot: String

    init(client: GatewayClientProtocol, sessionKey: String, workspaceRoot: String) {
        self.client = client
        self.sessionKey = sessionKey
        self.workspaceRoot = workspaceRoot
    }

    func listFiles() async throws -> [MemoryFile] {
        let response = try await exec("memory-list", args: workspaceRoot)
        return MemoryFile.parse(stdout: response.stdout ?? "")
    }

    func listSkills() async throws -> [SkillFile] {
        let response = try await exec("skills-list", args: workspaceRoot)
        return SkillFile.parse(stdout: response.stdout ?? "")
    }

    func listSkillFiles(skillId: String) async throws -> [SkillFileEntry] {
        let response = try await exec("skill-files", args: skillId)
        return SkillFileEntry.parse(stdout: response.stdout ?? "", skillId: skillId)
    }

    func readSkillFile(skillId: String, relativePath: String) async throws -> String {
        let response = try await exec("skill-read", args: "\(skillId) \(relativePath)")
        guard let stdout = response.stdout, !stdout.isEmpty else {
            throw MemoryError.fileNotFound("\(skillId)/\(relativePath)")
        }
        return stdout
    }

    func readFile(path: String) async throws -> MemoryFileContent {
        let body = MemoryGetToolRequest(path: path, sessionKey: sessionKey)
        let response: MemoryGetResponseDTO = try await client.invoke(body)
        return MemoryFileContent(path: response.path, text: response.text)
    }

    // MARK: - Helpers

    private func exec(_ command: String, args: String? = nil) async throws -> StatsExecResponse {
        let body = StatsExecRequest(command: command, args: args)
        let response: StatsExecResponse = try await client.statsPost("stats/exec", body: body)
        if let exitCode = response.exitCode, exitCode != 0 {
            logger.error("\(command) failed exitCode=\(exitCode) stderr=\(response.stderr ?? "")")
            throw MemoryError.commandFailed(
                command: command,
                exitCode: exitCode,
                stderr: response.stderr ?? ""
            )
        }
        return response
    }
}
