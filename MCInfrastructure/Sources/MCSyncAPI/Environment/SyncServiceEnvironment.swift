import SwiftUI

struct SyncServiceKey: EnvironmentKey {
    // `nonisolated(unsafe)` porque `EnvironmentKey.defaultValue` é um requisito nonisolated e o
    // `SyncServiceAPI` é `@MainActor`. É seguro: o default é um no-op sem estado mutável, e o
    // Environment do SwiftUI só é lido na main actor. Mesmo padrão de `NavigatorAPIKey`.
    nonisolated(unsafe) static let defaultValue: any SyncServiceAPI = NoOpSyncService()
}

public extension EnvironmentValues {
    var syncService: any SyncServiceAPI {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}

/// Default privado do próprio módulo API, pra não inverter a dependência API → Impl.
/// Quem quer comportamento real injeta `.environment(\.syncService, ...)`.
@Observable
private final class NoOpSyncService: SyncServiceAPI {
    var isSyncing: Bool { false }
    var lastSyncDate: Date? { nil }
    var lastSyncError: String? { nil }
    func sync() {}
}
