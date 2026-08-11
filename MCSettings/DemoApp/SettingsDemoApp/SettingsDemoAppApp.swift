import DemoShared
import MCSettings
import MCSettingsAPI
import MCNavigationAPI
import MCSyncAPI
import SwiftData
import SwiftUI

@main
struct SettingsDemoApp: App {
    @State private var navigator = FakeNavigator()

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .settings) { nav in
                SettingsRouteRegistry.register(in: nav)
            }
            .environment(\.syncService, FakeSyncService())
        }
        .modelContainer(DemoSeedData.makeContainer())
    }
}
