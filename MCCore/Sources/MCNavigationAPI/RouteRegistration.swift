import SwiftUI

public typealias RouteViewFactory = @MainActor @Sendable (RouteParams) -> AnyView

public protocol RouteRegistryAPI {
    func register(_ route: String, factory: @escaping RouteViewFactory)
    func registerRoot(for tab: TabID, factory: @escaping @MainActor @Sendable () -> AnyView)
}
