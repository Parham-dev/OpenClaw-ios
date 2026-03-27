import SwiftUI

/// Root tab navigation — Settings accessible from Home toolbar.
struct MainTabView: View {
    private let keychain: KeychainService
    private let client: GatewayClient
    private let cronDetailRepo: CronDetailRepository

    @State private var cronVM: CronSummaryViewModel

    init(keychain: KeychainService) {
        self.keychain = keychain
        let client = GatewayClient(keychain: keychain)
        self.client = client
        self.cronDetailRepo = RemoteCronDetailRepository(client: client)
        _cronVM = State(initialValue: CronSummaryViewModel(repository: RemoteCronRepository(client: client)))
    }

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView(keychain: keychain, client: client, cronVM: cronVM)
            }

            Tab("Crons", systemImage: "clock.arrow.2.circlepath") {
                CronsTab(vm: cronVM, detailRepository: cronDetailRepo)
            }

            Tab("Pipelines", systemImage: "bolt.fill") {
                PipelinesPlaceholderTab()
            }

            Tab("Memory", systemImage: "brain") {
                MemoryTab()
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                ChatTab()
            }
        }
    }
}
