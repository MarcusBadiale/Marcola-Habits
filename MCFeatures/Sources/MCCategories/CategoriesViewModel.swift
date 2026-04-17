import MarcolasPattern
import MCCategoriesAPI
import MCDomain
import MCNavigation
import MCShared
import SwiftData
import SwiftUI

@MCViewModel
struct CategoriesViewModel {
    @Query(sort: \CategoryModel.sortOrder) var categories: [CategoryModel]

    @Environment(\.modelContext) var modelContext
    @Environment(Navigator.self) var navigator

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
