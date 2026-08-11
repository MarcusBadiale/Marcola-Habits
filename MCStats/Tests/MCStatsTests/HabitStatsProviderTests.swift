import Foundation
import MCDomain
import SwiftData
import Testing
@testable import MCStats

@Suite("HabitStatsProvider")
struct HabitStatsProviderTests {

    // MARK: - Lookup

    @Test("acha o hábito pelo id")
    @MainActor
    func findsHabitByID() {
        let target = TestHelpers.makeHabit(name: "Run")
        let other = TestHelpers.makeHabit(name: "Cook")
        let sut = makeSUT(habitID: target.id, allHabits: [other, target])

        #expect(sut.habit?.name == "Run")
    }

    @Test("habit é nil quando o id não existe")
    @MainActor
    func habitNilWhenNotFound() {
        let sut = makeSUT(habitID: UUID(), allHabits: [TestHelpers.makeHabit()])

        #expect(sut.habit == nil)
    }

    // MARK: - Delegação

    @Test("streaks e taxa vêm do calculator, com o habitID certo")
    @MainActor
    func summaryDelegatesWithHabitID() {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        spy.stubbedCurrentStreak = 7
        spy.stubbedBestStreak = 14
        spy.stubbedCompletionRate = 0.86
        let sut = makeSUT(habitID: habit.id, allHabits: [habit], stats: spy)

        let summary = sut.summary

        #expect(summary.currentStreak == 7)
        #expect(summary.bestStreak == 14)
        #expect(summary.rate == 0.86)
        #expect(spy.currentStreakCalls.first?.habitID == habit.id)
        #expect(spy.bestStreakCalls.first?.habitID == habit.id)
    }

    @Test("repassa o days do período", arguments: [StatsPeriod.week, .month, .quarter])
    @MainActor
    func summaryForwardsPeriodDays(period: StatsPeriod) {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        let sut = makeSUT(habitID: habit.id, allHabits: [habit], stats: spy, period: period)

        _ = sut.summary

        #expect(spy.completionRateCalls.first?.days == period.days)
        #expect(spy.activityCalls.first?.days == period.days)
    }

    @Test("troca de período muda o days repassado")
    @MainActor
    func changingPeriodChangesForwardedDays() {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        var sut = makeSUT(habitID: habit.id, allHabits: [habit], stats: spy, period: .week)

        _ = sut.summary
        sut.period = .quarter
        _ = sut.summary

        #expect(spy.completionRateCalls.map(\.days) == [7, 90])
    }

    @Test("passa só o DTO do próprio hábito")
    @MainActor
    func summaryPassesOnlyOwnHabitDTO() {
        let habit = TestHelpers.makeHabit()
        let other = TestHelpers.makeHabit(name: "Other")
        let spy = SpyStatsCalculator()
        let sut = makeSUT(habitID: habit.id, allHabits: [habit, other], stats: spy)

        _ = sut.summary

        #expect(spy.completionRateCalls.first?.habits.map(\.id) == [habit.id])
        #expect(spy.activityCalls.first?.habits.map(\.id) == [habit.id])
    }

    @Test("passa só os logs do próprio hábito")
    @MainActor
    func summaryPassesOnlyOwnLogs() {
        let habit = TestHelpers.makeHabit()
        let other = TestHelpers.makeHabit(name: "Other")
        let spy = SpyStatsCalculator()
        let sut = makeSUT(
            habitID: habit.id,
            allHabits: [habit, other],
            allLogs: [
                TestHelpers.makeLog(habit: habit),
                TestHelpers.makeLog(habit: habit, daysAgo: 1),
                TestHelpers.makeLog(habit: other),
                TestHelpers.makeLog(habit: nil),
            ],
            stats: spy
        )

        _ = sut.summary

        let logs = spy.currentStreakCalls.first?.logs ?? []
        #expect(logs.count == 2)
        #expect(logs.allSatisfy { $0.habitID == habit.id })
    }

    @Test("days vêm da linha de activity do hábito")
    @MainActor
    func summaryDaysComeFromActivity() {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        spy.stubbedActivityDays = [DayActivityDTO(date: TestHelpers.today, state: .completed)]
        let sut = makeSUT(habitID: habit.id, allHabits: [habit], stats: spy)

        #expect(sut.summary.days.map(\.state) == [.completed])
    }

    // MARK: - Hábito inexistente

    @Test("sem hábito, o summary é vazio e o calculator não é chamado")
    @MainActor
    func summaryEmptyWithoutHabit() {
        let spy = SpyStatsCalculator()
        spy.stubbedCurrentStreak = 7
        spy.stubbedCompletionRate = 0.9
        let sut = makeSUT(habitID: UUID(), allHabits: [], stats: spy)

        let summary = sut.summary

        #expect(summary.currentStreak == 0)
        #expect(summary.bestStreak == 0)
        #expect(summary.rate == 0)
        #expect(summary.days.isEmpty)
        #expect(spy.currentStreakCalls.isEmpty)
        #expect(spy.bestStreakCalls.isEmpty)
        #expect(spy.completionRateCalls.isEmpty)
        #expect(spy.activityCalls.isEmpty)
    }

    // MARK: - SUT

    @MainActor
    private func makeSUT(
        habitID: UUID,
        allHabits: [HabitModel] = [],
        allLogs: [HabitLogModel] = [],
        stats: StatsCalculatorAPI = SpyStatsCalculator(),
        period: StatsPeriod = .month
    ) -> HabitStatsProvider.Mock {
        HabitStatsProvider.Mock(
            habitID: habitID,
            allHabits: allHabits,
            allLogs: allLogs,
            stats: stats,
            period: period
        )
    }
}
