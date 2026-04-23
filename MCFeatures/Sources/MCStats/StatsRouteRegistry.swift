import MCNavigationAPI
import SwiftUI

public struct StatsRouteRegistry {
    public static func register(in registry: RouteRegistryAPI) {
        registry.registerRoot(for: .stats) {
            AnyView(StatsView())
        }
    }
}
