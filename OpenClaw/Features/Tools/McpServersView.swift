import SwiftUI

/// Dedicated MCP servers page with full tool descriptions.
struct McpServersView: View {
    @State var vm: ToolsConfigViewModel

    var body: some View {
        List {
            if vm.isLoadingMcpTools && vm.mcpDetails.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: Spacing.xs) {
                            ProgressView()
                            Text("Querying MCP servers\u{2026}")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.neutral)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Spacing.md)
                }
            }

            ForEach(vm.mcpServers) { server in
                mcpServerSection(server)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("MCP Servers")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadMcpTools() }
    }

    @ViewBuilder
    private func mcpServerSection(_ server: McpServer) -> some View {
        Section {
            // Runtime
            LabeledContent("Runtime") {
                Text(server.runtime)
                    .font(AppTypography.captionMono)
                    .foregroundStyle(AppColors.neutral)
            }

            // Status
            if let detail = vm.mcpDetails[server.id] {
                LabeledContent("Status") {
                    Text(detail.status)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(detail.statusColor)
                }

                // Tools
                if detail.isOk {
                    ForEach(detail.tools, id: \.name) { tool in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(tool.name)
                                .font(AppTypography.captionMono)
                            if let desc = tool.description, !desc.isEmpty {
                                Text(desc)
                                    .font(AppTypography.micro)
                                    .foregroundStyle(AppColors.neutral)
                            }
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                }

                if let error = detail.error {
                    Label(error, systemImage: "xmark.circle.fill")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.danger)
                }
            } else if vm.isLoadingMcpTools {
                HStack {
                    Spacer()
                    ProgressView().scaleEffect(0.8)
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text(server.name)
                if let detail = vm.mcpDetails[server.id], detail.isOk {
                    Text("(\(detail.tools.count) tools)")
                        .foregroundStyle(AppColors.neutral)
                }
            }
        }
    }

}
