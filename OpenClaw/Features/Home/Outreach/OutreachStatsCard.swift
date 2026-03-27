import SwiftUI

struct OutreachStatsCard: View {
    let vm: OutreachStatsViewModel

    var body: some View {
        CardContainer(
            title: "Outreach",
            systemImage: "chart.bar.fill",
            isStale: vm.isStale,
            isLoading: vm.isLoading && vm.data == nil
        ) {
            if let s = vm.data {
                Grid(horizontalSpacing: Spacing.xs + 2, verticalSpacing: Spacing.xs + 2) {
                    GridRow {
                        StatCell(label: "Total",    value: s.totalLeads, color: AppColors.metricPrimary)
                        StatCell(label: "Emailed",  value: s.emailSent,  color: AppColors.metricSecondary)
                        StatCell(label: "WhatsApp", value: s.waSent,     color: AppColors.metricPositive)
                    }
                    GridRow {
                        StatCell(label: "Replied",   value: s.replied,   color: AppColors.metricWarm)
                        StatCell(label: "Converted", value: s.converted, color: AppColors.metricTertiary)
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f%%", s.replyRatePct))
                                .font(AppTypography.metricValue)
                                .foregroundStyle(AppColors.metricHighlight)
                            Text("Reply Rate")
                                .font(AppTypography.metricLabel)
                                .foregroundStyle(AppColors.neutral)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background(AppColors.tintedBackground(AppColors.metricHighlight), in: RoundedRectangle(cornerRadius: AppRadius.sm))
                        .accessibilityElement(children: .combine)
                    }
                }
            } else if vm.isLoading {
                CardLoadingView()
            } else if let err = vm.error {
                CardErrorView(error: err)
            }
        }
    }
}

private struct StatCell: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AppTypography.metricValue)
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(AppTypography.metricLabel)
                .foregroundStyle(AppColors.neutral)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(AppColors.tintedBackground(color), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
