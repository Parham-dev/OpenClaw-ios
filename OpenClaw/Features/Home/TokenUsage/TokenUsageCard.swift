import SwiftUI

struct TokenUsageCard: View {
    @State var vm: TokenUsageViewModel

    var body: some View {
        CardContainer(
            title: "Token Usage",
            systemImage: "number.circle",
            isStale: vm.isStale,
            isLoading: vm.isLoading && vm.data == nil
        ) {
            if let usage = vm.data {
                VStack(spacing: Spacing.sm) {
                    // Period picker
                    Picker("Period", selection: $vm.selectedPeriod) {
                        ForEach(TokenPeriod.allCases) { period in
                            Text(period.label).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vm.selectedPeriod) {
                        Task { await vm.refresh() }
                    }

                    // Hero row: total + cost
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatTokens(usage.totals.totalTokens))
                                .font(AppTypography.heroNumber)
                                .contentTransition(.numericText())
                            Text("total tokens")
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.neutral)
                        }
                        Spacer()
                        if usage.totals.costUsd > 0 {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "$%.2f", usage.totals.costUsd))
                                    .font(AppTypography.metricValue)
                                    .foregroundStyle(AppColors.metricWarm)
                                    .contentTransition(.numericText())
                                Text("cost")
                                    .font(AppTypography.micro)
                                    .foregroundStyle(AppColors.neutral)
                            }
                        }
                    }

                    // Token breakdown bar (input/output/cache)
                    TokenUsageBar(totals: usage.totals)

                    // Stats grid
                    TokenStatsGrid(totals: usage.totals)

                    // Model breakdown — behind show more
                    if !usage.byModel.isEmpty {
                        ModelBreakdownSection(models: usage.byModel)
                    }
                }
            } else if vm.isLoading {
                CardLoadingView(minHeight: 120)
            } else if let err = vm.error {
                CardErrorView(error: err, minHeight: 80)
            }
        }
    }
}

// MARK: - Token Usage Bar (different from TokenBreakdownBar — includes cache)

private struct TokenUsageBar: View {
    let totals: TokenUsage.Totals

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            GeometryReader { geo in
                let w = geo.size.width
                let total = max(totals.totalTokens, 1)
                HStack(spacing: 1) {
                    segment(totals.inputTokens, total, w, AppColors.metricPrimary)
                    segment(totals.outputTokens, total, w, AppColors.metricPositive)
                    segment(totals.cacheReadTokens, total, w, AppColors.metricHighlight)
                    segment(totals.cacheWriteTokens, total, w, AppColors.metricTertiary)
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())

            HStack(spacing: Spacing.sm) {
                LegendDot(color: AppColors.metricPrimary, label: "In", value: totals.inputTokens)
                LegendDot(color: AppColors.metricPositive, label: "Out", value: totals.outputTokens)
                LegendDot(color: AppColors.metricHighlight, label: "Cache Read", value: totals.cacheReadTokens)
                LegendDot(color: AppColors.metricTertiary, label: "Cache Write", value: totals.cacheWriteTokens)
                Spacer()
            }
        }
    }

    private func segment(_ value: Int, _ total: Int, _ width: CGFloat, _ color: Color) -> some View {
        let p = CGFloat(value) / CGFloat(total)
        return Rectangle().fill(color).frame(width: max(p * width, value > 0 ? 2 : 0))
    }
}

// MARK: - Stats Grid

private struct TokenStatsGrid: View {
    let totals: TokenUsage.Totals

    var body: some View {
        HStack(spacing: Spacing.sm) {
            StatPill(icon: "arrow.up.arrow.down", label: "Requests", value: "\(totals.requestCount)")
            StatPill(icon: "brain.head.profile", label: "Thinking", value: "\(totals.thinkingRequests)")
            StatPill(icon: "terminal", label: "Tool Use", value: "\(totals.toolRequests)")
            Spacer()
        }
    }
}

private struct StatPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(AppTypography.badgeIcon)
                .foregroundStyle(AppColors.neutral)
            Text(value)
                .font(AppTypography.captionBold)
                .contentTransition(.numericText())
            Text(label)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
        }
    }
}

// MARK: - Model Breakdown (collapsible)

private struct ModelBreakdownSection: View {
    let models: [TokenUsage.ModelUsage]
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Button {
                withAnimation(.snappy(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("By Model (\(models.count))")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.primaryAction)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.primaryAction)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(models) { model in
                    HStack(spacing: Spacing.xs) {
                        Text(shortName(model.model))
                            .font(AppTypography.caption)
                            .lineLimit(1)

                        Text(model.provider)
                            .font(AppTypography.micro)
                            .padding(.horizontal, Spacing.xs - 2)
                            .padding(.vertical, 2)
                            .background(AppColors.pillBackground, in: Capsule())
                            .foregroundStyle(AppColors.pillForeground)

                        Spacer()

                        Text(formatTokens(model.totalTokens))
                            .font(AppTypography.captionMono)
                            .foregroundStyle(AppColors.metricPrimary)

                        Text("\(model.requestCount) req")
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.neutral)
                    }
                }
            }
        }
    }

    private func shortName(_ model: String) -> String {
        model.replacingOccurrences(of: "claude-", with: "").capitalized
    }
}

// MARK: - Helpers

private struct LegendDot: View {
    let color: Color
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 2) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(label) \(formatTokens(value))")
                .font(AppTypography.nano)
                .foregroundStyle(AppColors.neutral)
        }
    }
}

private func formatTokens(_ count: Int) -> String {
    if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
    if count >= 1000 { return String(format: "%.1fk", Double(count) / 1000) }
    return "\(count)"
}
