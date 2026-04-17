import Foundation
import MCSyncAPI

public final class NoOpSyncEngine: SyncServiceAPI, @unchecked Sendable {
    public init() {}
    public func syncAll() async throws {}
    public func pushPendingChanges() async throws {}
    public func pullRemoteChanges() async throws {}
    public var isSyncing: Bool { false }
    public var lastSyncDate: Date? { nil }
}
