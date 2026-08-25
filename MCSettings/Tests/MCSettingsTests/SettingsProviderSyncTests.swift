import Foundation
import Testing
@testable import MCSettings

/// O provider não guarda estado de sync — ele lê do `SyncServiceAPI`, que é `@Observable`.
/// Então testar aqui é testar a derivação: dado um estado do serviço, qual label a UI mostra.
@Suite("SettingsProvider — sync")
struct SettingsProviderSyncTests {

    @MainActor
    private func makeSUT(sync: SpySyncService) -> SettingsProvider.Mock {
        SettingsProvider.Mock(
            allHabits: [],
            navigator: SpyNavigator(),
            syncService: sync,
            authService: SpyAuthService()
        )
    }

    @Test @MainActor
    func syncNowDelegaProServico() {
        let spy = SpySyncService()
        let sut = makeSUT(sync: spy)

        sut.syncNow()

        #expect(spy.syncCallCount == 1)
    }

    /// A dedução de chamada dupla mora no serviço, não no provider — então o provider repassa
    /// sempre, e é o `NoOpSyncEngine`/`FakeSyncService` que ignora a segunda.
    @Test @MainActor
    func syncNowRepassaTodaChamada() {
        let spy = SpySyncService()
        let sut = makeSUT(sync: spy)

        sut.syncNow()
        sut.syncNow()

        #expect(spy.syncCallCount == 2)
    }

    @Test @MainActor
    func semSyncNenhumMostraNeverSynced() {
        let sut = makeSUT(sync: SpySyncService())

        #expect(sut.isSyncing == false)
        #expect(sut.syncDetail == "Never synced")
    }

    @Test @MainActor
    func sincronizandoTemPrecedenciaSobreOResto() {
        let spy = SpySyncService()
        spy.isSyncing = true
        spy.lastSyncDate = .now
        spy.lastSyncError = "Network unavailable"

        let sut = makeSUT(sync: spy)

        #expect(sut.isSyncing)
        #expect(sut.syncDetail == "Syncing…")
    }

    @Test @MainActor
    func erroApareceNoLugarDaData() {
        let spy = SpySyncService()
        spy.lastSyncError = "Network unavailable"
        spy.lastSyncDate = .now

        let sut = makeSUT(sync: spy)

        #expect(sut.syncDetail == "Network unavailable")
    }

    @Test @MainActor
    func semErroMostraADataRelativa() {
        let spy = SpySyncService()
        spy.lastSyncDate = Calendar.current.date(byAdding: .hour, value: -2, to: .now)

        let sut = makeSUT(sync: spy)

        #expect(sut.syncDetail != "Never synced")
        #expect(sut.syncDetail != "Syncing…")
        #expect(sut.syncDetail.isEmpty == false)
    }
}
