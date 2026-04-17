import MCCategories
import MCDomain
import MCHome
import MCNavigation
import MCPersistence
import MCSettings
import MCStats
import SwiftUI
import SwiftData

@main
struct Marcola_HabitsApp: App {
    @State private var navigator = Navigator()

    init() {
        AppDependencies.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(navigator: navigator)
                .environment(navigator)
                .onAppear {
                    HomeRouteRegistrar.register(in: navigator)
                    CategoriesRouteRegistrar.register(in: navigator)
                    StatsRouteRegistrar.register(in: navigator)
                    SettingsRouteRegistrar.register(in: navigator)
                }
        }
        .modelContainer(for: [CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    }
}
