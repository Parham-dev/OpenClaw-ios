import SwiftUI

struct CronSummaryCard: View {
    let vm: CronSummaryViewModel

    private var jobs: [CronJob] { vm.data ?? [] }

    var body: some View {
        CardContainer(
            title: "Cron Jobs",
            systemImage: "clock.arrow.2.circlepath",
            isStale: vm.isStale,
            isLoading: vm.isLoading && jobs.isEmpty
        ) {
            if !jobs.isEmpty {
                VStack(spacing: 0) {
                    let preview = Array(jobs.prefix(5))
                    ForEach(Array(preview.enumerated()), id: \.element.id) { index, job in
                        CronJobRow(job: job)
                        if index < preview.count - 1 {
                            Divider()
                        }
                    }

                    if jobs.count > 5 {
                        NavigationLink {
                            CronJobsListView(jobs: jobs)
                        } label: {
                            HStack {
                                Text("See All (\(jobs.count))")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.primaryAction)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.neutral)
                            }
                            .padding(.top, Spacing.xs + 2)
                        }
                    }
                }
            } else if vm.isLoading {
                CardLoadingView()
            } else if let err = vm.error {
                CardErrorView(error: err)
            } else {
                Text("No cron jobs configured.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.neutral)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
    }
}

// MARK: - Row

private struct CronJobRow: View {
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
                Text(job.schedule.expr)
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
        switch job.lastRunStatus {
        case .succeeded: "checkmark.circle.fill"
        case .failed:    "xmark.circle.fill"
        case .unknown:   "questionmark.circle.fill"
        case .never:     "minus.circle"
        }
    }

    private var statusColor: Color {
        switch job.lastRunStatus {
        case .succeeded: AppColors.success
        case .failed:    AppColors.danger
        case .unknown:   AppColors.warning
        case .never:     AppColors.neutral
        }
    }

    private var statusAccessibilityLabel: String {
        switch job.lastRunStatus {
        case .succeeded: "Last run succeeded"
        case .failed:    "Last run failed"
        case .unknown:   "Last run status unknown"
        case .never:     "Never run"
        }
    }
}

// MARK: - Full List

struct CronJobsListView: View {
    let jobs: [CronJob]

    var body: some View {
        List(jobs) { job in
            CronJobRow(job: job)
                .listRowInsets(EdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md))
        }
        .navigationTitle("Cron Jobs")
        .navigationBarTitleDisplayMode(.large)
    }
}
