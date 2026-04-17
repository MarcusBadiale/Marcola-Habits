import Foundation

public protocol SyncServiceAPI: Sendable {
    func syncAll() async throws
    func pushPendingChanges() async throws
    func pullRemoteChanges() async throws
    var isSyncing: Bool { get }
    var lastSyncDate: Date? { get }
}
