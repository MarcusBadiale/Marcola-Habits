import MCCategories
import MCHome
import MCNavigation
import MCSettings
import MCStats
import SwiftUI

struct ContentView: View {
    @State private var navigator = Navigator()

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
        .onAppear {
            HomeRouteRegistry.register(in: navigator)
            CategoriesRouteRegistry.register(in: navigator)
            StatsRouteRegistry.register(in: navigator)
            SettingsRouteRegistry.register(in: navigator)
        }
    }
}
