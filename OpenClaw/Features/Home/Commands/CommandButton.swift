import SwiftUI

/// Reusable square command button with icon and label.
struct CommandButton: View {
    let command: QuickCommand
    let isRunning: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                Group {
                    if isRunning {
                        ProgressView()
                            .tint(command.iconColor)
                    } else {
                        Image(systemName: command.icon)
                            .font(AppTypography.statusIcon)
                            .foregroundStyle(command.iconColor)
                    }
                }
                .frame(height: 28)

                Text(command.name)
                    .font(AppTypography.micro)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.tintedBackground(command.iconColor, opacity: 0.06), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
        .accessibilityLabel(command.name)
    }
}
