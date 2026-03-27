import Foundation
import Observation

@Observable
@MainActor
final class CronDetailViewModel {
    var runs: [CronRun] = []
    var isLoading = false
    var isLoadingMore = false
    var error: Error?
    var isTriggering = false
    var isTogglingEnabled = false
    var hasMore = true

    let job: CronJob
    private let repository: CronDetailRepository
    private let onJobUpdated: () async -> Void
    private static let pageSize = 20

    init(job: CronJob, repository: CronDetailRepository, onJobUpdated: @escaping () async -> Void) {
        self.job = job
        self.repository = repository
        self.onJobUpdated = onJobUpdated
    }

    func loadRuns() async {
        isLoading = true
        do {
            let result = try await repository.fetchRuns(jobId: job.id, limit: Self.pageSize, offset: 0)
            runs = result.runs
            hasMore = result.hasMore
            error = nil
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let result = try await repository.fetchRuns(jobId: job.id, limit: Self.pageSize, offset: runs.count)
            let existingIds = Set(runs.map(\.id))
            let newRuns = result.runs.filter { !existingIds.contains($0.id) }
            runs.append(contentsOf: newRuns)
            hasMore = result.hasMore && !newRuns.isEmpty
        } catch {
            self.error = error
        }
        isLoadingMore = false
    }

    func triggerRun() async {
        isTriggering = true
        do {
            try await repository.triggerRun(jobId: job.id)
            Haptics.shared.success()
            await loadRuns()
            await onJobUpdated()
        } catch {
            self.error = error
            Haptics.shared.error()
        }
        isTriggering = false
    }

    func toggleEnabled() async {
        isTogglingEnabled = true
        let newEnabled = !job.enabled
        do {
            try await repository.setEnabled(jobId: job.id, enabled: newEnabled)
            Haptics.shared.success()
            await onJobUpdated()
        } catch {
            self.error = error
            Haptics.shared.error()
        }
        isTogglingEnabled = false
    }
}
