import SwiftUI

struct HomeView: View {
    @State private var systemVM: SystemHealthViewModel
    @State private var cronVM: CronSummaryViewModel
    @State private var outreachVM: OutreachStatsViewModel
    @State private var blogVM: BlogPipelineViewModel

    private let keychain: KeychainService

    init(keychain: KeychainService) {
        self.keychain = keychain
        let client = GatewayClient(keychain: keychain)
        _systemVM   = State(initialValue: SystemHealthViewModel(client: client))
        _cronVM     = State(initialValue: CronSummaryViewModel(client: client))
        _outreachVM = State(initialValue: OutreachStatsViewModel(client: client))
        _blogVM     = State(initialValue: BlogPipelineViewModel(client: client))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    SystemHealthCard(vm: systemVM)
                    CronSummaryCard(vm: cronVM)
                    OutreachStatsCard(vm: outreachVM)
                    BlogPipelineCard(vm: blogVM)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .refreshable {
                async let s: Void = systemVM.refresh()
                async let c: Void = cronVM.refresh()
                async let o: Void = outreachVM.refresh()
                async let b: Void = blogVM.refresh()
                _ = await (s, c, o, b)
            }
            .navigationTitle("OpenClaw")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView(keychain: keychain)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .task {
            systemVM.start()
            cronVM.start()
            outreachVM.start()
            blogVM.start()
        }
    }
}
