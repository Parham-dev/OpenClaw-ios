import SwiftUI

struct HomeView: View {
    @State private var systemVM: SystemHealthViewModel
    @State private var outreachVM: OutreachStatsViewModel
    @State private var blogVM: BlogPipelineViewModel

    private let cronVM: CronSummaryViewModel

    private let keychain: KeychainService

    init(keychain: KeychainService, client: GatewayClient, cronVM: CronSummaryViewModel) {
        self.keychain = keychain
        self.cronVM = cronVM
        _systemVM   = State(initialValue: SystemHealthViewModel(repository: RemoteSystemHealthRepository(client: client)))
        _outreachVM = State(initialValue: OutreachStatsViewModel(repository: RemoteOutreachRepository(client: client)))
        _blogVM     = State(initialValue: BlogPipelineViewModel(repository: RemoteBlogRepository(client: client)))
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
                Haptics.shared.refreshComplete()
            }
            .navigationTitle("Home")
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
