import MCCategoriesAPI
import MCNavigationAPI
import SwiftUI

public struct CategoriesRouteRegistrar {
    public static func register(in registry: RouteRegistryAPI) {
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
