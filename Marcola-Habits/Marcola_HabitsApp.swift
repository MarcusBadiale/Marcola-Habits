import MCDomain
import MCPersistence
import SwiftUI
import SwiftData

@main
struct Marcola_HabitsApp: App {
    init() {
        AppDependencies.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    }
}
