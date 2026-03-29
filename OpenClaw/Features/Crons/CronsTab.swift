import SwiftUI

struct CronsTab: View {
    let vm: CronSummaryViewModel
    let detailRepository: CronDetailRepository
    let client: GatewayClientProtocol

    @State private var selectedTab: CronTab = .jobs
    @State private var historyVM: CronHistoryViewModel?
    @State private var jobToRun: CronJob?
    @State private var triggerError: Error?

    private var jobs: [CronJob] { vm.data ?? [] }

    private var jobNameMap: [String: String] {
        Dictionary(uniqueKeysWithValues: jobs.map { ($0.id, $0.name) })
    }

    enum CronTab: String, CaseIterable {
        case jobs = "Cron Jobs"
        case history = "History"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    ForEach(CronTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)

                switch selectedTab {
                case .jobs:
                    jobsList
                case .history:
                    historyList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    DetailTitleView(title: "Crons") {
                        cronSubtitle
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        ScheduleTimelineView(jobs: jobs)
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .alert("Run Manually?", isPresented: Binding(
                get: { jobToRun != nil },
                set: { if !$0 { jobToRun = nil } }
            )) {
                Button("Run", role: .destructive) {
                    guard let job = jobToRun else { return }
                    Task { await triggerRun(job) }
                }
                Button("Cancel", role: .cancel) { jobToRun = nil }
            } message: {
                if let job = jobToRun {
                    Text("This will trigger \"\(job.name)\" immediately outside its normal schedule.")
                }
            }
        }
        .alert("Run Failed", isPresented: Binding(
            get: { triggerError != nil },
            set: { if !$0 { triggerError = nil } }
        )) {
            Button("OK") { triggerError = nil }
        } message: {
            if let err = triggerError {
                Text(err.localizedDescription)
            }
        }
        .task { vm.start() }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .history, historyVM == nil {
                let hvm = CronHistoryViewModel(
                    repository: detailRepository,
                    jobsProvider: { [vm] in vm.data ?? [] }
                )
                historyVM = hvm
                Task { await hvm.loadRuns() }
            }
        }
    }

    // MARK: - Subtitle

    @ViewBuilder
    private var cronSubtitle: some View {
        if !jobs.isEmpty {
            let failed = jobs.filter { $0.status == .failed }.count
            HStack(spacing: Spacing.xs) {
                Text("\(jobs.count) jobs")
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.neutral)
                if failed > 0 {
                    Text("\u{00B7} \(failed) failed")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.danger)
                }
            }
        }
    }

    // MARK: - Jobs List

    @ViewBuilder
    private var jobsList: some View {
        if !jobs.isEmpty {
            List {
                Section("Cron Jobs") {
                ForEach(jobs) { job in
                CronJobRow(job: job, onRun: { jobToRun = job })
                    .background(
                        NavigationLink("", destination: CronDetailView(
                            vm: CronDetailViewModel(
                                job: job,
                                repository: detailRepository,
                                client: client,
                                store: InvestigationStore(),
                                onJobUpdated: { await vm.refresh() }
                            ),
                            repository: detailRepository
                        ))
                        .opacity(0)
                    )
                }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await vm.refresh()
                Haptics.shared.refreshComplete()
            }
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

    // MARK: - History List

    @ViewBuilder
    private var historyList: some View {
        if let hvm = historyVM {
            if hvm.isLoading && hvm.runs.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hvm.runs.isEmpty && !hvm.isLoading {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock",
                    description: Text("No runs have been recorded yet.")
                )
            } else if let err = hvm.error, hvm.runs.isEmpty {
                ContentUnavailableView(
                    "Unavailable",
                    systemImage: "wifi.exclamationmark",
                    description: Text(err.localizedDescription)
                )
            } else {
                List {
                    Section("Run History") {
                    ForEach(hvm.runs) { run in
                        CronHistoryRow(run: run, jobName: jobNameMap[run.jobId])
                            .background(
                                Group {
                                    if run.sessionKey != nil || run.sessionId != nil {
                                        NavigationLink("", destination: SessionTraceView(run: run, repository: detailRepository, jobName: jobNameMap[run.jobId], client: client))
                                            .opacity(0)
                                    }
                                }
                            )
                    }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await hvm.loadRuns()
                    Haptics.shared.refreshComplete()
                }
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Actions

    private func triggerRun(_ job: CronJob) async {
        do {
            try await detailRepository.triggerRun(jobId: job.id)
            Haptics.shared.success()
            await vm.refresh()
        } catch {
            triggerError = error
            Haptics.shared.error()
        }
    }
}

// MARK: - Row

struct CronJobRow: View {
    let job: CronJob
    var onRun: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs + 1) {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(job.enabled ? AppColors.success : AppColors.neutral)
                        .frame(width: 8, height: 8)

                    Text(job.name)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer(minLength: Spacing.xxs)

                    CronStatusBadge(status: job.status, style: .small)
                }

                Text(job.scheduleDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.neutral)

                HStack(spacing: Spacing.sm) {
                    Label(job.lastRunFormatted, systemImage: "arrow.counterclockwise")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)

                    Label(job.nextRunFormatted, systemImage: "arrow.clockwise")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                }

                if job.consecutiveErrors > 0 {
                    Label(
                        "\(job.consecutiveErrors) consecutive error\(job.consecutiveErrors == 1 ? "" : "s")",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.danger)
                }
            }

            if let onRun {
                Button {
                    onRun()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(AppTypography.actionIcon)
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
