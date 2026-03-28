import SwiftUI

/// Definition of a quick command button.
struct QuickCommand: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let iconColor: Color
    let confirmMessage: String
    /// "stats-exec" for /stats/exec, "gateway" for /tools/invoke gateway tool, "pause-all-crons" for batch disable
    let toolName: String
    /// For stats-exec: ["command": "<allowlist-key>"], for gateway: ["action": "restart"]
    let args: [String: String]

    static let all: [QuickCommand] = [
        // Row 1 — visible by default
        QuickCommand(
            id: "restart-gateway",
            name: "Restart",
            icon: "arrow.clockwise.circle.fill",
            iconColor: AppColors.warning,
            confirmMessage: "Restart the OpenClaw gateway? Active sessions will reconnect automatically.",
            toolName: "gateway",
            args: ["action": "restart"]
        ),
        QuickCommand(
            id: "doctor",
            name: "Doctor",
            icon: "stethoscope.circle.fill",
            iconColor: AppColors.metricPositive,
            confirmMessage: "Run health checks on the gateway and all services?",
            toolName: "stats-exec",
            args: ["command": "doctor"]
        ),
        QuickCommand(
            id: "tail-logs",
            name: "Tail Logs",
            icon: "doc.text.magnifyingglass",
            iconColor: AppColors.info,
            confirmMessage: "Fetch the latest 50 gateway log lines?",
            toolName: "stats-exec",
            args: ["command": "logs"]
        ),
        // Row 2 — visible by default
        QuickCommand(
            id: "pause-all-crons",
            name: "Pause Crons",
            icon: "pause.circle.fill",
            iconColor: AppColors.danger,
            confirmMessage: "Disable ALL cron jobs? No scheduled tasks will run until re-enabled.",
            toolName: "pause-all-crons",
            args: [:]
        ),
        QuickCommand(
            id: "security-audit",
            name: "Security",
            icon: "lock.shield.fill",
            iconColor: AppColors.metricTertiary,
            confirmMessage: "Run a full security audit on the gateway?",
            toolName: "stats-exec",
            args: ["command": "security-audit"]
        ),
        QuickCommand(
            id: "backup",
            name: "Backup",
            icon: "externaldrive.fill.badge.checkmark",
            iconColor: AppColors.metricPrimary,
            confirmMessage: "Create a full gateway backup? This may take a moment.",
            toolName: "stats-exec",
            args: ["command": "backup"]
        ),
        // Row 3+ — behind "Show More"
        QuickCommand(
            id: "gateway-status",
            name: "Status",
            icon: "heart.circle.fill",
            iconColor: AppColors.success,
            confirmMessage: "Check gateway and channel status?",
            toolName: "stats-exec",
            args: ["command": "status"]
        ),
        QuickCommand(
            id: "channel-status",
            name: "Channels",
            icon: "bubble.left.and.bubble.right.fill",
            iconColor: AppColors.metricHighlight,
            confirmMessage: "Check status of all messaging channels?",
            toolName: "stats-exec",
            args: ["command": "channels-status"]
        ),
        QuickCommand(
            id: "memory-index",
            name: "Reindex",
            icon: "brain.fill",
            iconColor: AppColors.metricWarm,
            confirmMessage: "Force reindex the semantic memory store?",
            toolName: "stats-exec",
            args: ["command": "memory-reindex"]
        ),
        QuickCommand(
            id: "session-cleanup",
            name: "Cleanup",
            icon: "trash.circle.fill",
            iconColor: AppColors.neutral,
            confirmMessage: "Run session maintenance? Old sessions will be pruned.",
            toolName: "stats-exec",
            args: ["command": "session-cleanup"]
        ),
        QuickCommand(
            id: "plugin-update",
            name: "Update Plugins",
            icon: "arrow.down.circle.fill",
            iconColor: AppColors.metricSecondary,
            confirmMessage: "Update all installed plugins to latest versions?",
            toolName: "stats-exec",
            args: ["command": "plugin-update"]
        ),
        QuickCommand(
            id: "config-validate",
            name: "Validate",
            icon: "checkmark.seal.fill",
            iconColor: AppColors.success,
            confirmMessage: "Validate the gateway configuration file?",
            toolName: "stats-exec",
            args: ["command": "config-validate"]
        ),
    ]

    static let visibleCount = 6
    static let gridColumns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 3)
}
