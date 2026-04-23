import SwiftUI

public protocol NavigatorAPI: AnyObject {
    func push(_ route: String, params: RouteParams)
    func pop()
    func popToRoot()
    func present(_ route: String, params: RouteParams)
    func dismiss()
}

extension NavigatorAPI {
    public func push(_ route: String) { push(route, params: [:]) }
    public func present(_ route: String) { present(route, params: [:]) }
}

private final class NoOpNavigator: NavigatorAPI {
    func push(_ route: String, params: RouteParams) {}
    func pop() {}
    func popToRoot() {}
    func present(_ route: String, params: RouteParams) {}
    func dismiss() {}
}

struct NavigatorAPIKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: any NavigatorAPI = NoOpNavigator()
}

extension EnvironmentValues {
    public var navigator: any NavigatorAPI {
        get { self[NavigatorAPIKey.self] }
        set { self[NavigatorAPIKey.self] = newValue }
    }
}
