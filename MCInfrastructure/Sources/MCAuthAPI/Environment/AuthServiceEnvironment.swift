import SwiftUI

struct AuthServiceKey: EnvironmentKey {
    // `nonisolated(unsafe)` porque `EnvironmentKey.defaultValue` é um requisito nonisolated e o
    // `AuthServiceAPI` é `@MainActor`. Seguro: o default é um no-op sem estado mutável, e o
    // Environment do SwiftUI só é lido na main actor.
    nonisolated(unsafe) static let defaultValue: any AuthServiceAPI = NoOpAuthService()
}

public extension EnvironmentValues {
    var authService: any AuthServiceAPI {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

/// Default privado do próprio módulo API, pra não inverter a dependência API → Impl.
/// A Fase 7 injeta o cliente real via `.environment(\.authService, ...)`.
@Observable
private final class NoOpAuthService: AuthServiceAPI {
    var session: AuthSession { .signedOut }
    var isAuthenticating: Bool { false }
    var lastAuthError: String? { nil }
    func signIn() {}
    func signOut() {}
}
