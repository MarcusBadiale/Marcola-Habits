import Foundation
import MCSyncAPI

/// Registra as chamadas e deixa o estado stubável, pra assertar tanto *que* o provider disparou o
/// sync quanto *como* ele deriva o label a partir do estado do serviço.
@MainActor
@Observable
final class SpySyncService: SyncServiceAPI {

    private(set) var syncCallCount = 0

    var isSyncing: Bool = false
    var lastSyncDate: Date? = nil
    var lastSyncError: String? = nil

    func sync() { syncCallCount += 1 }
}
