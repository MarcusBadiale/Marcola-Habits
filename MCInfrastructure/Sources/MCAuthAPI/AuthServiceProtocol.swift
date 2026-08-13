import Foundation

/// Usuário autenticado. `id` é `String` e não `UUID` de propósito: o Supabase devolve `sub` como
/// string e o Sign in with Apple devolve um identificador opaco.
public struct AuthUser: Hashable, Sendable, Identifiable {

    public let id: String
    public let displayName: String?
    public let email: String?

    public init(id: String, displayName: String? = nil, email: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
    }
}

/// Estado de sessão como enum, e não `Bool` + `String?` soltos — evita o estado impossível
/// "logado sem usuário".
public enum AuthSession: Hashable, Sendable {

    case signedOut
    case signedIn(AuthUser)

    public var user: AuthUser? {
        if case .signedIn(let user) = self { user } else { nil }
    }

    public var isSignedIn: Bool { user != nil }
}

/// Contrato de autenticação visto pelas features.
///
/// Mesmo desenho do `SyncServiceAPI` e pelo mesmo motivo: `@MainActor` + `Observable` pra que a
/// View possa ler `session`/`isAuthenticating` direto do `body`, e `signIn()`/`signOut()`
/// síncronos porque quem é dono do `Task` é a implementação.
@MainActor
public protocol AuthServiceAPI: AnyObject, Observable {

    var session: AuthSession { get }

    /// `true` enquanto um `signIn()`/`signOut()` está em voo.
    var isAuthenticating: Bool { get }

    /// Mensagem do último erro de autenticação, ou `nil` se a última tentativa deu certo.
    var lastAuthError: String? { get }

    func signIn()
    func signOut()
}
