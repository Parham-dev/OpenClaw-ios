import Foundation
import Observation

/// Generic base for ViewModels that load data from a single async source.
/// Eliminates duplicated isLoading / error / isStale / start / refresh boilerplate.
@Observable
@MainActor
class LoadableViewModel<T: Sendable> {
    var data: T?
    var isLoading = false
    var error: Error?

    var isStale: Bool { error != nil && data != nil }

    private let loader: @Sendable () async throws -> T
    private var activeTask: Task<Void, Never>?

    nonisolated init(loader: @escaping @Sendable () async throws -> T) {
        self.loader = loader
    }

    /// Call from `.task { }` — kicks off initial fetch.
    func start() {
        guard activeTask == nil else { return }
        activeTask = Task { await fetch() }
    }

    /// Call from `.refreshable { }` — awaitable so the refresh indicator works.
    func refresh() async {
        activeTask?.cancel()
        activeTask = nil
        await fetch()
    }

    /// Cancel in-flight work (called when view disappears).
    func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }

    private func fetch() async {
        if data == nil { isLoading = true }
        do {
            let result = try await loader()
            guard !Task.isCancelled else { return }
            data = result
            error = nil
        } catch is CancellationError {
            // Silently ignore cancellation
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error
        }
        isLoading = false
    }
}
