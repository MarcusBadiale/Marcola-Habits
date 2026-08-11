import SwiftUI

struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: SyncServiceAPI = NoOpSyncService()
}

public extension EnvironmentValues {
    var syncService: SyncServiceAPI {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}

private final class NoOpSyncService: SyncServiceAPI, @unchecked Sendable {
    var isSyncing: Bool { false }
    var lastSyncDate: Date? { nil }
    func syncAll() async throws {}
    func pushPendingChanges() async throws {}
    func pullRemoteChanges() async throws {}
}
