import Foundation
import Testing
import MCDomain
import SwiftData
@testable import MCCategories

@Suite("EditCategoryProvider")
struct EditCategoryProviderTests {

    // MARK: - Validation

    @Test @MainActor
    func canSaveIsFalseWhenNameEmpty() throws {
        let context = try TestHelpers.makeContext()
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: nil, allCategories: [],
            modelContext: context, navigator: SpyNavigator()
        )
        #expect(sut.canSave == false)
    }

    @Test @MainActor
    func canSaveIsTrueWhenNameHasContent() throws {
        let context = try TestHelpers.makeContext()
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: nil, allCategories: [],
            modelContext: context, navigator: SpyNavigator()
        )
        sut.name = "Fitness"
        #expect(sut.canSave == true)
    }

    // MARK: - Editing mode

    @Test @MainActor
    func isEditingReturnsFalseWhenNoID() throws {
        let context = try TestHelpers.makeContext()
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: nil, allCategories: [],
            modelContext: context, navigator: SpyNavigator()
        )
        #expect(sut.isEditing == false)
    }

    @Test @MainActor
    func isEditingReturnsTrueWhenIDPresent() throws {
        let context = try TestHelpers.makeContext()
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: UUID(), allCategories: [],
            modelContext: context, navigator: SpyNavigator()
        )
        #expect(sut.isEditing == true)
    }

    // MARK: - Load existing

    @Test @MainActor
    func loadExistingPopulatesFieldsFromCategory() throws {
        let context = try TestHelpers.makeContext()
        let category = CategoryModel(name: "Health", icon: "heart.fill", colorHex: "#EF4444", sortOrder: 0)
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: category.id, allCategories: [category],
            modelContext: context, navigator: SpyNavigator()
        )
        sut.loadExisting()
        #expect(sut.name == "Health")
        #expect(sut.icon == "heart.fill")
        #expect(sut.colorHex == "#EF4444")
        #expect(sut.didLoadExisting == true)
    }

    @Test @MainActor
    func loadExistingDoesNothingOnSecondCall() throws {
        let context = try TestHelpers.makeContext()
        let category = CategoryModel(name: "Health", icon: "heart.fill", colorHex: "#EF4444", sortOrder: 0)
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: category.id, allCategories: [category],
            modelContext: context, navigator: SpyNavigator()
        )
        sut.loadExisting()
        sut.name = "Changed"
        sut.loadExisting()
        #expect(sut.name == "Changed")
    }

    // MARK: - Save new (requires iOS Simulator for SwiftData insert)

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func saveCreatesNewCategoryAndDismisses() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: nil, allCategories: [],
            modelContext: context, navigator: spy,
            name: "New Category", icon: "star.fill", colorHex: "#3B82F6"
        )
        sut.save()
        let categories = try context.fetch(FetchDescriptor<CategoryModel>())
        #expect(categories.count == 1)
        #expect(categories.first?.name == "New Category")
        #expect(categories.first?.sortOrder == 0)
        #expect(spy.dismissCount == 1)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func saveSetsCorrectSortOrder() throws {
        let context = try TestHelpers.makeContext()
        let existing = CategoryModel(name: "First", icon: "1.circle", colorHex: "#000", sortOrder: 2)
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: nil, allCategories: [existing],
            modelContext: context, navigator: SpyNavigator(),
            name: "Second"
        )
        sut.save()
        let categories = try context.fetch(FetchDescriptor<CategoryModel>())
        let newCat = categories.first { $0.name == "Second" }
        #expect(newCat?.sortOrder == 3)
    }

    // MARK: - Save existing (requires iOS Simulator for SwiftData update)

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func saveUpdatesExistingCategory() throws {
        let context = try TestHelpers.makeContext()
        let category = CategoryModel(name: "Old", icon: "folder", colorHex: "#000", sortOrder: 0)
        context.insert(category)
        let spy = SpyNavigator()
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: category.id, allCategories: [category],
            modelContext: context, navigator: spy,
            name: "Updated", icon: "star.fill", colorHex: "#F00"
        )
        sut.save()
        #expect(category.name == "Updated")
        #expect(category.icon == "star.fill")
        #expect(category.colorHex == "#F00")
        #expect(spy.dismissCount == 1)
    }

    // MARK: - Cancel

    @Test @MainActor
    func cancelDismisses() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        var sut = EditCategoryProvider.Mock(
            editingCategoryID: nil, allCategories: [],
            modelContext: context, navigator: spy
        )
        sut.cancel()
        #expect(spy.dismissCount == 1)
    }
}
