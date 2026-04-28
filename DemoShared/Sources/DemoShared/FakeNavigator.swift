import MCNavigationAPI
import SwiftUI

@Observable
public final class FakeNavigator: NavigatorAPI, RouteRegistryAPI {

    // MARK: - Route resolution

    private var factories: [String: @MainActor @Sendable (RouteParams) -> AnyView] = [:]
    private var rootFactories: [TabID: @MainActor @Sendable () -> AnyView] = [:]

    // MARK: - Navigation state

    public var path: [RouteEntry] = []
    public var presentedEntry: RouteEntry?

    public struct RouteEntry: Identifiable, Hashable {
        public let id = UUID()
        public let route: String
        public let params: RouteParams

        public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
        public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    public init() {}

    // MARK: - RouteRegistryAPI

    public func register(_ route: String, factory: @escaping RouteViewFactory) {
        factories[route] = factory
    }

    public func registerRoot(for tab: TabID, factory: @escaping @MainActor @Sendable () -> AnyView) {
        rootFactories[tab] = factory
    }

    // MARK: - NavigatorAPI

    public func push(_ route: String, params: RouteParams) {
        path.append(RouteEntry(route: route, params: params))
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path = []
    }

    public func present(_ route: String, params: RouteParams) {
        presentedEntry = RouteEntry(route: route, params: params)
    }

    public func dismiss() {
        presentedEntry = nil
    }

    // MARK: - View resolution

    @MainActor @ViewBuilder
    public func rootView(for tab: TabID) -> some View {
        if let factory = rootFactories[tab] {
            factory()
        } else {
            fakePlaceholder("Root not registered for tab: \(tab.rawValue)")
        }
    }

    @MainActor @ViewBuilder
    public func view(for entry: RouteEntry) -> some View {
        if let factory = factories[entry.route] {
            factory(entry.params)
        } else {
            fakePlaceholder("Route not registered: \(entry.route)\nParams: \(entry.params)")
        }
    }

    @MainActor
    private func fakePlaceholder(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Fake Route")
    }
}
