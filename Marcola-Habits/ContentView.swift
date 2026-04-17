import MCCategories
import MCHome
import MCNavigation
import MCSettings
import MCStats
import SwiftUI

struct ContentView: View {
    @Bindable var navigator: Navigator

    var body: some View {
        TabView(selection: $navigator.activeTab) {
            Tab("Hoje", systemImage: "sun.max.fill", value: Navigator.Tab.today) {
                NavigationStack(path: $navigator.todayPath) {
                    HomeView()
                        .navigationDestination(for: Navigator.RouteEntry.self) { entry in
                            navigator.view(for: entry)
                        }
                }
            }

            Tab("Categorias", systemImage: "square.grid.2x2.fill", value: Navigator.Tab.categories) {
                NavigationStack(path: $navigator.categoriesPath) {
                    CategoriesView()
                        .navigationDestination(for: Navigator.RouteEntry.self) { entry in
                            navigator.view(for: entry)
                        }
                }
            }

            Tab("Stats", systemImage: "chart.bar.fill", value: Navigator.Tab.stats) {
                NavigationStack(path: $navigator.statsPath) {
                    StatsView()
                        .navigationDestination(for: Navigator.RouteEntry.self) { entry in
                            navigator.view(for: entry)
                        }
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: Navigator.Tab.settings) {
                NavigationStack(path: $navigator.settingsPath) {
                    SettingsView()
                        .navigationDestination(for: Navigator.RouteEntry.self) { entry in
                            navigator.view(for: entry)
                        }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .sheet(item: $navigator.presentedRoute) { entry in
            navigator.view(for: entry)
        }
    }
}
