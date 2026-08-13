import Foundation
import MCDomain
import MCSettingsAPI
import Testing
@testable import MCSettings

@Suite("SettingsProvider")
struct SettingsProviderTests {

    @MainActor
    private func makeSUT(
        habits: [HabitModel] = [],
        theme: AppTheme = .system,
        navigator: SpyNavigator = SpyNavigator()
    ) -> SettingsProvider.Mock {
        SettingsProvider.Mock(
            allHabits: habits,
            navigator: navigator,
            syncService: SpySyncService(),
            authService: SpyAuthService(),
            themeRawValue: theme.rawValue
        )
    }

    // MARK: - Arquivados

    @Test @MainActor
    func contaSoOsArquivados() {
        let sut = makeSUT(habits: [
            TestHelpers.makeHabit(name: "Run", isArchived: true),
            TestHelpers.makeHabit(name: "Read", isArchived: true),
            TestHelpers.makeHabit(name: "Meditate"),
        ])

        #expect(sut.archivedCount == 2)
        #expect(sut.archivedDetail == "2")
    }

    @Test @MainActor
    func detalheDeArquivadosVaziosEhNone() {
        let sut = makeSUT(habits: [TestHelpers.makeHabit()])

        #expect(sut.archivedCount == 0)
        #expect(sut.archivedDetail == "None")
    }

    // MARK: - Tema

    @Test @MainActor
    func temaVemDoStorage() {
        #expect(makeSUT(theme: .dark).theme == .dark)
        #expect(makeSUT(theme: .dark).themeDetail == "Dark")
    }

    @Test @MainActor
    func temaInvalidoCaiEmSystem() {
        let sut = SettingsProvider.Mock(
            allHabits: [],
            navigator: SpyNavigator(),
            syncService: SpySyncService(),
            authService: SpyAuthService(),
            themeRawValue: "sepia"
        )

        #expect(sut.theme == .system)
        #expect(sut.themeDetail == "System")
    }

    // MARK: - Navegação

    @Test @MainActor
    func navegaProAppearance() {
        let spy = SpyNavigator()
        var sut = makeSUT(navigator: spy)

        sut.goToAppearance()

        #expect(spy.pushCalls.count == 1)
        #expect(spy.pushCalls.first?.route == SettingsRoutes.appearance)
    }

    @Test @MainActor
    func navegaProExport() {
        let spy = SpyNavigator()
        var sut = makeSUT(navigator: spy)

        sut.goToExport()

        #expect(spy.pushCalls.first?.route == SettingsRoutes.exportData)
    }

    @Test @MainActor
    func navegaProArquivados() {
        let spy = SpyNavigator()
        var sut = makeSUT(navigator: spy)

        sut.goToArchived()

        #expect(spy.pushCalls.first?.route == SettingsRoutes.archivedHabits)
    }

    /// As rotas de conta e notificações são declaradas na API mas não registradas — o login é
    /// inline no card e notificações é "Coming soon". Nenhuma função do provider empurra elas.
    @Test @MainActor
    func naoNavegaProContaNemNotificacoes() {
        let spy = SpyNavigator()
        var sut = makeSUT(navigator: spy)

        sut.goToAppearance()
        sut.goToExport()
        sut.goToArchived()

        let rotas = spy.pushCalls.map(\.route)
        #expect(rotas.contains(SettingsRoutes.account) == false)
        #expect(rotas.contains(SettingsRoutes.notifications) == false)
        #expect(spy.presentCalls.isEmpty)
    }
}
