import MCNavigationAPI
import SwiftUI

public struct DemoRootView: View {
    @Bindable var navigator: FakeNavigator
    let tab: TabID
    let registerRoutes: (FakeNavigator) -> Void

    @State private var isReady = false

    public init(
        navigator: FakeNavigator,
        tab: TabID,
        registerRoutes: @escaping (FakeNavigator) -> Void
    ) {
        self.navigator = navigator
        self.tab = tab
        self.registerRoutes = registerRoutes
    }

    public var body: some View {
        Group {
            if isReady {
                NavigationStack(path: $navigator.path) {
                    navigator.rootView(for: tab)
                        .navigationDestination(for: FakeNavigator.RouteEntry.self) { entry in
                            navigator.view(for: entry)
                        }
                }
                .sheet(item: $navigator.presentedEntry) { entry in
                    navigator.view(for: entry)
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .environment(\.navigator, navigator)
        .task {
            registerRoutes(navigator)
            isReady = true
        }
    }
}
