import SwiftUI

struct CronDetailView: View {
    @State var vm: CronDetailViewModel
    let repository: CronDetailRepository
    @State private var expandedRunId: String?

    var body: some View {
        List {
            // MARK: - Header
            Section {
                headerCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // MARK: - Schedule
            Section("Schedule") {
                LabeledContent("Frequency", value: vm.job.scheduleDescription)
                LabeledContent("Expression") {
                    Text(vm.job.scheduleExpr)
                        .font(AppTypography.captionMono)
                        .foregroundStyle(AppColors.neutral)
                }
                if let tz = vm.job.timeZone {
                    LabeledContent("Timezone", value: tz)
                }
            }

            // MARK: - Timing
            Section("Timing") {
                LabeledContent("Last Run") {
                    HStack(spacing: Spacing.xxs) {
                        CronStatusDot(status: vm.job.status)
                        Text(vm.job.lastRunFormatted)
                            .font(AppTypography.body)
                    }
                }
                if let error = vm.job.lastError {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.danger)
                }
                LabeledContent("Next Run") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(vm.job.nextRunFormatted)
                            .font(AppTypography.body)
                        if let nextRun = vm.job.nextRun {
                            Text(Formatters.absoluteString(for: nextRun))
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.neutral)
                        }
                    }
                }
                if vm.job.consecutiveErrors > 0 {
                    LabeledContent("Consecutive Errors") {
                        Text("\(vm.job.consecutiveErrors)")
                            .foregroundStyle(AppColors.danger)
                            .fontWeight(.semibold)
                    }
                }
            }

            // MARK: - Run History
            Section {
                if vm.isLoading && vm.runs.isEmpty {
                    CardLoadingView(minHeight: 60)
                } else if vm.runs.isEmpty && !vm.isLoading {
                    ContentUnavailableView(
                        "No Runs Yet",
                        systemImage: "clock",
                        description: Text("This job hasn't recorded any runs.")
                    )
                    .frame(minHeight: 100)
                } else {
                    ForEach(vm.runs) { run in
                        CronRunRow(run: run, isExpanded: expandedRunId == run.id) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedRunId = expandedRunId == run.id ? nil : run.id
                            }
                        }
                        .background(
                            Group {
                                if run.sessionKey != nil || run.sessionId != nil {
                                    NavigationLink("", destination: SessionTraceView(run: run, repository: repository))
                                        .opacity(0)
                                }
                            }
                        )
                    }

                    if vm.hasMore {
                        Button {
                            Task { await vm.loadMore() }
                        } label: {
                            HStack {
                                Spacer()
                                if vm.isLoadingMore {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Text("Load More")
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColors.primaryAction)
                                }
                                Spacer()
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .disabled(vm.isLoadingMore)
                    }
                }
            } header: {
                HStack {
                    Text("Run History")
                    if !vm.runs.isEmpty {
                        Text("(\(vm.runs.count))")
                            .foregroundStyle(AppColors.neutral)
                    }
                    Spacer()
                    if vm.isLoading && !vm.runs.isEmpty {
                        ProgressView().scaleEffect(0.7)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(vm.job.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await vm.loadRuns()
            Haptics.shared.refreshComplete()
        }
        .task {
            await vm.loadRuns()
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                CronStatusBadge(status: vm.job.status)
                Spacer()
                if vm.isTogglingEnabled {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Toggle("", isOn: Binding(
                        get: { vm.job.enabled },
                        set: { _ in Task { await vm.toggleEnabled() } }
                    ))
                    .labelsHidden()
                    .tint(AppColors.success)
                }
            }

            Button {
                Task { await vm.triggerRun() }
            } label: {
                HStack(spacing: Spacing.xs) {
                    if vm.isTriggering {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text("Run Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
            }
            .background(AppColors.primaryAction, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            .foregroundStyle(.white)
            .disabled(vm.isTriggering)
        }
        .padding(Spacing.md)
    }
}
