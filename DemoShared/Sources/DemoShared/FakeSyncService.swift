import Foundation
import MCSyncAPI

/// Sync fake pros Demo Apps. Diferente do `NoOpSyncEngine`, tem uma latência artificial — sem ela
/// o `isSyncing` liga e desliga no mesmo frame e não há janela pra ver o spinner nem pro UI test
/// assertar o estado intermediário.
@MainActor
@Observable
public final class FakeSyncService: SyncServiceAPI {

    public private(set) var isSyncing = false
    public private(set) var lastSyncDate: Date?
    public private(set) var lastSyncError: String?

    private let duration: Duration
    private var task: Task<Void, Never>?

    public init(duration: Duration = .milliseconds(800)) {
        self.duration = duration
    }

    public func sync() {
        guard task == nil else { return }

        isSyncing = true
        lastSyncError = nil

        task = Task { [weak self, duration] in
            defer {
                self?.isSyncing = false
                self?.task = nil
            }
            try? await Task.sleep(for: duration)
            self?.lastSyncDate = .now
        }
    }
}
