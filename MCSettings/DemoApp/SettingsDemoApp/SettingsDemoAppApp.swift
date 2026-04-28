import DemoShared
import MCSettings
import MCSettingsAPI
import MCNavigationAPI
import MCShared
import MCSyncAPI
import SwiftData
import SwiftUI

@main
struct SettingsDemoApp: App {
    @State private var navigator = FakeNavigator()

    init() {
        DemoDependencies.registerAll()
        DependencyContainer.shared.register(SyncServiceAPI.self) {
            FakeSyncService()
        }
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .settings) { nav in
                SettingsRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(DemoSeedData.makeContainer())
    }
}
