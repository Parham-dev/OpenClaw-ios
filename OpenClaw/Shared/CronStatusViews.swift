import SwiftUI

/// Small colored dot indicating cron run status.
struct CronStatusDot: View {
    let status: CronJob.RunStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .accessibilityLabel(label)
    }

    private var color: Color {
        switch status {
        case .succeeded: AppColors.success
        case .failed:    AppColors.danger
        case .unknown:   AppColors.warning
        case .never:     AppColors.neutral
        }
    }

    private var label: String {
        switch status {
        case .succeeded: "Succeeded"
        case .failed:    "Failed"
        case .unknown:   "Unknown"
        case .never:     "Never run"
        }
    }
}

/// Large pill-shaped status badge for cron detail headers.
struct CronStatusBadge: View {
    let status: CronJob.RunStatus
    var style: Style = .large

    enum Style { case small, large }

    var body: some View {
        HStack(spacing: Spacing.xxs + 2) {
            Image(systemName: icon)
                .font(style == .large ? AppTypography.body : AppTypography.badgeIcon)
            Text(label)
                .font(style == .large ? AppTypography.body : AppTypography.micro)
                .fontWeight(style == .large ? .semibold : .regular)
        }
        .foregroundStyle(color)
        .padding(.horizontal, style == .large ? Spacing.sm : Spacing.xs)
        .padding(.vertical, style == .large ? Spacing.xs : 3)
        .background(AppColors.tintedBackground(color), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    private var icon: String {
        switch status {
        case .succeeded: "checkmark.circle.fill"
        case .failed:    "xmark.circle.fill"
        case .unknown:   "questionmark.circle.fill"
        case .never:     "minus.circle"
        }
    }

    private var label: String {
        switch status {
        case .succeeded: style == .large ? "Last Run OK" : "OK"
        case .failed:    style == .large ? "Last Run Failed" : "Failed"
        case .unknown:   style == .large ? "Status Unknown" : "Unknown"
        case .never:     "Never Run"
        }
    }

    private var color: Color {
        switch status {
        case .succeeded: AppColors.success
        case .failed:    AppColors.danger
        case .unknown:   AppColors.warning
        case .never:     AppColors.neutral
        }
    }
}
