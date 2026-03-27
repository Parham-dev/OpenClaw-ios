import SwiftUI

struct MemoryTab: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Memory", systemImage: "brain")
                    .font(AppTypography.screenTitle)
            } description: {
                Text("Browse and edit workspace files — MEMORY.md, daily notes, skills. Coming soon.")
                    .font(AppTypography.body)
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
