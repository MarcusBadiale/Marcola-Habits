import Foundation

/// Contrato de sincronização visto pelas features.
///
/// É `@MainActor` + `Observable` de propósito: o `isSyncing`/`lastSyncDate` são lidos direto do
/// `body` de uma View, e um protocolo só-`Sendable` não criaria dependência de invalidação — a UI
/// mostraria um estado congelado. `AnyObject` + `Observable` é o que permite o SwiftUI rastrear.
///
/// `sync()` é **síncrono de propósito**: quem é dono do `Task` é a implementação, não a View nem o
/// provider. Isso mantém `Task { }` fora do código de feature e evita que a dedução de chamada
/// dupla se espalhe por cada tela que dispare um sync.
///
/// Na Fase 7 a maquinaria interna (fila, cliente de rede, resolução de conflito) pode ser um
/// `actor` atrás desta fachada — a fachada é o contrato de UI, o actor é o motor.
@MainActor
public protocol SyncServiceAPI: AnyObject, Observable {

    /// `true` enquanto um `sync()` está em voo.
    var isSyncing: Bool { get }

    /// Momento do último sync concluído com sucesso. `nil` = nunca sincronizou.
    var lastSyncDate: Date? { get }

    /// Mensagem do último erro de sync, ou `nil` se o último sync deu certo.
    var lastSyncError: String? { get }

    /// Dispara um sync. Chamadas concorrentes são ignoradas enquanto `isSyncing` for `true`.
    func sync()
}
