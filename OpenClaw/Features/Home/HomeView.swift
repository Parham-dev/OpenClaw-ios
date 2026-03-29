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
        _commandsVM   = State(initialValue: CommandsViewModel(client: client, cronRepository: RemoteCronRepository(client: client), cronDetailRepository: cronDetailRepository))
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    DetailTitleView(title: "Home") {
                        homeSubtitle
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        ChatTab(client: client)
                    } label: {
                        Image("openclaw")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        NavigationLink {
                            ToolsConfigView(client: client)
                        } label: {
                            Image(systemName: "wrench.and.screwdriver")
                        }
                        NavigationLink {
                            SettingsView(keychain: keychain, client: client)
                        } label: {
                            Image(systemName: "gear")
                        }
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

    @ViewBuilder
    private var homeSubtitle: some View {
        let cronJobs = cronVM.data ?? []
        let failedCrons = cronJobs.filter { $0.status == .failed }.count
        let systemOk = systemVM.data != nil && systemVM.error == nil

        if failedCrons > 0 {
            Text("\(failedCrons) cron failure\(failedCrons == 1 ? "" : "s")")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.danger)
        } else if !systemOk && systemVM.error != nil {
            Text("System unavailable")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.warning)
        } else if cronJobs.isEmpty {
            Text("Loading\u{2026}")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
        } else {
            Text("All systems OK")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.success)
        }
    }
}
