import Foundation
import Testing
import MCCategoriesAPI
import MCDomain
import MCHomeAPI
import SwiftData
@testable import MCCategories

@Suite("CategoryDetailProvider")
struct CategoryDetailProviderTests {

    // MARK: - Category lookup

    @Test("category acha o modelo pelo categoryID")
    @MainActor
    func categoryFindsByID() throws {
        let category = TestHelpers.makeCategory()
        let other = TestHelpers.makeCategory(name: "Learning", sortOrder: 1)
        let sut = try makeSUT(categoryID: category.id, allCategories: [other, category])
        #expect(sut.category?.id == category.id)
    }

    @Test("category retorna nil quando o ID não está na lista")
    @MainActor
    func categoryReturnsNilWhenMissing() throws {
        let sut = try makeSUT(categoryID: UUID(), allCategories: [TestHelpers.makeCategory()])
        #expect(sut.category == nil)
    }

    // MARK: - Active habits

    @Test("activeHabits exclui arquivados e ordena por nome")
    @MainActor
    func activeHabitsExcludesArchivedAndSortsByName() throws {
        let category = TestHelpers.makeCategory()
        let archived = TestHelpers.makeHabit(name: "Old")
        archived.isArchived = true
        // Relação montada na mão em vez de via `context.insert`: mantém o teste sem o
        // gate de simulador, então ele roda também no `swift test` do host.
        category.habits = [
            TestHelpers.makeHabit(name: "Zebra"),
            TestHelpers.makeHabit(name: "Alpha"),
            archived,
        ]

        let sut = try makeSUT(categoryID: category.id, allCategories: [category])

        #expect(sut.activeHabits.map(\.name) == ["Alpha", "Zebra"])
    }

    @Test("activeHabits é vazio quando a categoria não existe")
    @MainActor
    func activeHabitsEmptyWhenCategoryMissing() throws {
        let sut = try makeSUT(categoryID: UUID(), allCategories: [])
        #expect(sut.activeHabits.isEmpty)
    }

    // MARK: - Completion

    @Test("isCompleted é false sem log")
    @MainActor
    func isCompletedFalseWithoutLog() throws {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(category: category)
        var sut = try makeSUT(categoryID: category.id, allCategories: [category])
        #expect(sut.isCompleted(habit) == false)
    }

    @Test("isCompleted é true com log completo de hoje")
    @MainActor
    func isCompletedTrueWithTodayLog() throws {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(category: category)
        var sut = try makeSUT(
            categoryID: category.id, allCategories: [category],
            allLogs: [TestHelpers.makeLog(habit: habit, completed: true)]
        )
        #expect(sut.isCompleted(habit) == true)
    }

    @Test("isCompleted é false em multi-count com contagem parcial")
    @MainActor
    func isCompletedFalseWithPartialCount() throws {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(name: "Water", targetCount: 8, targetUnit: "cups", category: category)
        var sut = try makeSUT(
            categoryID: category.id, allCategories: [category],
            allLogs: [TestHelpers.makeLog(habit: habit, completed: false, count: 3)]
        )
        #expect(sut.isCompleted(habit) == false)
    }

    @Test("isCompleted é true em multi-count quando bate o targetCount")
    @MainActor
    func isCompletedTrueWhenCountReachesTarget() throws {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(name: "Water", targetCount: 8, targetUnit: "cups", category: category)
        var sut = try makeSUT(
            categoryID: category.id, allCategories: [category],
            allLogs: [TestHelpers.makeLog(habit: habit, completed: false, count: 8)]
        )
        #expect(sut.isCompleted(habit) == true)
    }

    @Test("isCompleted ignora log de ontem")
    @MainActor
    func isCompletedIgnoresYesterdayLog() throws {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(category: category)
        var sut = try makeSUT(
            categoryID: category.id, allCategories: [category],
            allLogs: [TestHelpers.makeLog(habit: habit, daysAgo: 1, completed: true)]
        )
        #expect(sut.isCompleted(habit) == false)
    }

    // MARK: - Navigation

    @Test("goToHabitDetail empurra a rota do MCHome com o id do hábito")
    @MainActor
    func goToHabitDetailPushesHomeRoute() throws {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(category: category)
        let spy = SpyNavigator()
        var sut = try makeSUT(categoryID: category.id, allCategories: [category], navigator: spy)

        sut.goToHabitDetail(habit)

        #expect(spy.pushCalls.count == 1)
        #expect(spy.pushCalls.first?.route == HomeRoutes.habitDetail)
        #expect(spy.pushCalls.first?.params["id"] as? UUID == habit.id)
    }

    @Test("showEditCategory apresenta a rota de edição com o categoryID")
    @MainActor
    func showEditCategoryPresentsEditRoute() throws {
        let category = TestHelpers.makeCategory()
        let spy = SpyNavigator()
        var sut = try makeSUT(categoryID: category.id, allCategories: [category], navigator: spy)

        sut.showEditCategory()

        #expect(spy.presentCalls.count == 1)
        #expect(spy.presentCalls.first?.route == CategoriesRoutes.editCategory)
        #expect(spy.presentCalls.first?.params["id"] as? UUID == category.id)
    }

    // MARK: - SUT

    @MainActor
    private func makeSUT(
        categoryID: UUID,
        allCategories: [CategoryModel],
        allLogs: [HabitLogModel] = [],
        navigator: SpyNavigator = SpyNavigator()
    ) throws -> CategoryDetailProvider.Mock {
        CategoryDetailProvider.Mock(
            categoryID: categoryID,
            allCategories: allCategories,
            allLogs: allLogs,
            modelContext: try TestHelpers.makeContext(),
            navigator: navigator
        )
    }
}
