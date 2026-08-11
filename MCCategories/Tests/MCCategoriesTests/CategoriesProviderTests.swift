import Foundation
import Testing
import MCDomain
import MCCategoriesAPI
import SwiftData
@testable import MCCategories

@Suite("CategoriesProvider")
struct CategoriesProviderTests {

    // MARK: - Habit count (requires iOS Simulator for SwiftData relationships)

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func habitCountReturnsNonArchivedHabits() throws {
        let context = try TestHelpers.makeContext()
        let category = CategoryModel(name: "Health", icon: "heart", colorHex: "#F00", sortOrder: 0)
        context.insert(category)
        let active = HabitModel(
            name: "Run", icon: "figure.run", colorHex: "#F00",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .morning, category: category
        )
        let archived = HabitModel(
            name: "Old", icon: "xmark", colorHex: "#999",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .anytime, category: category
        )
        archived.isArchived = true
        context.insert(active)
        context.insert(archived)

        var sut = CategoriesProvider.Mock(
            categories: [category],
            modelContext: context, navigator: SpyNavigator()
        )
        #expect(sut.habitCount(for: category) == 1)
    }

    // MARK: - Navigation

    @Test @MainActor
    func goToDetailPushesCorrectRoute() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        let category = CategoryModel(name: "Health", icon: "heart", colorHex: "#F00", sortOrder: 0)
        var sut = CategoriesProvider.Mock(
            categories: [category],
            modelContext: context, navigator: spy
        )
        sut.goToDetail(category)
        #expect(spy.pushCalls.count == 1)
        #expect(spy.pushCalls.first?.route == CategoriesRoutes.categoryDetail)
        #expect(spy.pushCalls.first?.params["id"] as? UUID == category.id)
    }

    @Test @MainActor
    func showAddCategoryPresentsCorrectRoute() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        var sut = CategoriesProvider.Mock(
            categories: [],
            modelContext: context, navigator: spy
        )
        sut.showAddCategory()
        #expect(spy.presentCalls.count == 1)
        #expect(spy.presentCalls.first?.route == CategoriesRoutes.editCategory)
    }

    // MARK: - Delete (requires iOS Simulator for SwiftData delete)

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func deleteCategoryRemovesFromContext() throws {
        let context = try TestHelpers.makeContext()
        let category = CategoryModel(name: "Health", icon: "heart", colorHex: "#F00", sortOrder: 0)
        context.insert(category)
        try context.save()

        var sut = CategoriesProvider.Mock(
            categories: [category],
            modelContext: context, navigator: SpyNavigator()
        )
        sut.deleteCategory(category)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<CategoryModel>())
        #expect(remaining.isEmpty)
    }
}
