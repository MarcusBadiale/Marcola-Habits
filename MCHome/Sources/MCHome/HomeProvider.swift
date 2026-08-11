import MCDomain
import MCHomeAPI
import MCMacros
import MCNavigationAPI
import MCShared
import SwiftData
import SwiftUI

@Mockable
struct HomeProvider: MCProvider {
    @Query(filter: #Predicate<HabitModel> { !$0.isArchived }, sort: \HabitModel.name)
    var habits: [HabitModel]

    @Query(sort: \CategoryModel.sortOrder)
    var categories: [CategoryModel]

    @Query
    var allLogs: [HabitLogModel]

    @State var selectedDate: Date = Date.now.startOfDay
    @State var selectedCategoryID: UUID? = nil

    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.navigator) var navigator: NavigatorAPI
    @Environment(\.statsCalculator) var stats: StatsCalculatorAPI

    var filteredHabits: [HabitModel] {
        let scheduled = habits.filter { $0.isScheduled(for: selectedDate) }
        guard let catID = selectedCategoryID else { return scheduled }
        return scheduled.filter { $0.category?.id == catID }
    }

    func logFor(_ habit: HabitModel) -> HabitLogModel? {
        let day = selectedDate.startOfDay
        return allLogs.first { $0.habit?.id == habit.id && $0.date.isInSameDay(day) }
    }

    func isCompleted(_ habit: HabitModel) -> Bool {
        guard let log = logFor(habit) else { return false }
        return habit.targetCount > 1 ? log.count >= habit.targetCount : log.completed
    }

    func progress(_ habit: HabitModel) -> Double {
        guard habit.targetCount > 1, let log = logFor(habit) else { return 0 }
        return min(Double(log.count) / Double(habit.targetCount), 1.0)
    }

    func streak(_ habit: HabitModel) -> Int {
        stats.currentStreak(
            habitID: habit.id,
            logs: allLogs.filter { $0.habit?.id == habit.id }.map { $0.toDTO() }
        )
    }

    func toggleCompletion(_ habit: HabitModel) {
        let day = selectedDate.startOfDay
        if let log = logFor(habit) {
            if habit.targetCount > 1 {
                log.count = log.count >= habit.targetCount ? 0 : habit.targetCount
                log.completed = log.count >= habit.targetCount
            } else {
                log.completed.toggle()
            }
            log.updatedAt = Date.now
        } else {
            let log = HabitLogModel(
                date: day,
                completed: habit.targetCount <= 1,
                count: habit.targetCount <= 1 ? 0 : habit.targetCount,
                habit: habit
            )
            modelContext.insert(log)
        }
    }

    func goToDetail(_ habit: HabitModel) {
        navigator.push(HomeRoutes.habitDetail, params: ["id": habit.id])
    }

    func showAddHabit() {
        navigator.present(HomeRoutes.addHabit)
    }
}
