import SwiftUI

/// Proportional bar showing input/output/reasoning token breakdown.
struct TokenBreakdownBar: View {
    let input: Int
    let output: Int
    let total: Int

    private var reasoning: Int { max(total - input - output, 0) }
    private var hasReasoning: Bool { reasoning > 0 }

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            GeometryReader { geo in
                let width = geo.size.width
                HStack(spacing: 1) {
                    barSegment(value: input, total: total, width: width, color: AppColors.metricPrimary)
                    barSegment(value: output, total: total, width: width, color: AppColors.metricPositive)
                    if hasReasoning {
                        barSegment(value: reasoning, total: total, width: width, color: AppColors.metricTertiary)
                    }
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tokens: \(Formatters.tokens(input)) in, \(Formatters.tokens(output)) out")

            HStack(spacing: Spacing.sm) {
                TokenLegendItem(color: AppColors.metricPrimary, label: "In", value: input)
                TokenLegendItem(color: AppColors.metricPositive, label: "Out", value: output)
                if hasReasoning {
                    TokenLegendItem(color: AppColors.metricTertiary, label: "Other", value: reasoning)
                }
                Spacer()
            }
        }
    }

    private func barSegment(value: Int, total: Int, width: CGFloat, color: Color) -> some View {
        let proportion = total > 0 ? CGFloat(value) / CGFloat(total) : 0
        return Rectangle()
            .fill(color)
            .frame(width: max(proportion * width, value > 0 ? 2 : 0))
    }
}

/// Reusable legend dot + label for token bars.
struct TokenLegendItem: View {
    let color: Color
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(Formatters.tokens(value))")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
        }
    }
}
