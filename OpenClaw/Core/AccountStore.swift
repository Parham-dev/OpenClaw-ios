import Foundation
import Observation
import os

private let logger = Logger(subsystem: "co.uk.appwebdev.openclaw", category: "AccountStore")

/// A configured gateway instance.
struct GatewayAccount: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var url: String
    var agentId: String
    /// Workspace path override. Empty string means auto-derive from agentId.
    var workspacePath: String

    var displayURL: String {
        URL(string: url)?.host() ?? url
    }

    /// Resolved workspace root used in prompts.
    /// Custom path if set, otherwise `~/.openclaw/workspace/{agentId}/`.
    var workspaceRoot: String {
        if !workspacePath.isEmpty { return workspacePath }
        return "~/.openclaw/workspace/\(agentId)/"
    }

    var sessionKeyMain: String { "agent:\(agentId):main" }
    var sessionKeyCronPrefix: String { "agent:\(agentId):cron:" }
    var sessionKeySubagentPrefix: String { "agent:\(agentId):subagent:" }

    init(name: String, url: String, agentId: String = "orchestrator", workspacePath: String = "") {
        self.id = UUID().uuidString
        self.name = name
        self.url = url
        self.agentId = agentId
        self.workspacePath = workspacePath
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        url = try c.decode(String.self, forKey: .url)
        agentId = try c.decodeIfPresent(String.self, forKey: .agentId) ?? "orchestrator"
        workspacePath = try c.decodeIfPresent(String.self, forKey: .workspacePath) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, url, agentId, workspacePath
    }
}

/// Manages multiple gateway accounts. Persists to UserDefaults.
@Observable
@MainActor
final class AccountStore {
    private(set) var accounts: [GatewayAccount] = []
    private(set) var activeAccountId: String?

    private static let accountsKey = "gateway_accounts"
    private static let activeKey = "gateway_active_account"

    var activeAccount: GatewayAccount? {
        accounts.first { $0.id == activeAccountId }
    }

    var isConfigured: Bool { activeAccount != nil }

    init() {
        load()
    }

    // MARK: - Add

    func add(name: String, url: String, token: String, agentId: String = "orchestrator", workspacePath: String = "") throws {
        var cleanURL = url.trimmingCharacters(in: .whitespaces)
        if cleanURL.hasSuffix("/") { cleanURL = String(cleanURL.dropLast()) }
        if !cleanURL.hasPrefix("http") { cleanURL = "https://\(cleanURL)" }

        var cleanWS = workspacePath.trimmingCharacters(in: .whitespaces)
        if !cleanWS.isEmpty && !cleanWS.hasSuffix("/") { cleanWS += "/" }

        let account = GatewayAccount(name: name.trimmingCharacters(in: .whitespaces), url: cleanURL, agentId: agentId, workspacePath: cleanWS)
        try KeychainService.saveToken(token.trimmingCharacters(in: .whitespaces), forAccount: account.id)
        accounts.append(account)
        activeAccountId = account.id
        save()
    }

    // MARK: - Switch

    func setActive(_ id: String) {
        guard accounts.contains(where: { $0.id == id }) else { return }
        activeAccountId = id
        UserDefaults.standard.set(id, forKey: Self.activeKey)
        AppConstants.account = activeAccount
    }

    // MARK: - Delete

    func delete(_ id: String) {
        try? KeychainService.deleteToken(forAccount: id)
        accounts.removeAll { $0.id == id }
        if activeAccountId == id {
            activeAccountId = accounts.first?.id
        }
        save()
    }

    // MARK: - Token for active account

    func activeToken() -> String? {
        guard let id = activeAccountId else { return nil }
        return KeychainService.readToken(forAccount: id)
    }

    func activeBaseURL() -> URL? {
        guard let account = activeAccount else { return nil }
        return URL(string: account.url)
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.accountsKey),
           let decoded = try? JSONDecoder().decode([GatewayAccount].self, from: data) {
            accounts = decoded
        }
        activeAccountId = UserDefaults.standard.string(forKey: Self.activeKey) ?? accounts.first?.id

        // Migration: import legacy single-account config
        if accounts.isEmpty {
            migrateFromLegacy()
        }

        AppConstants.account = activeAccount
        if let acct = activeAccount {
            logger.info("Account loaded: \(acct.name), agentId=\(acct.agentId)")
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: Self.accountsKey)
        }
        if let id = activeAccountId {
            UserDefaults.standard.set(id, forKey: Self.activeKey)
        }
    }

    /// One-time migration from the old single-account GatewayConfig + KeychainService.
    private func migrateFromLegacy() {
        guard let urlStr = UserDefaults.standard.string(forKey: "gateway_base_url"),
              let token = KeychainService.readLegacyToken() else { return }

        let host = URL(string: urlStr)?.host() ?? "Gateway"
        let account = GatewayAccount(name: host, url: urlStr)
        try? KeychainService.saveToken(token, forAccount: account.id)
        accounts.append(account)
        activeAccountId = account.id
        save()

        // Clean up legacy
        UserDefaults.standard.removeObject(forKey: "gateway_base_url")
        try? KeychainService.deleteLegacyToken()
    }
}
