import Foundation
import MCAuthAPI

/// Auth fake pros Demo Apps. Mesma latência artificial do `FakeSyncService`, pelo mesmo motivo:
/// dar uma janela observável pro spinner e pro UI test.
@MainActor
@Observable
public final class FakeAuthService: AuthServiceAPI {

    public private(set) var session: AuthSession
    public private(set) var isAuthenticating = false
    public private(set) var lastAuthError: String?

    private let duration: Duration
    private var task: Task<Void, Never>?

    public init(session: AuthSession = .signedOut, duration: Duration = .milliseconds(600)) {
        self.session = session
        self.duration = duration
    }

    public func signIn() {
        transition(to: .signedIn(AuthUser(id: "demo-user", displayName: "Marcus", email: "marcus@marcola.app")))
    }

    public func signOut() {
        transition(to: .signedOut)
    }

    private func transition(to newSession: AuthSession) {
        guard task == nil else { return }

        isAuthenticating = true
        lastAuthError = nil

        task = Task { [weak self, duration] in
            defer {
                self?.isAuthenticating = false
                self?.task = nil
            }
            try? await Task.sleep(for: duration)
            self?.session = newSession
        }
    }
}
