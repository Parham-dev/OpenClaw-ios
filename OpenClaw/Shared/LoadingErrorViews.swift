import SwiftUI

/// Standard loading placeholder used inside cards.
struct CardLoadingView: View {
    var minHeight: CGFloat = 80

    var body: some View {
        ProgressView()
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
