import SwiftUI

struct ChatTab: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    .font(AppTypography.screenTitle)
            } description: {
                Text("Streaming conversations with your AI agent. Coming soon.")
                    .font(AppTypography.body)
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
