import DemoShared
import MCHome
import MCHomeAPI
import MCNavigationAPI
import SwiftData
import SwiftUI

@main
struct HomeDemoApp: App {
    @State private var navigator = FakeNavigator()

    init() {
        DemoDependencies.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .today) { nav in
                HomeRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(DemoSeedData.makeContainer())
    }
}
