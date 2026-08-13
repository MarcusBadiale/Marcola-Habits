import MCCategories
import MCDesignSystem
import MCHome
import MCNavigation
import MCSettings
import MCSettingsAPI
import MCStats
import MCSync
import MCSyncAPI
import SwiftUI

struct ContentView: View {
    @State private var navigator = Navigator()

    // Um por App: os serviços guardam estado (isSyncing, lastSyncDate, session) e são @Observable.
    // Reconstruí-los a cada avaliação de body descartaria esse estado.
    @State private var syncService = NoOpSyncEngine()

    @AppStorage(AppearanceStorageKeys.theme) private var themeRawValue = AppTheme.system.rawValue
    @AppStorage(AppearanceStorageKeys.accentHex) private var accentHex = AppearanceDefaults.accentHex

    private var theme: AppTheme { AppTheme(storedValue: themeRawValue) }

    var body: some View {
        TabView(selection: $navigator.activeTab) {
            ForEach($navigator.tabs) { $tab in
                Tab(tab.title, systemImage: tab.icon, value: tab.id) {
                    NavigationStack(path: $tab.path) {
                        tab.rootView
                            .navigationDestination(for: Navigator.RouteEntry.self) { entry in
                                navigator.view(for: entry)
                            }
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .sheet(item: $navigator.presentedRoute) { entry in
            navigator.view(for: entry)
        }
        .environment(\.navigator, navigator)
        .environment(\.syncService, syncService)
        // `.tint` e `.preferredColorScheme` como modificadores mais externos, DEPOIS do `.sheet`:
        // aplicados antes, as views apresentadas em sheet (é assim que HomeRoutes.addHabit abre)
        // ficariam com o tema e o accent do sistema em vez dos escolhidos.
        .tint(Color(hex: accentHex))
        .preferredColorScheme(theme.colorScheme)
        .onAppear {
            HomeRouteRegistry.register(in: navigator)
            CategoriesRouteRegistry.register(in: navigator)
            StatsRouteRegistry.register(in: navigator)
            SettingsRouteRegistry.register(in: navigator)
        }
    }
}
