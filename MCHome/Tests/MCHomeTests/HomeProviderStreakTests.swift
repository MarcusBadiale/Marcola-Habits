import Foundation
import Testing
import MCDomain
import SwiftData
@testable import MCHome

/// Streak vive em arquivo próprio porque `HomeProviderTests` já está no limite de tamanho.
@Suite("HomeProvider — streak")
struct HomeProviderStreakTests {

    @Test("streak delega pro calculator com o habitID certo")
    @MainActor
    func streakDelegatesToCalculator() throws {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        spy.stubbedCurrentStreak = 12
        let sut = try makeSUT(habits: [habit], allLogs: [TestHelpers.makeLog(habit: habit)], stats: spy)

        #expect(sut.streak(habit) == 12)
        #expect(spy.currentStreakCalls.count == 1)
        #expect(spy.currentStreakCalls.first?.habitID == habit.id)
    }

    @Test("streak passa só os logs do próprio hábito")
    @MainActor
    func streakPassesOnlyOwnLogs() throws {
        let habit = TestHelpers.makeHabit()
        let other = TestHelpers.makeHabit(name: "Read")
        let spy = SpyStatsCalculator()
        let logs = [
            TestHelpers.makeLog(habit: habit, daysAgo: 0),
            TestHelpers.makeLog(habit: other, daysAgo: 0),
            TestHelpers.makeLog(habit: habit, daysAgo: 1),
        ]
        let sut = try makeSUT(habits: [habit, other], allLogs: logs, stats: spy)

        _ = sut.streak(habit)

        let passed = try #require(spy.currentStreakCalls.first?.logs)
        #expect(passed.count == 2)
        #expect(passed.allSatisfy { $0.habitID == habit.id })
    }

    @Test("streak sobrevive à virada do dia — conta a partir de ontem")
    @MainActor
    func streakCountsFromYesterdayWhenTodayNotDone() throws {
        let habit = TestHelpers.makeHabit()
        // Três dias seguidos completados até ontem, sem check-in hoje.
        let logs = (1...3).map { TestHelpers.makeLog(habit: habit, daysAgo: $0, completed: true) }
        let sut = try makeSUT(habits: [habit], allLogs: logs, stats: StatsCalculator())

        #expect(sut.streak(habit) == 3)
    }

    @Test("streak é zero sem nenhum log")
    @MainActor
    func streakZeroWithoutLogs() throws {
        let habit = TestHelpers.makeHabit()
        let sut = try makeSUT(habits: [habit], stats: StatsCalculator())
        #expect(sut.streak(habit) == 0)
    }

    // MARK: - SUT

    @MainActor
    private func makeSUT(
        habits: [HabitModel],
        allLogs: [HabitLogModel] = [],
        stats: StatsCalculatorAPI
    ) throws -> HomeProvider.Mock {
        HomeProvider.Mock(
            habits: habits,
            categories: [],
            allLogs: allLogs,
            modelContext: try TestHelpers.makeContext(),
            navigator: SpyNavigator(),
            stats: stats
        )
    }
}
