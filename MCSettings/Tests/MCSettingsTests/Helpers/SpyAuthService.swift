import Foundation
import MCAuthAPI

@MainActor
@Observable
final class SpyAuthService: AuthServiceAPI {

    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0

    var session: AuthSession = .signedOut
    var isAuthenticating: Bool = false
    var lastAuthError: String? = nil

    func signIn() { signInCallCount += 1 }
    func signOut() { signOutCallCount += 1 }
}
