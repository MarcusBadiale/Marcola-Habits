import MCNavigationAPI
import SwiftUI

@Observable
public final class Navigator: RouteRegistryAPI, NavigatorAPI {

    private var factories: [String: RouteViewFactory] = [:]

    public var tabs: [TabState] = [
        TabState(id: .today, title: "Today", icon: "sun.max.fill"),
        TabState(id: .categories, title: "Categories", icon: "square.grid.2x2.fill"),
        TabState(id: .stats, title: "Stats", icon: "chart.bar.fill"),
        TabState(id: .settings, title: "Settings", icon: "gearshape.fill"),
    ]

    public var activeTab: TabID = .today
    public var presentedRoute: RouteEntry? = nil

    public struct TabState: Identifiable {
        public let id: TabID
        public let title: String
        public let icon: String
        public var path: [RouteEntry] = []
        private var rootViewFactory: (@MainActor @Sendable () -> AnyView)?

        public init(id: TabID, title: String, icon: String) {
            self.id = id
            self.title = title
            self.icon = icon
        }

        @ViewBuilder @MainActor
        public var rootView: some View {
            if let factory = rootViewFactory {
                factory()
            }
        }

        mutating func setRoot(_ factory: @escaping @MainActor @Sendable () -> AnyView) {
            rootViewFactory = factory
        }
    }

    public struct RouteEntry: Identifiable, Hashable {
        public let id = UUID()
        public let route: String
        public let params: RouteParams

        public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
        public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    public init() {}

    public subscript(_ id: TabID) -> TabState {
        get { tabs.first(where: { $0.id == id })! }
        set {
            guard let i = tabs.firstIndex(where: { $0.id == id }) else { return }
            tabs[i] = newValue
        }
    }

    // MARK: - RouteRegistryAPI

    public func register(_ route: String, factory: @escaping RouteViewFactory) {
        factories[route] = factory
    }

    public func registerRoot(for tab: TabID, factory: @escaping @MainActor @Sendable () -> AnyView) {
        self[tab].setRoot(factory)
    }

    // MARK: - Navigation

    public func push(_ route: String, params: RouteParams = [:]) {
        self[activeTab].path.append(RouteEntry(route: route, params: params))
    }

    public func pop() {
        guard !self[activeTab].path.isEmpty else { return }
        self[activeTab].path.removeLast()
    }

    public func popToRoot() {
        self[activeTab].path = []
    }

    public func present(_ route: String, params: RouteParams = [:]) {
        presentedRoute = RouteEntry(route: route, params: params)
    }

    public func dismiss() {
        presentedRoute = nil
    }

    // MARK: - View Resolution

    @MainActor @ViewBuilder
    public func view(for entry: RouteEntry) -> some View {
        if let factory = factories[entry.route] {
            factory(entry.params)
        } else {
            Text("Route not found: \(entry.route)")
        }
    }
}
