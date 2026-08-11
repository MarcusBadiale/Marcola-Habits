import Foundation
import MCNavigationAPI
import MCStatsAPI
import SwiftUI

public struct StatsRouteRegistry {
    public static func register(in registry: RouteRegistryAPI) {
        registry.registerRoot(for: .stats) {
            AnyView(StatsView())
        }

        registry.register(StatsRoutes.habitStats) { params in
            let id = params["id"] as! UUID
            return AnyView(HabitStatsView(habitID: id))
        }
    }
}
