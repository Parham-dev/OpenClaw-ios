import SwiftUI

struct PipelinesPlaceholderTab: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Pipelines", systemImage: "bolt.fill")
                    .font(AppTypography.screenTitle)
            } description: {
                Text("Live pipeline cards — Blog, Outreach, WhatsApp, Site Agent. Coming soon.")
                    .font(AppTypography.body)
            }
            .navigationTitle("Pipelines")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
