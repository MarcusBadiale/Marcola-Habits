import MarcolasPattern
import MCCategoriesAPI
import MCDomain
import MCHomeAPI
import MCNavigationAPI
import MCShared
import SwiftData
import SwiftUI

@MCProvider
struct CategoryDetailProvider {
    let categoryID: UUID

    @Query var allCategories: [CategoryModel]
    @Query var allLogs: [HabitLogModel]

    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.navigator) var navigator: NavigatorAPI

    var category: CategoryModel? {
        allCategories.first { $0.id == categoryID }
    }

    var activeHabits: [HabitModel] {
        guard let category else { return [] }
        return category.habits
            .filter { !$0.isArchived }
            .sorted { $0.name < $1.name }
    }

    func isCompleted(_ habit: HabitModel) -> Bool {
        let today = Date.now.startOfDay
        guard let log = allLogs.first(where: { $0.habit?.id == habit.id && $0.date.isInSameDay(today) }) else {
            return false
        }
        return habit.targetCount > 1 ? log.count >= habit.targetCount : log.completed
    }

    func goToHabitDetail(_ habit: HabitModel) {
        navigator.push(HomeRoutes.habitDetail, params: ["id": habit.id])
    }

    func showEditCategory() {
        navigator.present(CategoriesRoutes.editCategory, params: ["id": categoryID])
    }
}
