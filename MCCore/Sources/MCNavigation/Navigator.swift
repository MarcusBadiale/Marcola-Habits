import MCNavigationAPI
import SwiftUI

@Observable
public final class Navigator: RouteRegistryAPI {

    private var factories: [String: RouteViewFactory] = [:]

    public var todayPath: [RouteEntry] = []
    public var categoriesPath: [RouteEntry] = []
    public var statsPath: [RouteEntry] = []
    public var settingsPath: [RouteEntry] = []

    public var activeTab: Tab = .today
    public var presentedRoute: RouteEntry? = nil

    public enum Tab: String, CaseIterable, Hashable, Sendable {
        case today, categories, stats, settings
    }

    public struct RouteEntry: Identifiable, Hashable {
        public let id = UUID()
        public let route: String
        public let params: RouteParams

        public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
        public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    public init() {}

    private var activePath: [RouteEntry] {
        get {
            switch activeTab {
            case .today: todayPath
            case .categories: categoriesPath
            case .stats: statsPath
            case .settings: settingsPath
            }
        }
        set {
            switch activeTab {
            case .today: todayPath = newValue
            case .categories: categoriesPath = newValue
            case .stats: statsPath = newValue
            case .settings: settingsPath = newValue
            }
        }
    }

    // MARK: - RouteRegistryAPI

    public func register(_ route: String, factory: @escaping RouteViewFactory) {
        factories[route] = factory
    }

    // MARK: - Navigation

    public func push(_ route: String, params: RouteParams = [:]) {
        activePath.append(RouteEntry(route: route, params: params))
    }

    public func pop() {
        guard !activePath.isEmpty else { return }
        activePath.removeLast()
    }

    public func popToRoot() {
        activePath = []
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
