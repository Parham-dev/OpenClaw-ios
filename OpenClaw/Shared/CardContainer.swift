import SwiftUI

/// Reusable card shell used by every dashboard card.
struct CardContainer<Content: View>: View {
    let title: String
    let systemImage: String
    let isStale: Bool
    let isLoading: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: systemImage)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.neutral)
                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.neutral)
                Spacer()
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(AppColors.neutral)
                            .transition(.opacity)
                    } else if isStale {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.warning)
                            .transition(.opacity)
                    }
                }
                .frame(width: 20, height: 20)
            }

            content()
                .transition(.opacity)
        }
        .padding(Spacing.md)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(AppColors.cardBorder, lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: isStale)
    }
}
