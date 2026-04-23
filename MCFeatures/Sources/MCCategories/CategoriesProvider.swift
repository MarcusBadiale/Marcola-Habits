import MarcolasPattern
import MCCategoriesAPI
import MCDomain
import MCNavigationAPI
import MCShared
import SwiftData
import SwiftUI

@MCProvider
struct CategoriesProvider {
    @Query(sort: \CategoryModel.sortOrder) var categories: [CategoryModel]

    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.navigator) var navigator: NavigatorAPI

    func habitCount(for category: CategoryModel) -> Int {
        category.habits.filter { !$0.isArchived }.count
    }

    func goToDetail(_ category: CategoryModel) {
        navigator.push(CategoriesRoutes.categoryDetail, params: ["id": category.id])
    }

    func showAddCategory() {
        navigator.present(CategoriesRoutes.editCategory)
    }

    func deleteCategory(_ category: CategoryModel) {
        modelContext.delete(category)
    }
}
