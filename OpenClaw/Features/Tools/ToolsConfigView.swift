import SwiftUI

struct ToolsConfigView: View {
    @State private var vm: ToolsConfigViewModel
    private let client: GatewayClientProtocol

    init(client: GatewayClientProtocol) {
        self.client = client
        _vm = State(initialValue: ToolsConfigViewModel(client: client))
    }

    var body: some View {
        List {
            if vm.isLoading && vm.config == nil {
                CardLoadingView(minHeight: 100)
            } else if let config = vm.config {
                nativeToolsSection(config)
                mcpSection
            } else if let err = vm.error {
                CardErrorView(error: err, minHeight: 60)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tools & MCP")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !vm.mcpServers.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        McpServersView(vm: vm)
                    } label: {
                        Image(systemName: "server.rack")
                    }
                }
            }
        }
        .refreshable {
            await vm.load()
            Haptics.shared.refreshComplete()
        }
        .task { await vm.load() }
    }

    // MARK: - Native Tools

    @ViewBuilder
    private func nativeToolsSection(_ config: ToolsConfig) -> some View {
        Section {
            HStack {
                Text("Profile")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.neutral)
                Spacer()
                Text(config.profile.capitalized)
                    .font(AppTypography.captionBold)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(config.profileColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(config.profileColor)
            }

            if !config.allow.isEmpty {
                LabeledContent("Allow") {
                    Text(config.allow.joined(separator: ", "))
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.success)
                }
            }
            if !config.deny.isEmpty {
                LabeledContent("Deny") {
                    Text(config.deny.joined(separator: ", "))
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.danger)
                }
            }
        } header: {
            HStack {
                Text("Native Tools")
                let count = config.groups.reduce(0) { $0 + $1.tools.count }
                Text("(\(count))")
                    .foregroundStyle(AppColors.neutral)
            }
        }

        ForEach(config.groups) { group in
            Section {
                ForEach(group.tools) { tool in
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(tool.name)
                            .font(AppTypography.captionMono)
                        if !tool.description.isEmpty {
                            Text(tool.description)
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.neutral)
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            } header: {
                Label(group.name, systemImage: group.icon)
            }
        }
    }

    // MARK: - MCP Servers (summary rows)

    @ViewBuilder
    private var mcpSection: some View {
        if !vm.mcpServers.isEmpty {
            Section("MCP Servers") {
                ForEach(vm.mcpServers) { server in
                    NavigationLink {
                        McpServersView(vm: vm)
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "server.rack")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.metricTertiary)
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(server.name)
                                    .font(AppTypography.body)
                                    .fontWeight(.medium)
                                Text(server.runtime)
                                    .font(AppTypography.micro)
                                    .foregroundStyle(AppColors.neutral)
                            }
                            Spacer()
                            if let detail = vm.mcpDetails[server.id] {
                                Text("\(detail.tools.count) tools")
                                    .font(AppTypography.micro)
                                    .foregroundStyle(detail.statusColor)
                            }
                        }
                    }
                }
            }
        }
    }

}
