import Foundation
import SwiftUI

struct ToolsConfig: Sendable {
    let profile: String
    let allow: [String]
    let deny: [String]
    let mcpServerNames: [String]
    let groups: [ToolGroup]

    struct ToolGroup: Sendable, Identifiable {
        let id: String
        let name: String
        let icon: String
        let tools: [NativeTool]
    }

    struct NativeTool: Sendable, Identifiable {
        let id: String
        let name: String
        let description: String
    }

    var profileColor: Color {
        switch profile {
        case "full":      AppColors.success
        case "coding":    AppColors.primaryAction
        case "messaging": AppColors.metricTertiary
        case "minimal":   AppColors.metricWarm
        default:          AppColors.neutral
        }
    }

    init(dto: ToolsListDTO) {
        profile = dto.profile ?? "unknown"
        allow = dto.allow ?? []
        deny = dto.deny ?? []
        mcpServerNames = dto.mcpServers ?? []

        let iconMap: [String: (name: String, icon: String)] = [
            "runtime":    ("Runtime",    "terminal"),
            "fs":         ("Files",      "doc.text"),
            "web":        ("Web",        "globe"),
            "ui":         ("UI",         "macwindow"),
            "messaging":  ("Messaging",  "message"),
            "automation": ("Automation", "clock.arrow.circlepath"),
            "nodes":      ("Nodes",      "iphone.radiowaves.left.and.right"),
            "media":      ("Media",      "photo"),
            "sessions":   ("Sessions",   "person.2"),
            "memory":     ("Memory",     "brain"),
        ]

        var grouped: [String: [NativeTool]] = [:]
        for tool in dto.native ?? [] {
            let group = tool.group ?? "other"
            grouped[group, default: []].append(
                NativeTool(id: tool.name, name: tool.name, description: tool.description ?? "")
            )
        }

        groups = grouped.keys.sorted().map { key in
            let info = iconMap[key] ?? (name: key.capitalized, icon: "puzzlepiece")
            return ToolGroup(id: key, name: info.name, icon: info.icon, tools: grouped[key] ?? [])
        }
    }
}

struct McpServer: Sendable, Identifiable {
    let id: String
    let name: String
    let runtime: String

    init(name: String, config: McpListDTO.ServerConfig) {
        self.id = name
        self.name = name
        let args = config.args?.joined(separator: " ") ?? ""
        self.runtime = [config.command, args].filter { !($0 ?? "").isEmpty }.compactMap { $0 }.joined(separator: " ")
    }
}

struct McpServerDetail: Sendable {
    let status: String
    let tools: [McpToolsDTO.Tool]
    let error: String?

    var isOk: Bool { status == "ok" }

    var statusColor: Color {
        switch status {
        case "ok": AppColors.success
        case "timeout": AppColors.warning
        default: AppColors.danger
        }
    }
}
