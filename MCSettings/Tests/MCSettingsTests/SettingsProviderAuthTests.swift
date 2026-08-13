import Foundation
import MCAuthAPI
import Testing
@testable import MCSettings

@Suite("SettingsProvider — conta")
struct SettingsProviderAuthTests {

    @MainActor
    private func makeSUT(auth: SpyAuthService) -> SettingsProvider.Mock {
        SettingsProvider.Mock(
            allHabits: [],
            navigator: SpyNavigator(),
            syncService: SpySyncService(),
            authService: auth
        )
    }

    private var marcus: AuthUser {
        AuthUser(id: "demo-user", displayName: "Marcus", email: "marcus@marcola.app")
    }

    @Test @MainActor
    func deslogadoOfereceEntrar() {
        let sut = makeSUT(auth: SpyAuthService())

        #expect(sut.isSignedIn == false)
        #expect(sut.accountName == "Not signed in")
        #expect(sut.accountActionTitle == "Sign in with Apple")
        #expect(sut.accountDetail == "Sync your habits across devices")
    }

    @Test @MainActor
    func logadoMostraNomeEEmail() {
        let spy = SpyAuthService()
        spy.session = .signedIn(marcus)

        let sut = makeSUT(auth: spy)

        #expect(sut.isSignedIn)
        #expect(sut.accountName == "Marcus")
        #expect(sut.accountDetail == "marcus@marcola.app")
        #expect(sut.accountActionTitle == "Sign out")
    }

    @Test @MainActor
    func toggleEntraQuandoDeslogado() {
        let spy = SpyAuthService()
        var sut = makeSUT(auth: spy)

        sut.toggleAccount()

        #expect(spy.signInCallCount == 1)
        #expect(spy.signOutCallCount == 0)
    }

    @Test @MainActor
    func toggleSaiQuandoLogado() {
        let spy = SpyAuthService()
        spy.session = .signedIn(marcus)
        var sut = makeSUT(auth: spy)

        sut.toggleAccount()

        #expect(spy.signOutCallCount == 1)
        #expect(spy.signInCallCount == 0)
    }

    @Test @MainActor
    func erroDeAuthApareceNoDetalhe() {
        let spy = SpyAuthService()
        spy.lastAuthError = "Sign in failed"

        let sut = makeSUT(auth: spy)

        #expect(sut.accountDetail == "Sign in failed")
    }

    @Test @MainActor
    func isAuthenticatingVemDoServico() {
        let spy = SpyAuthService()
        spy.isAuthenticating = true

        #expect(makeSUT(auth: spy).isAuthenticating)
        #expect(makeSUT(auth: SpyAuthService()).isAuthenticating == false)
    }

    @Test("session sem usuário não é signedIn")
    func sessionEnumNaoTemEstadoImpossivel() {
        #expect(AuthSession.signedOut.user == nil)
        #expect(AuthSession.signedOut.isSignedIn == false)
        #expect(AuthSession.signedIn(marcus).user?.id == "demo-user")
        #expect(AuthSession.signedIn(marcus).isSignedIn)
    }
}
