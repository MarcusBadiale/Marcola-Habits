import Foundation
import MCDomain
import MCPersistence
import SwiftData
import SwiftUI

@main
struct Marcola_HabitsApp: App {
    let container: ModelContainer

    init() {
        AppDependencies.registerAll()
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            container = try! ModelContainerFactory.makeSeeded()
        } else {
            container = try! ModelContainerFactory.makeProduction()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
