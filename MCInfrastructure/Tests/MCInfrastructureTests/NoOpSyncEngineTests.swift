import Foundation
import Testing
@testable import MCSync

@Suite("NoOpSyncEngine")
struct NoOpSyncEngineTests {

    @Test("começa sem nunca ter sincronizado")
    @MainActor
    func estadoInicial() {
        let sut = NoOpSyncEngine()

        #expect(sut.isSyncing == false)
        #expect(sut.lastSyncDate == nil)
        #expect(sut.lastSyncError == nil)
    }

    @Test("sync grava lastSyncDate e volta a isSyncing == false")
    @MainActor
    func syncCompleta() async {
        let sut = NoOpSyncEngine()

        sut.sync()
        await Task.yield()
        // Cede o suficiente pro Task interno rodar e o defer executar.
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.isSyncing == false)
        #expect(sut.lastSyncDate != nil)
        #expect(sut.lastSyncError == nil)
    }

    @Test("chamada dupla enquanto sincroniza é ignorada")
    @MainActor
    func dedupeChamadaDupla() async {
        let sut = NoOpSyncEngine()

        // As duas chamadas acontecem antes de qualquer suspensão, então a segunda cai no guard.
        sut.sync()
        #expect(sut.isSyncing == true)
        sut.sync()

        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.isSyncing == false)
        #expect(sut.lastSyncDate != nil)
    }

    @Test("sincronizar de novo depois de terminar funciona")
    @MainActor
    func segundoSyncDepoisDoPrimeiro() async {
        let sut = NoOpSyncEngine()

        sut.sync()
        try? await Task.sleep(for: .milliseconds(50))
        let primeiro = sut.lastSyncDate

        sut.sync()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(primeiro != nil)
        #expect(sut.lastSyncDate != nil)
        #expect(sut.lastSyncDate! >= primeiro!)
    }
}
