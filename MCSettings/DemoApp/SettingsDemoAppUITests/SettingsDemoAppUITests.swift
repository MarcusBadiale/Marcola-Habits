import XCTest

final class SettingsFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // O UserDefaults do Demo App persiste entre execuções no simulador — sem resetar, um teste
        // que muda o tema contamina o próximo run. O app apaga as chaves; passar `-mcSettingsTheme
        // system` NÃO serviria, porque o NSArgumentDomain tem precedência maior que o domínio do
        // app e travaria o valor contra qualquer escrita da tela.
        app.launchArguments = ["--reset-appearance"]
        app.launch()
    }

    // MARK: - Root

    @MainActor
    func testSettingsShowsAllSections() {
        SettingsPage(app: app)
            .assertVisible()
            .assertSectionsVisible()
            .assertDisabledRowsExist()
    }

    @MainActor
    func testDisabledRowsDoNotNavigate() {
        SettingsPage(app: app)
            .assertVisible()
            .tapDisabledRow("settings-notifications-row")
            .tapDisabledRow("settings-rate-row")
            // Continua na root: nenhuma das duas tem destino registrado.
            .assertVisible()
            .assertSectionsVisible()
    }

    /// Prova ponta a ponta que a observação atravessa o existencial `any SyncServiceAPI`: o
    /// `FakeSyncService` só grava `lastSyncDate` depois de ~800ms, então o label ter deixado de
    /// ser "Never synced" só é possível se o SwiftUI reagiu à mudança dentro do serviço.
    @MainActor
    func testSyncUpdatesTheLastSyncLabel() {
        SettingsPage(app: app)
            .assertVisible()
            .assertTextExists("Never synced")
            .tapSync()
            .assertSyncLabelChangedFromNever()
    }

    /// Mesma prova, do lado do auth: o card só troca pra "Marcus" depois do delay do
    /// `FakeAuthService`.
    @MainActor
    func testSignInUpdatesTheAccountCard() {
        SettingsPage(app: app)
            .assertVisible()
            .assertTextExists("Not signed in")
            .assertAccountActionTitle("Sign in with Apple")
            .tapAccountAction()
            .assertTextExists("Marcus")
            .assertAccountActionTitle("Sign out")
    }

    // MARK: - Arquivados

    @MainActor
    func testUnarchiveRemovesHabitFromList() {
        SettingsPage(app: app)
            .assertVisible()
            .tapArchived()
            .assertVisible()
            // "Correr 5km" é o arquivado que o DemoSeedData insere.
            .assertHabitExists("Correr 5km")
            .unarchive(at: 0)
            .assertHabitGone("Correr 5km")
            .assertEmpty()
    }

    @MainActor
    func testDeleteArchivedHabitAsksForConfirmation() {
        SettingsPage(app: app)
            .assertVisible()
            .tapArchived()
            .assertVisible()
            .requestDelete(at: 0)
            .assertConfirmationVisible()
            .confirmDelete()
            .assertHabitGone("Correr 5km")
    }

    // Sem UI test pro cancelamento do delete: neste iOS o `confirmationDialog` é apresentado como
    // popover e **não expõe botão de Cancel na árvore de acessibilidade** — dispensar depende de
    // tocar fora, que não é confiável em XCUITest. O que é código nosso (`cancelDelete()` não
    // apagar nada e limpar o pendente) está coberto em ArchivedHabitsProviderTests; o que sobraria
    // aqui é o mecanismo de dispensa do SwiftUI.

    // MARK: - Aparência

    @MainActor
    func testThemeSelectionPersistsAcrossNavigation() {
        SettingsPage(app: app)
            .assertVisible()
            .tapTheme()
            .assertVisible()
            .selectTheme("Dark")
            .goBack()
            .assertRowDetail("settings-theme-row", contains: "Dark")
            .tapTheme()
            .assertThemeSelected("Dark")
    }

    @MainActor
    func testSelectingAccentKeepsScreenUsable() {
        SettingsPage(app: app)
            .assertVisible()
            .tapTheme()
            .assertVisible()
            .selectAccent(at: 4)
            .assertVisible()
            .goBack()
            .assertVisible()
    }

    // MARK: - Export

    @MainActor
    func testExportScreenBuildsTheFile() {
        SettingsPage(app: app)
            .assertVisible()
            .tapExport()
            .assertVisible()
            .assertShareAvailable()
            .assertSizeComputed()
            .assertNoError()
            .assertDisclaimerVisible()
    }
}
