import SwiftUI

/// Circular ring gauge with a percentage value and a label below.
struct RingGauge: View {
    /// 0.0 – 1.0
    let value: Double
    let label: String
    let color: Color

    private let lineWidth: CGFloat = 9
    private let size: CGFloat = 72

    var body: some View {
        VStack(spacing: Spacing.xxs + 1) {
            ZStack {
                Circle()
                    .stroke(AppColors.neutral.opacity(0.15), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: min(value, 1))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: value)

                Text(String(format: "%.0f%%", value * 100))
                    .font(AppTypography.gaugePercent)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
            }
            .frame(width: size, height: size)

            Text(label)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(String(format: "%.0f", value * 100)) percent")
        .accessibilityValue(String(format: "%.0f%%", value * 100))
    }
}
