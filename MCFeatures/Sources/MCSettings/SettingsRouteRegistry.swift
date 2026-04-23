import MCNavigationAPI
import SwiftUI

public struct SettingsRouteRegistry {
    public static func register(in registry: RouteRegistryAPI) {
        registry.registerRoot(for: .settings) {
            AnyView(SettingsView())
        }
    }
}
