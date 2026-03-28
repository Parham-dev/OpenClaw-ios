import SwiftUI

struct CommandsCard: View {
    @State var vm: CommandsViewModel
    var client: GatewayClientProtocol?
    @State private var commandToConfirm: QuickCommand?

    private let columns = QuickCommand.gridColumns

    var body: some View {
        CardContainer(
            title: "Commands",
            systemImage: "terminal.fill",
            isStale: false,
            isLoading: false
        ) {
            VStack(spacing: Spacing.sm) {
                LazyVGrid(columns: columns, spacing: Spacing.xs) {
                    ForEach(Array(QuickCommand.all.prefix(QuickCommand.visibleCount))) { cmd in
                        CommandButton(
                            command: cmd,
                            isRunning: vm.isCommandRunning(cmd.id)
                        ) {
                            commandToConfirm = cmd
                        }
                    }
                }

                // Detail navigation
                if let client {
                    NavigationLink {
                        CommandsDetailView(commandsVM: vm, client: client)
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Text("View Details")
                                .font(AppTypography.caption)
                            Image(systemName: "chevron.right")
                                .font(AppTypography.micro)
                        }
                        .foregroundStyle(AppColors.primaryAction)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxs)
                    }
                }
            }
        }
        .alert("Run Command?", isPresented: Binding(
            get: { commandToConfirm != nil },
            set: { if !$0 { commandToConfirm = nil } }
        )) {
            Button("Run", role: .destructive) {
                guard let cmd = commandToConfirm else { return }
                Task { await vm.execute(cmd) }
            }
            Button("Cancel", role: .cancel) { commandToConfirm = nil }
        } message: {
            if let cmd = commandToConfirm {
                Text(cmd.confirmMessage)
            }
        }
        .sheet(item: $vm.result) { result in
            CommandResultSheet(result: result, vm: vm)
        }
    }
}
