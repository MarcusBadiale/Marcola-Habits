import MCAuthAPI
import MCDomain
import MCMacros
import MCNavigationAPI
import MCSettingsAPI
import MCShared
import MCSyncAPI
import SwiftData
import SwiftUI

// `@MainActor` porque o provider lê `syncService`/`authService`, que são `@MainActor` (ver
// SyncServiceProtocol.swift). O `@Mockable` propaga a isolação pro `Mock` — tipo aninhado não
// herda global actor sozinho.
@MainActor
@Mockable
struct SettingsProvider: MCProvider {

    // @Query sem filtro: o `.Mock` troca @Query por `var`, então um predicate aqui seria lógica
    // que nenhum teste alcança. O recorte vive em `archivedCount`.
    @Query var allHabits: [HabitModel]

    @AppStorage(AppearanceStorageKeys.theme) var themeRawValue: String = AppTheme.system.rawValue

    @Environment(\.navigator) var navigator: NavigatorAPI
    @Environment(\.syncService) var syncService: any SyncServiceAPI
    @Environment(\.authService) var authService: any AuthServiceAPI

    // Zero @State e zero modelContext de propósito: o root de Settings não escreve nada, e todo
    // o estado de sync/auth mora nos serviços — que são @Observable, então o SwiftUI invalida
    // sozinho quando eles mudam.

    // MARK: - Arquivados

    var archivedCount: Int {
        allHabits.filter(\.isArchived).count
    }

    var archivedDetail: String {
        archivedCount == 0 ? "None" : "\(archivedCount)"
    }

    // MARK: - Aparência

    var theme: AppTheme {
        AppTheme(storedValue: themeRawValue)
    }

    var themeDetail: String { theme.label }

    // MARK: - Versão

    var appVersionDetail: String { AppVersion.display() }

    // MARK: - Sync

    var isSyncing: Bool { syncService.isSyncing }

    var syncDetail: String {
        if syncService.isSyncing { return "Syncing…" }
        if let error = syncService.lastSyncError { return error }
        guard let date = syncService.lastSyncDate else { return "Never synced" }
        return date.formatted(.relative(presentation: .named))
    }

    // MARK: - Conta

    var isSignedIn: Bool { authService.session.isSignedIn }
    var isAuthenticating: Bool { authService.isAuthenticating }

    var accountName: String {
        authService.session.user?.displayName ?? "Not signed in"
    }

    var accountDetail: String {
        if let error = authService.lastAuthError { return error }
        return authService.session.user?.email ?? "Sync your habits across devices"
    }

    var accountActionTitle: String {
        isSignedIn ? "Sign out" : "Sign in with Apple"
    }

    // MARK: - Ações

    func syncNow() {
        syncService.sync()
    }

    func toggleAccount() {
        if isSignedIn {
            authService.signOut()
        } else {
            authService.signIn()
        }
    }

    func goToAppearance() { navigator.push(SettingsRoutes.appearance) }
    func goToExport() { navigator.push(SettingsRoutes.exportData) }
    func goToArchived() { navigator.push(SettingsRoutes.archivedHabits) }
}
