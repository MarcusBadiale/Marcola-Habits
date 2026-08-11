import Foundation
import MCDomain
import SwiftData
import Testing
@testable import MCStats

/// As linhas por hábito do `summary`. Arquivo próprio porque `StatsProviderSummaryTests` já está
/// no limite de tamanho.
@Suite("StatsProvider — linhas por hábito")
struct StatsProviderRowTests {

    @Test("streak da linha vem do currentStreak, com a lista completa de logs")
    @MainActor
    func rowStreakComesFromCalculator() {
        let a = TestHelpers.makeHabit(name: "A")
        let b = TestHelpers.makeHabit(name: "B")
        let spy = SpyStatsCalculator()
        spy.stubbedCurrentStreakByHabit = [a.id: 7, b.id: 2]
        let sut = makeSUT(
            allHabits: [a, b],
            allLogs: [TestHelpers.makeLog(habit: a), TestHelpers.makeLog(habit: b)],
            stats: spy
        )

        let rows = sut.summary.habits

        #expect(rows.map(\.streak) == [7, 2])
        // `currentStreak` filtra por habitID internamente — o provider não pré-filtra por hábito.
        #expect(spy.currentStreakCalls.allSatisfy { $0.logs.count == 2 })
    }

    @Test("rate da linha vem do batch completionRates, numa chamada só")
    @MainActor
    func rowRateComesFromBatch() {
        let a = TestHelpers.makeHabit(name: "A")
        let b = TestHelpers.makeHabit(name: "B")
        let spy = SpyStatsCalculator()
        spy.stubbedCompletionRates = [a.id: 0.9]
        let sut = makeSUT(allHabits: [a, b], stats: spy)

        let rows = sut.summary.habits

        #expect(rows.map(\.rate) == [0.9, 0])
        #expect(spy.completionRatesCalls.count == 1)
    }

    @Test("days da linha casam pelo habitID, não pela ordem")
    @MainActor
    func rowDaysMatchByHabitID() {
        let a = TestHelpers.makeHabit(name: "A")
        let b = TestHelpers.makeHabit(name: "B")
        let spy = SpyStatsCalculator()
        // De propósito na ordem trocada: o provider casa por id.
        spy.stubbedActivity = [
            HabitActivityDTO(habitID: b.id, days: [DayActivityDTO(date: TestHelpers.today, state: .completed)]),
            HabitActivityDTO(habitID: a.id, days: []),
        ]
        let sut = makeSUT(allHabits: [a, b], stats: spy)

        let rows = sut.summary.habits

        #expect(rows.first?.days.isEmpty == true)
        #expect(rows.last?.days.first?.state == .completed)
    }

    @Test("linha sem activity correspondente fica com days vazio")
    @MainActor
    func rowWithoutActivityHasNoDays() {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        spy.stubbedActivity = [HabitActivityDTO(habitID: UUID(), days: [])]
        let sut = makeSUT(allHabits: [habit], stats: spy)

        #expect(sut.summary.habits.first?.days.isEmpty == true)
    }

    // MARK: - SUT

    @MainActor
    private func makeSUT(
        allHabits: [HabitModel] = [],
        allLogs: [HabitLogModel] = [],
        stats: StatsCalculatorAPI = SpyStatsCalculator()
    ) -> StatsProvider.Mock {
        StatsProvider.Mock(
            allHabits: allHabits,
            allLogs: allLogs,
            navigator: SpyNavigator(),
            stats: stats
        )
    }
}
