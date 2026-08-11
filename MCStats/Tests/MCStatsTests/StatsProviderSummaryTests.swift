import Foundation
import MCDomain
import SwiftData
import Testing
@testable import MCStats

/// O `summary` vive em suíte própria porque `StatsProviderTests` já está perto do limite de tamanho.
@Suite("StatsProvider — summary")
struct StatsProviderSummaryTests {

    // MARK: - Período

    @Test("repassa o days do período em todas as chamadas", arguments: [StatsPeriod.week, .month, .quarter])
    @MainActor
    func summaryForwardsPeriodDays(period: StatsPeriod) {
        let spy = SpyStatsCalculator()
        let sut = makeSUT(allHabits: [TestHelpers.makeHabit()], stats: spy, period: period)

        _ = sut.summary

        #expect(spy.completionRateCalls.first?.days == period.days)
        #expect(spy.completionRatesCalls.first?.days == period.days)
        #expect(spy.activityCalls.first?.days == period.days)
    }

    @Test("período default é 30 dias")
    @MainActor
    func summaryDefaultPeriodIsThirtyDays() {
        let spy = SpyStatsCalculator()
        var sut = StatsProvider.Mock(
            allHabits: [TestHelpers.makeHabit()], allLogs: [],
            navigator: SpyNavigator(), stats: spy
        )

        _ = sut.summary

        #expect(spy.completionRateCalls.first?.days == 30)
        sut.period = .quarter
        #expect(sut.summary.habits.count == 1)
    }

    // MARK: - Taxa agregada

    @Test("rate vem do completionRate")
    @MainActor
    func summaryRateComesFromCalculator() {
        let spy = SpyStatsCalculator()
        spy.stubbedCompletionRate = 0.42
        let sut = makeSUT(allHabits: [TestHelpers.makeHabit()], stats: spy)

        #expect(sut.summary.rate == 0.42)
    }

    @Test("hábito arquivado não entra nos habits passados ao calculator")
    @MainActor
    func summaryExcludesArchivedHabit() {
        let active = TestHelpers.makeHabit(name: "Run")
        let archived = TestHelpers.makeHabit(name: "Old", isArchived: true)
        let spy = SpyStatsCalculator()
        let sut = makeSUT(allHabits: [active, archived], stats: spy)

        _ = sut.summary

        #expect(spy.completionRateCalls.first?.habits.map(\.id) == [active.id])
    }

    @Test("log de hábito arquivado não entra nos logs passados ao calculator")
    @MainActor
    func summaryExcludesLogsOfArchivedHabit() {
        let active = TestHelpers.makeHabit(name: "Run")
        let archived = TestHelpers.makeHabit(name: "Old", isArchived: true)
        let spy = SpyStatsCalculator()
        let sut = makeSUT(
            allHabits: [active, archived],
            allLogs: [TestHelpers.makeLog(habit: active), TestHelpers.makeLog(habit: archived)],
            stats: spy
        )

        _ = sut.summary

        #expect(spy.completionRateCalls.first?.logs.map(\.habitID) == [active.id])
    }

    @Test("log órfão é descartado")
    @MainActor
    func summaryDiscardsOrphanLog() {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        let sut = makeSUT(
            allHabits: [habit],
            allLogs: [TestHelpers.makeLog(habit: nil)],
            stats: spy
        )

        _ = sut.summary

        #expect(spy.completionRateCalls.first?.logs.isEmpty == true)
    }

    // MARK: - Melhor streak global

    @Test("bestStreak é o maior entre os hábitos ativos")
    @MainActor
    func summaryBestStreakTakesMax() {
        let a = TestHelpers.makeHabit(name: "A")
        let b = TestHelpers.makeHabit(name: "B")
        let spy = SpyStatsCalculator()
        spy.stubbedBestStreakByHabit = [a.id: 3, b.id: 11]
        let sut = makeSUT(allHabits: [a, b], stats: spy)

        #expect(sut.summary.bestStreak == 11)
    }

    @Test("sem hábito ativo não chama o calculator")
    @MainActor
    func summaryDoesNotCallCalculatorWithoutActiveHabits() {
        let spy = SpyStatsCalculator()
        let sut = makeSUT(allHabits: [TestHelpers.makeHabit(isArchived: true)], stats: spy)

        let summary = sut.summary

        #expect(summary.rate == 0)
        #expect(summary.bestStreak == 0)
        #expect(summary.habits.isEmpty)
        #expect(spy.bestStreakCalls.isEmpty)
        #expect(spy.completionRateCalls.isEmpty)
        #expect(spy.activityCalls.isEmpty)
    }

    // MARK: - SUT

    @MainActor
    private func makeSUT(
        allHabits: [HabitModel] = [],
        allLogs: [HabitLogModel] = [],
        stats: StatsCalculatorAPI = SpyStatsCalculator(),
        period: StatsPeriod = .month
    ) -> StatsProvider.Mock {
        StatsProvider.Mock(
            allHabits: allHabits,
            allLogs: allLogs,
            navigator: SpyNavigator(),
            stats: stats,
            period: period
        )
    }
}
