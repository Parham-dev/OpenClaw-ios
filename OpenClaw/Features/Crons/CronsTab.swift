import SwiftUI

struct CronsTab: View {
    let vm: CronSummaryViewModel
    let detailRepository: CronDetailRepository

    private var jobs: [CronJob] { vm.data ?? [] }

    var body: some View {
        NavigationStack {
            Group {
                if !jobs.isEmpty {
                    List(jobs) { job in
                        CronJobRow(job: job, onRun: { runJob(job) })
                            .background(
                                NavigationLink("", destination: CronDetailView(
                                    vm: CronDetailViewModel(
                                        job: job,
                                        repository: detailRepository,
                                        onJobUpdated: { await vm.refresh() }
                                    )
                                ))
                                .opacity(0)
                            )
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

    private func runJob(_ job: CronJob) {
        Haptics.shared.success()
    }
}

// MARK: - Row

struct CronJobRow: View {
    let job: CronJob
    var onRun: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            // Left: all job info stacked
            VStack(alignment: .leading, spacing: Spacing.xxs + 1) {
                // Name + status
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(job.enabled ? AppColors.success : AppColors.neutral)
                        .frame(width: 8, height: 8)

                    Text(job.name)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer(minLength: Spacing.xxs)

                    StatusBadge(status: job.status)
                }

                // Schedule
                Text(job.scheduleDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.neutral)

                // Last + Next run
                HStack(spacing: Spacing.sm) {
                    Label(job.lastRunFormatted, systemImage: "arrow.counterclockwise")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)

                    Label(job.nextRunFormatted, systemImage: "arrow.clockwise")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                }

                // Error count
                if job.consecutiveErrors > 0 {
                    Label(
                        "\(job.consecutiveErrors) consecutive error\(job.consecutiveErrors == 1 ? "" : "s")",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.danger)
                }
            }

            // Right: run button, vertically centered
            if let onRun {
                Button {
                    onRun()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.primaryAction)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Run \(job.name) manually")
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: CronJob.RunStatus

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(AppTypography.micro)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background(AppColors.tintedBackground(color), in: Capsule())
    }

    private var icon: String {
        switch status {
        case .succeeded: "checkmark"
        case .failed:    "xmark"
        case .unknown:   "questionmark"
        case .never:     "minus"
        }
    }

    private var label: String {
        switch status {
        case .succeeded: "OK"
        case .failed:    "Failed"
        case .unknown:   "Unknown"
        case .never:     "Never run"
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

