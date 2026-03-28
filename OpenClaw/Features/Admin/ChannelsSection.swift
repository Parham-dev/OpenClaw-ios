import SwiftUI

struct ChannelsSection: View {
    let status: ChannelsStatus

    var body: some View {
        // Connected channels
        Section("Channels") {
            ForEach(status.channels) { channel in
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(channel.isConnected ? AppColors.success : AppColors.neutral.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(channel.name)
                        .font(AppTypography.body)
                    Spacer()
                    if channel.isConnected {
                        Text("\(channel.accountCount) account\(channel.accountCount == 1 ? "" : "s")")
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.neutral)
                    } else {
                        Text("Disconnected")
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.neutral)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }

        // Provider usage
        if !status.providers.isEmpty {
            Section("Provider Usage") {
                ForEach(status.providers) { provider in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(provider.displayName)
                                .font(AppTypography.body)
                                .fontWeight(.medium)
                            if let plan = provider.plan {
                                Text(plan)
                                    .font(AppTypography.nano)
                                    .padding(.horizontal, Spacing.xxs)
                                    .padding(.vertical, 2)
                                    .background(AppColors.pillBackground, in: Capsule())
                                    .foregroundStyle(AppColors.pillForeground)
                            }
                            Spacer()
                        }

                        ForEach(provider.windows) { window in
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                HStack {
                                    Text(window.label)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.neutral)
                                    Spacer()
                                    Text(String(format: "%.1f%%", window.usedPercent))
                                        .font(AppTypography.captionBold)
                                        .foregroundStyle(usageColor(window.usedPercent))
                                }
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppColors.neutral.opacity(0.15))
                                        .overlay(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(usageColor(window.usedPercent))
                                                .frame(width: geo.size.width * min(window.usedPercent / 100, 1))
                                        }
                                }
                                .frame(height: 6)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(window.label): \(String(format: "%.1f", window.usedPercent)) percent used")
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
        }
    }

    private func usageColor(_ percent: Double) -> Color {
        AppColors.gauge(percent: percent, warn: 70, critical: 90)
    }
}
