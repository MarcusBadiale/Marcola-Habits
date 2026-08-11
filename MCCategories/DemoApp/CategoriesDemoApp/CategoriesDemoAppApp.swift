import DemoShared
import MCCategories
import MCNavigationAPI
import SwiftData
import SwiftUI

@main
struct CategoriesDemoApp: App {
    @State private var navigator = FakeNavigator()

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .categories) { nav in
                CategoriesRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(DemoSeedData.makeContainer())
    }
}
