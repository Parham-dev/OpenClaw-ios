import MarkdownUI
import SwiftUI

/// Action picker + execution sheet for memory/skills maintenance tasks.
struct MemoryActionSheet: View {
    let tab: MemoryTab.WorkspaceTab
    var vm: MemoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAction: MemoryAction?
    @State private var isRunning = false
    @State private var result: String?
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            List {
                if result == nil && !isRunning {
                    Section("Choose Action") {
                        ForEach(actions) { action in
                            Button {
                                selectedAction = action
                                Task { await run(action) }
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: action.icon)
                                        .font(AppTypography.statusIcon)
                                        .foregroundStyle(action.color)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                                        Text(action.name)
                                            .font(AppTypography.body)
                                            .fontWeight(.medium)
                                        Text(action.description)
                                            .font(AppTypography.micro)
                                            .foregroundStyle(AppColors.neutral)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, Spacing.xxs)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isRunning {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: Spacing.xs) {
                                ProgressView()
                                Text(selectedAction?.loadingText ?? "Working\u{2026}")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.neutral)
                                ElapsedTimer()
                            }
                            Spacer()
                        }
                        .padding(.vertical, Spacing.md)
                    }
                }

                if let response = result {
                    Section("Agent Response") {
                        Markdown(response)
                            .markdownTheme(.openClaw)
                            .textSelection(.enabled)
                    }
                }

                if let error {
                    Section {
                        Label(error.localizedDescription, systemImage: "xmark.circle.fill")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.danger)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(result != nil || error != nil ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Actions per tab

    private var actions: [MemoryAction] {
        switch tab {
        case .memory:
            return [
                MemoryAction(
                    id: "full-cleanup",
                    name: "Full Cleanup",
                    description: "Read docs, update today, then clean all memory files",
                    icon: "sparkles",
                    color: AppColors.metricTertiary,
                    loadingText: "Agent is reading docs and cleaning all memory\u{2026}",
                    prompt: PromptTemplates.memoryFullCleanup
                ),
                MemoryAction(
                    id: "today-cleanup",
                    name: "Today Cleanup",
                    description: "Read docs, update today's memory only",
                    icon: "calendar.badge.clock",
                    color: AppColors.primaryAction,
                    loadingText: "Agent is updating today's memory\u{2026}",
                    prompt: PromptTemplates.memoryTodayCleanup
                ),
            ]
        case .skills:
            return []
        }
    }

    // MARK: - Execute

    private func run(_ action: MemoryAction) async {
        isRunning = true
        error = nil
        result = nil

        let prompt = action.prompt()
        await vm.runMaintenanceAction(prompt: prompt)

        result = vm.maintenanceResult
        error = vm.maintenanceError
        isRunning = false
    }
}

// MARK: - Action Model

struct MemoryAction: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let loadingText: String
    let prompt: () -> (system: String, user: String)
}
