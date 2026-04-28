import MCNavigationAPI

final class SpyNavigator: NavigatorAPI {
    var pushCalls: [(route: String, params: RouteParams)] = []
    var presentCalls: [(route: String, params: RouteParams)] = []
    var popCount = 0
    var dismissCount = 0

    func push(_ route: String, params: RouteParams) {
        pushCalls.append((route, params))
    }

    func pop() { popCount += 1 }
    func popToRoot() {}

    func present(_ route: String, params: RouteParams) {
        presentCalls.append((route, params))
    }

    func dismiss() { dismissCount += 1 }
}
