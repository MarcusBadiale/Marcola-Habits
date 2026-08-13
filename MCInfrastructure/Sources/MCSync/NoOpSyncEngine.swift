import Foundation
import MCSyncAPI

/// Stub de sync até a Fase 7. Não fala com rede nenhuma — só exercita o ciclo de estado
/// (`isSyncing` liga/desliga, `lastSyncDate` é gravado), pra que a UI construída em cima do
/// `SyncServiceAPI` tenha um comportamento real pra mostrar antes do Supabase existir.
@MainActor
@Observable
public final class NoOpSyncEngine: SyncServiceAPI {

    public private(set) var isSyncing = false
    public private(set) var lastSyncDate: Date?
    public private(set) var lastSyncError: String?

    private var task: Task<Void, Never>?

    public init() {}

    /// A dedução de chamada dupla mora aqui, não no provider: quem sabe que já tem um sync em voo
    /// é o serviço.
    public func sync() {
        guard task == nil else { return }

        isSyncing = true
        lastSyncError = nil

        task = Task { [weak self] in
            defer {
                self?.isSyncing = false
                self?.task = nil
            }
            await self?.performSync()
        }
    }

    /// Fase 7 substitui isto pelo push/pull real.
    private func performSync() async {
        lastSyncDate = .now
    }
}
