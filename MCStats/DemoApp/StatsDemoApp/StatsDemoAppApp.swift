import DemoShared
import MCStats
import MCStatsAPI
import MCNavigationAPI
import SwiftData
import SwiftUI

@main
struct StatsDemoApp: App {
    @State private var navigator = FakeNavigator()

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .stats) { nav in
                StatsRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(DemoSeedData.makeContainer())
    }
}
