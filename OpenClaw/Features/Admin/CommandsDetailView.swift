import SwiftUI

struct CommandsDetailView: View {
    @State var commandsVM: CommandsViewModel
    @State private var adminVM: AdminViewModel
    @State private var commandToConfirm: QuickCommand?

    private let columns = QuickCommand.gridColumns

    init(commandsVM: CommandsViewModel, client: GatewayClientProtocol) {
        self.commandsVM = commandsVM
        _adminVM = State(initialValue: AdminViewModel(client: client))
    }

    var body: some View {
        List {
            // All commands grid
            Section("Commands") {
                LazyVGrid(columns: columns, spacing: Spacing.xs) {
                    ForEach(QuickCommand.all) { cmd in
                        CommandButton(
                            command: cmd,
                            isRunning: commandsVM.isCommandRunning(cmd.id)
                        ) {
                            commandToConfirm = cmd
                        }
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }

            // Admin sections
            if adminVM.isLoading && adminVM.modelsConfig == nil {
                Section("Models & Config") {
                    CardLoadingView(minHeight: 60)
                }
                Section("Channels") {
                    CardLoadingView(minHeight: 60)
                }
            } else {
                if let config = adminVM.modelsConfig {
                    ModelsSection(config: config, agents: adminVM.agents)
                }

                if let channels = adminVM.channelsStatus {
                    ChannelsSection(status: channels)
                }

                if let err = adminVM.error, adminVM.modelsConfig == nil {
                    Section {
                        CardErrorView(error: err, minHeight: 60)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Commands & Admin")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await adminVM.load()
            Haptics.shared.refreshComplete()
        }
        .task { await adminVM.load() }
        .alert("Run Command?", isPresented: Binding(
            get: { commandToConfirm != nil },
            set: { if !$0 { commandToConfirm = nil } }
        )) {
            Button("Run", role: .destructive) {
                guard let cmd = commandToConfirm else { return }
                Task { await commandsVM.execute(cmd) }
            }
            Button("Cancel", role: .cancel) { commandToConfirm = nil }
        } message: {
            if let cmd = commandToConfirm {
                Text(cmd.confirmMessage)
            }
        }
        .sheet(item: $commandsVM.result) { result in
            CommandResultSheet(result: result, vm: commandsVM)
        }
    }
}
