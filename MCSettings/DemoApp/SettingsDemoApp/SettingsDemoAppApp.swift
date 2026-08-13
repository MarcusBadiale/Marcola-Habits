import DemoShared
import MCAuthAPI
import MCSettings
import MCSettingsAPI
import MCNavigationAPI
import MCSyncAPI
import SwiftData
import SwiftUI

@main
struct SettingsDemoApp: App {
    // Um por App e não um por avaliação de body: os serviços guardam estado (isSyncing, session)
    // e o SwiftUI observa. Reconstruí-los descartaria o estado a cada invalidação.
    @State private var navigator = FakeNavigator()
    @State private var syncService = FakeSyncService()
    @State private var authService = FakeAuthService()

    init() {
        // O Demo App tem bundle ID próprio, então o UserDefaults dele persiste entre execuções no
        // simulador e um teste que muda o tema contamina o próximo run.
        //
        // Apagar a chave em vez de passar o valor por launch argument: o NSArgumentDomain tem
        // precedência **maior** que o domínio do app, então `-mcSettingsTheme system` não
        // "reseta" — ele trava o valor, e nenhuma escrita da tela voltaria a ser lida.
        if ProcessInfo.processInfo.arguments.contains("--reset-appearance") {
            UserDefaults.standard.removeObject(forKey: AppearanceStorageKeys.theme)
            UserDefaults.standard.removeObject(forKey: AppearanceStorageKeys.accentHex)
        }
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .settings) { nav in
                SettingsRouteRegistry.register(in: nav)
            }
            // O DemoRootView só injeta `\.navigator` — o resto é por conta de cada Demo App.
            .environment(\.syncService, syncService)
            .environment(\.authService, authService)
        }
        .modelContainer(DemoSeedData.makeContainer())
    }
}
