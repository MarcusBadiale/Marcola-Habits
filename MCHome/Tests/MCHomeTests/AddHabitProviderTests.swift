import Foundation
import Testing
import MCDomain
import MCHomeAPI
import SwiftData
@testable import MCHome

@Suite("AddHabitProvider")
struct AddHabitProviderTests {

    // MARK: - Validation

    @Test @MainActor
    func canSaveIsFalseWhenNameEmpty() throws {
        let context = try TestHelpers.makeContext()
        let sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: SpyNavigator()
        )
        #expect(sut.canSave == false)
    }

    @Test @MainActor
    func canSaveIsFalseWhenNameIsWhitespace() throws {
        let context = try TestHelpers.makeContext()
        var sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: SpyNavigator()
        )
        sut.name = "   "
        #expect(sut.canSave == false)
    }

    @Test @MainActor
    func canSaveIsTrueWhenNameHasContent() throws {
        let context = try TestHelpers.makeContext()
        var sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: SpyNavigator()
        )
        sut.name = "Meditar"
        #expect(sut.canSave == true)
    }

    // MARK: - Frequency

    @Test @MainActor
    func frequencyReturnsDaily() throws {
        let context = try TestHelpers.makeContext()
        let sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: SpyNavigator(),
            frequencyType: .daily
        )
        #expect(sut.frequency == .daily)
    }

    @Test @MainActor
    func frequencyReturnsSpecificDays() throws {
        let context = try TestHelpers.makeContext()
        let days: Set<Weekday> = [.monday, .wednesday, .friday]
        let sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: SpyNavigator(),
            frequencyType: .specificDays,
            selectedDays: days
        )
        #expect(sut.frequency == .specificDays(days))
    }

    @Test @MainActor
    func frequencyReturnsTimesPerWeek() throws {
        let context = try TestHelpers.makeContext()
        let sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: SpyNavigator(),
            frequencyType: .timesPerWeek,
            timesPerWeek: 5
        )
        #expect(sut.frequency == .timesPerWeek(5))
    }

    // MARK: - Template

    @Test @MainActor
    func applyTemplatePopulatesFields() throws {
        let context = try TestHelpers.makeContext()
        let category = CategoryModel(name: "Saúde", icon: "heart", colorHex: "#F00", sortOrder: 0)
        let template = HabitTemplateModel(
            name: "Beber água", icon: "drop.fill", categoryName: "Saúde",
            defaultFrequency: .daily, defaultTargetCount: 8, defaultTargetUnit: "copos"
        )
        var sut = AddHabitProvider.Mock(
            categories: [category], templates: [template],
            modelContext: context, navigator: SpyNavigator()
        )
        sut.applyTemplate(template)
        #expect(sut.name == "Beber água")
        #expect(sut.icon == "drop.fill")
        #expect(sut.targetCount == 8)
        #expect(sut.targetUnit == "copos")
        #expect(sut.frequencyType == .daily)
        #expect(sut.selectedCategoryID == category.id)
    }

    // MARK: - Save (requires iOS Simulator for SwiftData insert)

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func saveInsertsHabitAndDismisses() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        var sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: spy,
            name: "New habit"
        )
        sut.save()
        let habits = try context.fetch(FetchDescriptor<HabitModel>())
        #expect(habits.count == 1)
        #expect(habits.first?.name == "New habit")
        #expect(spy.dismissCount == 1)
    }

    // MARK: - Cancel

    @Test @MainActor
    func cancelDismisses() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        var sut = AddHabitProvider.Mock(
            categories: [], templates: [],
            modelContext: context, navigator: spy
        )
        sut.cancel()
        #expect(spy.dismissCount == 1)
    }
}
