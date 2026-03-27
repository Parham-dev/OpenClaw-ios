import MarkdownUI
import SwiftUI

struct CronDetailView: View {
    @State var vm: CronDetailViewModel
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
                        StatusDot(status: vm.job.status)
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
                        RunRow(run: run, isExpanded: expandedRunId == run.id) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedRunId = expandedRunId == run.id ? nil : run.id
                            }
                        }
                    }

                    // Load more
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
                StatusBadgeLarge(status: vm.job.status)
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

// MARK: - Run Row

private struct RunRow: View {
    let run: CronRun
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: onTap) {
                HStack(spacing: Spacing.xs) {
                    StatusDot(status: run.status)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(run.runAtFormatted)
                            .font(AppTypography.body)
                        Text(run.runAtAbsolute)
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.neutral)
                    }

                    Spacer()

                    Text(run.durationFormatted)
                        .font(AppTypography.captionMono)
                        .foregroundStyle(AppColors.neutral)

                    if let model = run.model {
                        Text(modelShortName(model))
                            .font(AppTypography.micro)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(AppColors.pillBackground, in: Capsule())
                            .foregroundStyle(AppColors.pillForeground)
                    }

                    Image(systemName: "chevron.down")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                RunExpandedContent(run: run)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func modelShortName(_ model: String) -> String {
        let cleaned = model
            .replacingOccurrences(of: "github-copilot/", with: "")
            .replacingOccurrences(of: "anthropic/", with: "")
            .replacingOccurrences(of: "claude-", with: "")
        let parts = cleaned.split(separator: "-")
        guard parts.count >= 2 else { return cleaned }
        let name = parts[0].prefix(1).uppercased() + parts[0].dropFirst()
        let version = parts[1...].joined(separator: ".")
        return "\(name) \(version)"
    }
}

// MARK: - Expanded Content (separate view to avoid re-parsing markdown on every render)

private struct RunExpandedContent: View {
    let run: CronRun

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                TokenStat(label: "In", value: run.inputTokens)
                TokenStat(label: "Out", value: run.outputTokens)
                TokenStat(label: "Total", value: run.totalTokens)
            }

            if let summary = run.summary, !summary.isEmpty {
                Divider()
                Markdown(summary)
                    .markdownTheme(.openClaw)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, Spacing.xxs)
    }
}

// MARK: - Supporting Views

private struct StatusDot: View {
    let status: CronJob.RunStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .accessibilityLabel(accessibilityText)
    }

    private var color: Color {
        switch status {
        case .succeeded: AppColors.success
        case .failed:    AppColors.danger
        case .unknown:   AppColors.warning
        case .never:     AppColors.neutral
        }
    }

    private var accessibilityText: String {
        switch status {
        case .succeeded: "Succeeded"
        case .failed:    "Failed"
        case .unknown:   "Unknown"
        case .never:     "Never run"
        }
    }
}

private struct StatusBadgeLarge: View {
    let status: CronJob.RunStatus

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(AppTypography.body)
            Text(label)
                .font(AppTypography.body)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
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
        case .succeeded: "Last Run OK"
        case .failed:    "Last Run Failed"
        case .unknown:   "Status Unknown"
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

private struct TokenStat: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(formatTokens(value))
                .font(AppTypography.captionMono)
                .fontWeight(.medium)
            Text(label)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
        }
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000)
        }
        return "\(count)"
    }
}
