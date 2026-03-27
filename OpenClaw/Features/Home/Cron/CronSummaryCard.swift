import SwiftUI

/// Compact cron summary for the dashboard — shows last run result and next upcoming run.
struct CronSummaryCard: View {
    let vm: CronSummaryViewModel

    private var jobs: [CronJob] { vm.data ?? [] }

    /// Most recently run job (by lastRun date).
    private var lastRan: CronJob? {
        jobs.filter { $0.lastRun != nil }
            .max { ($0.lastRun ?? .distantPast) < ($1.lastRun ?? .distantPast) }
    }

    /// Next job to fire (by nextRun date).
    private var nextUp: CronJob? {
        jobs.filter { $0.nextRun != nil && $0.enabled }
            .min { ($0.nextRun ?? .distantFuture) < ($1.nextRun ?? .distantFuture) }
    }

    var body: some View {
        CardContainer(
            title: "Cron Jobs",
            systemImage: "clock.arrow.2.circlepath",
            isStale: vm.isStale,
            isLoading: vm.isLoading && jobs.isEmpty
        ) {
            if !jobs.isEmpty {
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        // Last Run
                        CronMiniStat(
                            heading: "LAST RUN",
                            icon: lastRunIcon,
                            iconColor: lastRunColor,
                            title: lastRan?.name ?? "\u{2014}",
                            subtitle: lastRunSubtitle
                        )

                        Divider()
                            .frame(height: 44)

                        // Next Up
                        CronMiniStat(
                            heading: "NEXT UP",
                            icon: "arrow.right.circle.fill",
                            iconColor: AppColors.info,
                            title: nextUp?.name ?? "\u{2014}",
                            subtitle: nextUp?.nextRunFormatted ?? "\u{2014}"
                        )
                    }

                    // Job count footer
                    HStack {
                        Text("\(jobs.count) jobs")
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.neutral)

                        let failedCount = jobs.filter { $0.status == .failed }.count
                        if failedCount > 0 {
                            Text("\u{00B7} \(failedCount) failed")
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.danger)
                        }

                        Spacer()
                    }
                }
            } else if vm.isLoading {
                CardLoadingView(minHeight: 60)
            } else if let err = vm.error {
                CardErrorView(error: err, minHeight: 60)
            } else {
                Text("No cron jobs configured.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.neutral)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }

    private var lastRunIcon: String {
        switch lastRan?.status {
        case .succeeded: "checkmark.circle.fill"
        case .failed:    "xmark.circle.fill"
        case .unknown:   "questionmark.circle.fill"
        default:         "minus.circle"
        }
    }

    private var lastRunColor: Color {
        switch lastRan?.status {
        case .succeeded: AppColors.success
        case .failed:    AppColors.danger
        case .unknown:   AppColors.warning
        default:         AppColors.neutral
        }
    }

    private var lastRunSubtitle: String {
        guard let lastRun = lastRan?.lastRun else { return "\u{2014}" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastRun, relativeTo: Date())
    }
}

// MARK: - Mini stat block

private struct CronMiniStat: View {
    let heading: String
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(heading)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
                .tracking(AppTypography.sectionLabelTracking)

            HStack(spacing: Spacing.xxs + 2) {
                Image(systemName: icon)
                    .font(AppTypography.caption)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(AppTypography.body)
                    .lineLimit(1)
            }

            Text(subtitle)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
