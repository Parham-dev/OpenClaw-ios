import SwiftUI

struct SessionTraceView: View {
    let title: String
    let subtitle: String?
    let sessionKey: String
    let repository: SessionRepository
    let newestFirst: Bool
    var client: GatewayClientProtocol?

    @State private var trace: SessionTrace?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var expandedStepId: String?
    @State private var commentTarget: TraceStep?
    @State private var comments: [TraceComment] = []
    @State private var showSubmitSheet = false

    /// Init from a cron run (existing usage — oldest first).
    init(run: CronRun, repository: CronDetailRepository, jobName: String? = nil, client: GatewayClientProtocol? = nil) {
        self.title = jobName ?? "Run Trace"
        self.subtitle = run.runAtAbsolute
        self.sessionKey = run.sessionKey ?? run.sessionId ?? ""
        self.repository = SessionRepositoryAdapter(cronRepo: repository)
        self.newestFirst = false
        self.client = client
    }

    /// Init from a session key directly (sessions tab).
    init(sessionKey: String, title: String, subtitle: String? = nil, newestFirst: Bool = false, repository: SessionRepository, client: GatewayClientProtocol? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.sessionKey = sessionKey
        self.repository = repository
        self.newestFirst = newestFirst
        self.client = client
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.neutral)
                    }
                }
            }

            // Trace steps
            if isLoading && trace == nil {
                Section("Execution Trace") {
                    CardLoadingView(minHeight: 100)
                }
            } else if let trace {
                Section {
                    ForEach(newestFirst ? trace.steps.reversed() : trace.steps) { step in
                        TraceStepRow(
                            step: step,
                            isExpanded: expandedStepId == step.id,
                            onTap: {
                                withAnimation(.snappy(duration: 0.3)) {
                                    expandedStepId = expandedStepId == step.id ? nil : step.id
                                }
                            },
                            onComment: client != nil ? { commentTarget = step } : nil,
                            comments: comments.filter { $0.stepId == step.id },
                            onRemoveComment: { id in comments.removeAll { $0.id == id } }
                        )
                    }

                    if trace.truncated {
                        HStack {
                            Spacer()
                            Label("History truncated — older steps not shown", systemImage: "ellipsis.circle")
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.neutral)
                            Spacer()
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                } header: {
                    HStack {
                        Text("Execution Trace")
                        Text("(\(trace.steps.count) steps)")
                            .foregroundStyle(AppColors.neutral)
                    }
                }
            } else if let error {
                Section("Execution Trace") {
                    CardErrorView(error: error)
                }
            } else if sessionKey.isEmpty {
                Section("Execution Trace") {
                    Text("No session data available.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.neutral)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trace")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !comments.isEmpty && client != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSubmitSheet = true } label: {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "paperplane.fill")
                            Text("\(comments.count)")
                        }
                        .foregroundStyle(AppColors.primaryAction)
                    }
                }
            }
        }
        .sheet(item: $commentTarget) { step in
            CommentSheet(mode: .paragraph(preview: step.contentPreview) { text in
                comments.append(TraceComment(step: step, text: text))
            })
        }
        .sheet(isPresented: $showSubmitSheet) {
            if let client {
                TraceCommentsSheet(
                    sessionKey: sessionKey,
                    sessionTitle: title,
                    client: client,
                    comments: $comments
                )
            }
        }
        .task {
            guard !sessionKey.isEmpty else { return }
            isLoading = true
            do {
                trace = try await repository.fetchTrace(sessionKey: sessionKey, limit: 100)
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}

/// Adapter so CronDetailRepository can be used where SessionRepository is expected.
private struct SessionRepositoryAdapter: SessionRepository {
    let cronRepo: CronDetailRepository

    @MainActor func fetchSessions(limit: Int) async throws -> [SessionEntry] { [] }

    func fetchTrace(sessionKey: String, limit: Int) async throws -> SessionTrace {
        try await cronRepo.fetchSessionTrace(sessionKey: sessionKey, limit: limit)
    }
}
