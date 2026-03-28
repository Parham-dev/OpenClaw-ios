import SwiftUI

struct HomeView: View {
    @State private var systemVM: SystemHealthViewModel
    @State private var outreachVM: OutreachStatsViewModel
    @State private var blogVM: BlogPipelineViewModel
    @State private var commandsVM: CommandsViewModel
    @State private var tokenUsageVM: TokenUsageViewModel

    private let cronVM: CronSummaryViewModel
    private let keychain: KeychainService
    private let client: GatewayClientProtocol
    private let cronDetailRepository: CronDetailRepository

    init(keychain: KeychainService, client: GatewayClientProtocol, cronVM: CronSummaryViewModel, cronDetailRepository: CronDetailRepository) {
        self.keychain = keychain
        self.client = client
        self.cronVM = cronVM
        self.cronDetailRepository = cronDetailRepository
        _systemVM     = State(initialValue: SystemHealthViewModel(repository: RemoteSystemHealthRepository(client: client)))
        _outreachVM   = State(initialValue: OutreachStatsViewModel(repository: RemoteOutreachRepository(client: client)))
        _blogVM       = State(initialValue: BlogPipelineViewModel(repository: RemoteBlogRepository(client: client)))
        _commandsVM   = State(initialValue: CommandsViewModel(client: client, cronRepository: RemoteCronRepository(client: client)))
        _tokenUsageVM = State(initialValue: TokenUsageViewModel(client: client))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    SystemHealthCard(vm: systemVM)
                    CommandsCard(vm: commandsVM, client: client)
                    CronSummaryCard(vm: cronVM)

                    TokenUsageCard(vm: tokenUsageVM, detailRepository: cronDetailRepository)

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
                async let t: Void = tokenUsageVM.refresh()
                _ = await (s, c, o, b, t)
                Haptics.shared.refreshComplete()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        ChatTab(client: client)
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView(keychain: keychain)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            systemVM.startPolling()
        }
        .onDisappear {
            systemVM.stopPolling()
        }
        .task {
            cronVM.start()
            outreachVM.start()
            blogVM.start()
            tokenUsageVM.start()
        }
    }
}
