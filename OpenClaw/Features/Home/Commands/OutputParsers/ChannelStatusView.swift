import SwiftUI

/// Parsed channel status probe viewer.
struct ChannelStatusView: View {
    let output: String

    private var result: ChannelProbeResult { ChannelProbeResult.parse(output) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Gateway status
            if let gw = result.gatewayStatus {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: gw.contains("reachable") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(gw.contains("reachable") ? AppColors.success : AppColors.danger)
                    Text("Gateway")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                    Text(gw)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.neutral)
                }
            }

            // Channel probes
            ForEach(result.channels) { channel in
                ChannelProbeRow(channel: channel)
            }

            // Tip
            if let tip = result.tip {
                Text(tip)
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.neutral)
            }
        }
    }
}

private struct ChannelProbeRow: View {
    let channel: ChannelProbe

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header: name + status
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(channel.isWorking ? AppColors.success : AppColors.danger)
                    .frame(width: 8, height: 8)
                Text(channel.name)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                Text(channel.account)
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.neutral)
                Spacer()
                if channel.isWorking {
                    Text("works")
                        .font(AppTypography.nano)
                        .padding(.horizontal, Spacing.xxs)
                        .padding(.vertical, 2)
                        .background(AppColors.success.opacity(0.15), in: Capsule())
                        .foregroundStyle(AppColors.success)
                }
            }

            // Properties as chips
            HStack(spacing: Spacing.xs) {
                ForEach(channel.properties, id: \.key) { prop in
                    HStack(spacing: 2) {
                        Text(prop.key)
                            .font(AppTypography.nano)
                            .foregroundStyle(AppColors.neutral)
                        Text(prop.value)
                            .font(AppTypography.nano)
                            .foregroundStyle(propColor(prop))
                    }
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, 2)
                    .background(AppColors.neutral.opacity(0.06), in: Capsule())
                }
            }
        }
        .padding(Spacing.sm)
        .background(AppColors.tintedBackground(channel.isWorking ? AppColors.success : AppColors.danger, opacity: 0.04), in: RoundedRectangle(cornerRadius: AppRadius.sm))
    }

    private func propColor(_ prop: ChannelProperty) -> Color {
        let v = prop.value.lowercased()
        if v == "enabled" || v == "running" || v == "configured" { return AppColors.success }
        if v == "disabled" || v == "stopped" || v == "error" { return AppColors.danger }
        return .primary
    }
}

// MARK: - Models + Parser

struct ChannelProbe: Identifiable {
    let id: String
    let name: String
    let account: String
    let isWorking: Bool
    let properties: [ChannelProperty]
}

struct ChannelProperty: Sendable {
    let key: String
    let value: String
}

struct ChannelProbeResult {
    let gatewayStatus: String?
    let channels: [ChannelProbe]
    let tip: String?

    static func parse(_ output: String) -> ChannelProbeResult {
        let lines = output.components(separatedBy: "\n")
        var gatewayStatus: String?
        var channels: [ChannelProbe] = []
        var tip: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Skip checking line
            if trimmed.lowercased().hasPrefix("checking") { continue }

            // Gateway status
            if trimmed.lowercased().hasPrefix("gateway") && !trimmed.hasPrefix("- ") {
                gatewayStatus = trimmed.replacingOccurrences(of: "Gateway ", with: "")
                    .replacingOccurrences(of: ".", with: "")
                    .trimmingCharacters(in: .whitespaces)
                continue
            }

            // Tip
            if trimmed.hasPrefix("Tip:") {
                tip = trimmed
                continue
            }

            // Channel line: - Telegram default: enabled, configured, ...
            if trimmed.hasPrefix("- ") {
                let content = String(trimmed.dropFirst(2))
                let parts = content.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }

                let nameAccount = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let propsStr = String(parts[1]).trimmingCharacters(in: .whitespaces)

                // Split name and account: "Telegram default"
                let nameWords = nameAccount.split(separator: " ")
                let name = nameWords.first.map(String.init) ?? nameAccount
                let account = nameWords.dropFirst().joined(separator: " ")

                // Parse comma-separated properties
                let rawProps = propsStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                var properties: [ChannelProperty] = []
                var isWorking = false

                for prop in rawProps {
                    if prop == "works" {
                        isWorking = true
                        continue
                    }
                    // key:value pair or standalone value
                    if prop.contains(":") {
                        let kv = prop.split(separator: ":", maxSplits: 1)
                        properties.append(ChannelProperty(key: String(kv[0]), value: String(kv.count > 1 ? kv[1] : "").trimmingCharacters(in: .whitespaces)))
                    } else {
                        properties.append(ChannelProperty(key: "", value: prop))
                    }
                }

                channels.append(ChannelProbe(id: name, name: name.capitalized, account: account, isWorking: isWorking, properties: properties))
            }
        }

        return ChannelProbeResult(gatewayStatus: gatewayStatus, channels: channels, tip: tip)
    }
}
