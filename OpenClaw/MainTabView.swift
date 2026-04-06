import SwiftUI

/// Root navigation — tab bar on iOS, sidebar on macOS.
struct MainTabView: View {
    let accountStore: AccountStore
    private let client: GatewayClientProtocol
    private let cronDetailRepo: CronDetailRepository
    private let sessionRepo: SessionRepository

    @State private var cronVM: CronSummaryViewModel
    @State private var memoryVM: MemoryViewModel
    @State private var sessionsVM: SessionsViewModel

    init(accountStore: AccountStore) {
        self.accountStore = accountStore
        guard let client = GatewayClient(accountStore: accountStore) else {
            fatalError("MainTabView created without a configured account")
        }
        self.client = client
        self.cronDetailRepo = RemoteCronDetailRepository(client: client)
        let sessionRepo = RemoteSessionRepository(client: client)
        self.sessionRepo = sessionRepo
        _cronVM = State(initialValue: CronSummaryViewModel(repository: RemoteCronRepository(client: client)))
        _memoryVM = State(initialValue: MemoryViewModel(
            repository: RemoteMemoryRepository(client: client, sessionKey: SessionKeys.main, workspaceRoot: AppConstants.workspaceRoot),
            client: client
        ))
        _sessionsVM = State(initialValue: SessionsViewModel(repository: sessionRepo))
    }

    var body: some View {
        #if os(macOS)
        macBody
        #else
        iosBody
        #endif
    }

    // MARK: - iOS (Tab Bar)

    #if !os(macOS)
    private var iosBody: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView(accountStore: accountStore, client: client, cronVM: cronVM, cronDetailRepository: cronDetailRepo)
            }
            Tab("Crons", systemImage: "clock.arrow.2.circlepath") {
                CronsTab(vm: cronVM, detailRepository: cronDetailRepo, client: client)
            }
            Tab("Mem & Skills", systemImage: "brain") {
                MemoryTab(vm: memoryVM)
            }
            Tab("Sessions", systemImage: "bubble.left.and.text.bubble.right") {
                SessionsView(vm: sessionsVM, repository: sessionRepo, client: client)
            }
            Tab("More", systemImage: "ellipsis.circle") {
                MoreTab(client: client)
            }
        }
    }
    #endif

    // MARK: - macOS (Sidebar)

    #if os(macOS)
    @State private var selection: SidebarItem? = .home

    enum SidebarItem: String, CaseIterable, Identifiable {
        case home = "Home"
        case crons = "Crons"
        case memSkills = "Mem & Skills"
        case sessions = "Sessions"
        case chat = "Chat"
        case settings = "Settings"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .home: "house.fill"
            case .crons: "clock.arrow.2.circlepath"
            case .memSkills: "brain"
            case .sessions: "bubble.left.and.text.bubble.right"
            case .chat: "bubble.left.and.bubble.right"
            case .settings: "gear"
            }
        }
    }

    private var macBody: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationTitle("OpenClaw")
        } detail: {
            switch selection {
            case .home:
                HomeView(accountStore: accountStore, client: client, cronVM: cronVM, cronDetailRepository: cronDetailRepo)
            case .crons:
                CronsTab(vm: cronVM, detailRepository: cronDetailRepo, client: client)
            case .memSkills:
                MemoryTab(vm: memoryVM)
            case .sessions:
                SessionsView(vm: sessionsVM, repository: sessionRepo, client: client)
            case .chat:
                ChatTab(client: client)
            case .settings:
                SettingsView(accountStore: accountStore, client: client)
            case nil:
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
    #endif
}
