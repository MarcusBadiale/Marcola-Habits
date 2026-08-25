import Foundation
import Testing
import MCDomain
import MCHomeAPI
import SwiftData
@testable import MCHome

@Suite("HomeProvider")
struct HomeProviderTests {

    // MARK: - Filtered habits

    @Test @MainActor
    func filteredHabitsReturnsScheduledForToday() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Daily", icon: "star", colorHex: "#000",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .anytime
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator(),
            selectedDate: Date.now.startOfDay
        )
        #expect(sut.filteredHabits.count == 1)
    }

    @Test @MainActor
    func filteredHabitsFiltersByCategory() throws {
        let context = try TestHelpers.makeContext()
        let category = CategoryModel(name: "Health", icon: "heart", colorHex: "#F00", sortOrder: 0)
        let habit1 = HabitModel(
            name: "Run", icon: "figure.run", colorHex: "#F00",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .morning, category: category
        )
        let habit2 = HabitModel(
            name: "Read", icon: "book", colorHex: "#00F",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .evening
        )
        let sut = HomeProvider.Mock(
            habits: [habit1, habit2], categories: [category], allLogs: [],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator(),
            selectedCategoryID: category.id
        )
        #expect(sut.filteredHabits.count == 1)
        #expect(sut.filteredHabits.first?.name == "Run")
    }

    // MARK: - Completion

    @Test @MainActor
    func isCompletedReturnsFalseWithNoLog() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Test", icon: "star", colorHex: "#000",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .anytime
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator()
        )
        #expect(sut.isCompleted(habit) == false)
    }

    @Test @MainActor
    func isCompletedReturnsTrueWithCompletedLog() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Test", icon: "star", colorHex: "#000",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .anytime
        )
        let log = HabitLogModel(
            date: Date.now.startOfDay, completed: true, count: 1, habit: habit
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [log],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator()
        )
        #expect(sut.isCompleted(habit) == true)
    }

    @Test @MainActor
    func isCompletedChecksTargetCountForMultiCountHabits() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Water", icon: "drop", colorHex: "#00F",
            frequency: .daily, targetCount: 8, targetUnit: "cups",
            routine: .anytime
        )
        let partialLog = HabitLogModel(
            date: Date.now.startOfDay, completed: false, count: 3, habit: habit
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [partialLog],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator()
        )
        #expect(sut.isCompleted(habit) == false)
    }

    // MARK: - Progress

    @Test @MainActor
    func progressReturnsZeroWithNoLog() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Water", icon: "drop", colorHex: "#00F",
            frequency: .daily, targetCount: 8, targetUnit: "cups",
            routine: .anytime
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator()
        )
        #expect(sut.progress(habit) == 0)
    }

    @Test @MainActor
    func progressReturnsPartialValue() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Water", icon: "drop", colorHex: "#00F",
            frequency: .daily, targetCount: 8, targetUnit: "cups",
            routine: .anytime
        )
        let log = HabitLogModel(
            date: Date.now.startOfDay, completed: false, count: 4, habit: habit
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [log],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator()
        )
        #expect(sut.progress(habit) == 0.5)
    }

    @Test @MainActor
    func progressCapsAtOne() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Water", icon: "drop", colorHex: "#00F",
            frequency: .daily, targetCount: 8, targetUnit: "cups",
            routine: .anytime
        )
        let log = HabitLogModel(
            date: Date.now.startOfDay, completed: true, count: 10, habit: habit
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [log],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator()
        )
        #expect(sut.progress(habit) == 1.0)
    }

    // MARK: - Navigation

    @Test @MainActor
    func goToDetailPushesCorrectRoute() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        let habit = HabitModel(
            name: "Test", icon: "star", colorHex: "#000",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .anytime
        )
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [],
            modelContext: context, navigator: spy, stats: StatsCalculator()
        )
        sut.goToDetail(habit)
        #expect(spy.pushCalls.count == 1)
        #expect(spy.pushCalls.first?.route == HomeRoutes.habitDetail)
        #expect(spy.pushCalls.first?.params["id"] as? UUID == habit.id)
    }

    @Test @MainActor
    func showAddHabitPresentsCorrectRoute() throws {
        let context = try TestHelpers.makeContext()
        let spy = SpyNavigator()
        let sut = HomeProvider.Mock(
            habits: [], categories: [], allLogs: [],
            modelContext: context, navigator: spy, stats: StatsCalculator()
        )
        sut.showAddHabit()
        #expect(spy.presentCalls.count == 1)
        #expect(spy.presentCalls.first?.route == HomeRoutes.addHabit)
    }

    // MARK: - Toggle completion (requires iOS Simulator for SwiftData insert)

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func toggleCompletionCreatesLogWhenNoneExists() throws {
        let context = try TestHelpers.makeContext()
        let habit = HabitModel(
            name: "Test", icon: "star", colorHex: "#000",
            frequency: .daily, targetCount: 1, targetUnit: "",
            routine: .anytime
        )
        context.insert(habit)
        let sut = HomeProvider.Mock(
            habits: [habit], categories: [], allLogs: [],
            modelContext: context, navigator: SpyNavigator(), stats: StatsCalculator()
        )
        sut.toggleCompletion(habit)
        let logs = try context.fetch(FetchDescriptor<HabitLogModel>())
        #expect(logs.count == 1)
        #expect(logs.first?.completed == true)
    }
}
