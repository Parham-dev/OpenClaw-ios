import MarkdownUI
import SwiftUI

struct ChatView: View {
    @State var vm: ChatViewModel
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        if vm.messages.isEmpty && !vm.isLoadingHistory {
                            emptyState
                        }

                        if vm.isLoadingHistory {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, Spacing.xxl)
                        }

                        ForEach(vm.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: vm.messages.last?.content) {
                    if let last = vm.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            // Error
            if let error = vm.error {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.danger)
                    Text(error.localizedDescription)
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.danger)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
            }

            // Input
            CommentInputBar(
                placeholder: "Message your agent\u{2026}",
                text: $inputText
            ) { submitted in
                inputText = ""
                vm.send(submitted)
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if vm.isStreaming {
                    Button { vm.cancel() } label: {
                        Image(systemName: "stop.circle.fill")
                            .foregroundStyle(AppColors.danger)
                    }
                } else {
                    Button {
                        vm.reloadHistory()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoadingHistory)
                }
            }
        }
        .task { await vm.loadHistory() }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.neutral.opacity(0.3))
            Text("Send a message to your orchestrator agent.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.neutral)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: Spacing.xxl) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Spacing.xxs) {
                if isUser {
                    Text(message.content)
                        .font(AppTypography.body)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(AppColors.primaryAction, in: RoundedRectangle(cornerRadius: AppRadius.card))
                        .foregroundStyle(.white)
                } else {
                    if message.content.isEmpty && message.isStreaming {
                        HStack(spacing: Spacing.xs) {
                            ProgressView().scaleEffect(0.7)
                            Text("Thinking\u{2026}")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.neutral)
                        }
                        .padding(Spacing.sm)
                    } else {
                        Markdown(message.content)
                            .markdownTheme(.openClaw)
                            .textSelection(.enabled)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                AppColors.neutral.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: AppRadius.card)
                            )
                    }

                    if message.isStreaming && !message.content.isEmpty {
                        HStack(spacing: Spacing.xxs) {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 6, height: 6)
                            Text("Streaming")
                                .font(AppTypography.nano)
                                .foregroundStyle(AppColors.neutral)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(isUser ? "You" : "Agent"): \(message.content)")

            if !isUser { Spacer(minLength: Spacing.xxl) }
        }
    }
}

