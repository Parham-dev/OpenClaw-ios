import SwiftUI

/// Skeleton loading placeholder with shimmer — replaces plain ProgressView.
struct CardLoadingView: View {
    var minHeight: CGFloat = 80

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                SkeletonRect(width: 72, height: 72, radius: 36)
                SkeletonRect(width: 72, height: 72, radius: 36)
                SkeletonRect(width: 72, height: 72, radius: 36)
            }
            HStack {
                SkeletonRect(width: 80, height: 12)
                Spacer()
                SkeletonRect(width: 50, height: 12)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }
}

/// Standard error state used inside cards.
struct CardErrorView: View {
    let error: Error
    var minHeight: CGFloat = 80

    var body: some View {
        ContentUnavailableView(
            "Unavailable",
            systemImage: "wifi.exclamationmark",
            description: Text(error.localizedDescription)
        )
        .frame(minHeight: minHeight)
    }
}

/// A rounded rectangle placeholder block for skeleton loading.
/// Shimmer is applied per-shape so it only animates over the filled area.
private struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var radius: CGFloat = AppRadius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(AppColors.neutral.opacity(0.12))
            .frame(width: width, height: height)
            .shimmer()
    }
}
