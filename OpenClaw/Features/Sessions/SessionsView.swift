import SwiftUI

struct SessionsView: View {
    @State var vm: SessionsViewModel
    let repository: SessionRepository
    @State private var selectedTab: SessionTab = .chat

    enum SessionTab: String, CaseIterable {
        case chat = "Chat History"
        case subagents = "Subagents"
    }

    var body: some View {
        NavigationStack {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(SessionTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)

            switch selectedTab {
            case .chat:
                chatSection
            case .subagents:
                subagentsSection
            }
        }
        .navigationTitle("Sessions")
        .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.load() }
    }

    // MARK: - Chat History

    @ViewBuilder
    private var chatSection: some View {
        if vm.isLoading && vm.mainSession == nil {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let main = vm.mainSession {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    MainSessionCard(session: main, repository: repository)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .refreshable {
                await vm.load()
                Haptics.shared.refreshComplete()
            }
        } else if let err = vm.error {
            List { CardErrorView(error: err, minHeight: 60) }
                .listStyle(.insetGrouped)
        } else {
            ContentUnavailableView(
                "No Session",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("No active chat session found.")
            )
        }
    }

    // MARK: - Subagents

    @ViewBuilder
    private var subagentsSection: some View {
        if vm.isLoading && vm.subagents.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !vm.subagents.isEmpty {
            List(vm.subagents) { session in
                NavigationLink {
                    SessionTraceView(
                        sessionKey: session.id,
                        title: session.displayName,
                        subtitle: session.updatedAtFormatted,
                        repository: repository
                    )
                } label: {
                    SubagentRow(session: session)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await vm.load()
                Haptics.shared.refreshComplete()
            }
        } else if let err = vm.error {
            List { CardErrorView(error: err, minHeight: 60) }
                .listStyle(.insetGrouped)
        } else {
            ContentUnavailableView(
                "No Subagents",
                systemImage: "point.3.connected.trianglepath.dotted",
                description: Text("No subagent sessions found.")
            )
        }
    }
}

// MARK: - Main Session Hero Card

private struct MainSessionCard: View {
    let session: SessionEntry
    let repository: SessionRepository

    var body: some View {
        NavigationLink {
            SessionTraceView(
                sessionKey: session.id,
                title: "Main Session",
                subtitle: session.startedAtFormatted,
                newestFirst: true,
                repository: repository
            )
        } label: {
            VStack(spacing: Spacing.lg) {
                // Status + model
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Main Session")
                            .font(AppTypography.heroNumber)
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(session.status == .running ? AppColors.success : AppColors.neutral)
                                .frame(width: 8, height: 8)
                            Text(session.status == .running ? "Running" : "Idle")
                                .font(AppTypography.caption)
                                .foregroundStyle(session.status == .running ? AppColors.success : AppColors.neutral)
                        }
                    }
                    Spacer()
                    if let model = session.model {
                        ModelPill(model: model)
                    }
                }

                // Context ring gauge — center piece
                HStack(spacing: Spacing.xl) {
                    RingGauge(
                        value: session.contextUsage,
                        label: "Context",
                        color: AppColors.gauge(
                            percent: session.contextUsage * 100,
                            warn: 60,
                            critical: 80
                        )
                    )

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        MetricRow(
                            icon: "number.circle",
                            label: "Tokens",
                            value: Formatters.tokens(session.totalTokens),
                            color: AppColors.metricPrimary
                        )
                        MetricRow(
                            icon: "dollarsign.circle",
                            label: "Cost",
                            value: Formatters.cost(session.costUsd),
                            color: AppColors.metricWarm
                        )
                        MetricRow(
                            icon: "point.3.connected.trianglepath.dotted",
                            label: "Subagents",
                            value: "\(session.childSessionCount)",
                            color: AppColors.neutral
                        )
                        MetricRow(
                            icon: "clock",
                            label: "Updated",
                            value: session.updatedAtFormatted,
                            color: AppColors.neutral
                        )
                    }
                }

                // Context detail
                HStack(spacing: Spacing.sm) {
                    Text(Formatters.tokens(session.totalTokens))
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.metricPrimary)
                    Text("/")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                    Text(Formatters.tokens(session.contextTokens))
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                    Text("context window")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                    Spacer()
                    HStack(spacing: Spacing.xxs) {
                        Text("View Trace")
                            .font(AppTypography.caption)
                        Image(systemName: "chevron.right")
                            .font(AppTypography.micro)
                    }
                    .foregroundStyle(AppColors.primaryAction)
                }
            }
            .padding(Spacing.md)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: AppRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .strokeBorder(AppColors.cardBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(AppTypography.micro)
                .foregroundStyle(color)
                .frame(width: 16)
            Text(value)
                .font(AppTypography.captionBold)
                .foregroundStyle(color)
            Text(label)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
        }
    }
}

// MARK: - Subagent Row

private struct SubagentRow: View {
    let session: SessionEntry

    var body: some View {
        HStack(spacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(session.displayName)
                    .font(AppTypography.body)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    if let model = session.model {
                        ModelPill(model: model)
                    }
                    Label(Formatters.tokens(session.totalTokens), systemImage: "number.circle")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.metricPrimary)
                    Spacer()
                    Text(session.updatedAtFormatted)
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
    }
}
