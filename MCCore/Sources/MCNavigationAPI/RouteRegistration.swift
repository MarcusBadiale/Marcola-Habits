import SwiftUI

public typealias RouteViewFactory = @MainActor @Sendable (RouteParams) -> AnyView

public protocol RouteRegistryAPI {
    func register(_ route: String, factory: @escaping RouteViewFactory)
}
