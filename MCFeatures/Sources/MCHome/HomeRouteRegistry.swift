import MCHomeAPI
import MCNavigationAPI
import SwiftUI

public struct HomeRouteRegistry {
    public static func register(in registry: RouteRegistryAPI) {
        registry.registerRoot(for: .today) {
            AnyView(HomeView())
        }

        registry.register(HomeRoutes.habitDetail) { params in
            let id = params["id"] as! UUID
            return AnyView(HabitDetailView(habitID: id))
        }

        registry.register(HomeRoutes.addHabit) { _ in
            AnyView(AddHabitSheet())
        }
    }
}
