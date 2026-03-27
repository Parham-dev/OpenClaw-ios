import SwiftUI

struct CronsTab: View {
    let vm: CronSummaryViewModel

    private var jobs: [CronJob] { vm.data ?? [] }

    var body: some View {
        NavigationStack {
            Group {
                if !jobs.isEmpty {
                    List(jobs) { job in
                        CronJobRow(job: job)
                            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md))
                    }
                    .listStyle(.insetGrouped)
                } else if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.error {
                    ContentUnavailableView(
                        "Unavailable",
                        systemImage: "wifi.exclamationmark",
                        description: Text(err.localizedDescription)
                    )
                } else {
                    ContentUnavailableView(
                        "No Cron Jobs",
                        systemImage: "clock.arrow.2.circlepath",
                        description: Text("No cron jobs are configured on the gateway.")
                    )
                }
            }
            .refreshable {
                await vm.refresh()
                Haptics.shared.refreshComplete()
            }
            .navigationTitle("Cron Jobs")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { vm.start() }
    }
}

// MARK: - Row (shared between CronsTab and CronSummaryCard)

struct CronJobRow: View {
    let job: CronJob

    var body: some View {
        HStack(spacing: Spacing.xs + 2) {
            Circle()
                .fill(job.enabled ? AppColors.success : AppColors.neutral)
                .frame(width: 8, height: 8)
                .accessibilityLabel(job.enabled ? "Enabled" : "Disabled")

            VStack(alignment: .leading, spacing: 2) {
                Text(job.name)
                    .font(AppTypography.body)
                    .lineLimit(1)
                Text(job.scheduleExpr)
                    .font(AppTypography.microMono)
                    .foregroundStyle(AppColors.neutral)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: statusIcon)
                    .font(AppTypography.caption)
                    .foregroundStyle(statusColor)
                    .accessibilityLabel(statusAccessibilityLabel)
                Text(job.nextRunFormatted)
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.neutral)
            }
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }

    private var statusIcon: String {
        switch job.status {
        case .succeeded: "checkmark.circle.fill"
        case .failed:    "xmark.circle.fill"
        case .unknown:   "questionmark.circle.fill"
        case .never:     "minus.circle"
        }
    }

    private var statusColor: Color {
        switch job.status {
        case .succeeded: AppColors.success
        case .failed:    AppColors.danger
        case .unknown:   AppColors.warning
        case .never:     AppColors.neutral
        }
    }

    private var statusAccessibilityLabel: String {
        switch job.status {
        case .succeeded: "Last run succeeded"
        case .failed:    "Last run failed"
        case .unknown:   "Last run status unknown"
        case .never:     "Never run"
        }
    }
}
