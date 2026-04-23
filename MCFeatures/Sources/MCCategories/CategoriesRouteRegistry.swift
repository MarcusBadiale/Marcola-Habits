import MCCategoriesAPI
import MCNavigationAPI
import SwiftUI

public struct CategoriesRouteRegistry {
    public static func register(in registry: RouteRegistryAPI) {
        registry.registerRoot(for: .categories) {
            AnyView(CategoriesView())
        }

        registry.register(CategoriesRoutes.categoryDetail) { params in
            let id = params["id"] as! UUID
            return AnyView(CategoryDetailView(categoryID: id))
        }

        registry.register(CategoriesRoutes.editCategory) { params in
            let id = params["id"] as? UUID
            return AnyView(EditCategorySheet(editingCategoryID: id))
        }
    }
}
