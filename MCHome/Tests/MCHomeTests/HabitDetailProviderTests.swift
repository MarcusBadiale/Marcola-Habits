import Foundation
import Testing
import MCDomain
import SwiftData
@testable import MCHome

@Suite("HabitDetailProvider")
struct HabitDetailProviderTests {

    // MARK: - Habit lookup

    @Test("habit acha o modelo pelo habitID")
    @MainActor
    func habitFindsByID() throws {
        let habit = TestHelpers.makeHabit()
        let other = TestHelpers.makeHabit(name: "Read")
        let sut = try makeSUT(habitID: habit.id, allHabits: [other, habit])
        #expect(sut.habit?.id == habit.id)
    }

    @Test("habit retorna nil quando o ID não está na lista")
    @MainActor
    func habitReturnsNilWhenMissing() throws {
        let sut = try makeSUT(habitID: UUID(), allHabits: [TestHelpers.makeHabit()])
        #expect(sut.habit == nil)
    }

    // MARK: - Recent logs

    @Test("recentLogs ignora logs de outro hábito")
    @MainActor
    func recentLogsFiltersByHabit() throws {
        let habit = TestHelpers.makeHabit()
        let other = TestHelpers.makeHabit(name: "Read")
        let logs = [
            TestHelpers.makeLog(habit: habit, daysAgo: 0),
            TestHelpers.makeLog(habit: other, daysAgo: 1),
        ]
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit, other], allLogs: logs)
        #expect(sut.recentLogs.count == 1)
        #expect(sut.recentLogs.first?.habit?.id == habit.id)
    }

    @Test("recentLogs ordena da data mais recente pra mais antiga")
    @MainActor
    func recentLogsSortsDescending() throws {
        let habit = TestHelpers.makeHabit()
        let logs = [
            TestHelpers.makeLog(habit: habit, daysAgo: 5),
            TestHelpers.makeLog(habit: habit, daysAgo: 0),
            TestHelpers.makeLog(habit: habit, daysAgo: 2),
        ]
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit], allLogs: logs)
        let dates = sut.recentLogs.map(\.date)
        #expect(dates == dates.sorted(by: >))
    }

    @Test("recentLogs corta em 14 entradas")
    @MainActor
    func recentLogsCapsAt14() throws {
        let habit = TestHelpers.makeHabit()
        let logs = (0..<20).map { TestHelpers.makeLog(habit: habit, daysAgo: $0) }
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit], allLogs: logs)
        #expect(sut.recentLogs.count == 14)
    }

    @Test("recentLogs é vazio quando o hábito não existe")
    @MainActor
    func recentLogsEmptyWhenHabitMissing() throws {
        let habit = TestHelpers.makeHabit()
        let sut = try makeSUT(
            habitID: UUID(), allHabits: [],
            allLogs: [TestHelpers.makeLog(habit: habit)]
        )
        #expect(sut.recentLogs.isEmpty)
    }

    // MARK: - Current streak (delega pro StatsCalculator)

    @Test("currentStreak delega pro calculator com o habitID certo")
    @MainActor
    func currentStreakDelegatesToCalculator() throws {
        let habit = TestHelpers.makeHabit()
        let spy = SpyStatsCalculator()
        spy.stubbedCurrentStreak = 7
        let sut = try makeSUT(
            habitID: habit.id, allHabits: [habit],
            allLogs: [TestHelpers.makeLog(habit: habit)],
            stats: spy
        )
        #expect(sut.currentStreak == 7)
        #expect(spy.currentStreakCalls.count == 1)
        #expect(spy.currentStreakCalls.first?.habitID == habit.id)
    }

    @Test("currentStreak passa só os logs do próprio hábito")
    @MainActor
    func currentStreakPassesOnlyOwnLogs() throws {
        let habit = TestHelpers.makeHabit()
        let other = TestHelpers.makeHabit(name: "Read")
        let spy = SpyStatsCalculator()
        let logs = [
            TestHelpers.makeLog(habit: habit, daysAgo: 0),
            TestHelpers.makeLog(habit: other, daysAgo: 0),
            TestHelpers.makeLog(habit: habit, daysAgo: 1),
        ]
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit, other], allLogs: logs, stats: spy)
        _ = sut.currentStreak
        let passed = try #require(spy.currentStreakCalls.first?.logs)
        #expect(passed.count == 2)
        #expect(passed.allSatisfy { $0.habitID == habit.id })
    }

    @Test("currentStreak é zero e não chama o calculator sem hábito")
    @MainActor
    func currentStreakZeroWhenHabitMissing() throws {
        let spy = SpyStatsCalculator()
        spy.stubbedCurrentStreak = 99
        let sut = try makeSUT(habitID: UUID(), allHabits: [], stats: spy)
        #expect(sut.currentStreak == 0)
        #expect(spy.currentStreakCalls.isEmpty)
    }

    // MARK: - Frequency description

    @Test("frequencyDescription para .daily")
    @MainActor
    func frequencyDescriptionDaily() throws {
        let habit = TestHelpers.makeHabit(frequency: .daily)
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit])
        #expect(sut.frequencyDescription == "Every day")
    }

    @Test("frequencyDescription ordena os dias da semana")
    @MainActor
    func frequencyDescriptionSpecificDays() throws {
        let habit = TestHelpers.makeHabit(frequency: .specificDays([.friday, .monday, .wednesday]))
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit])
        #expect(sut.frequencyDescription == "Mon, Wed, Fri")
    }

    @Test("frequencyDescription para .timesPerWeek")
    @MainActor
    func frequencyDescriptionTimesPerWeek() throws {
        let habit = TestHelpers.makeHabit(frequency: .timesPerWeek(3))
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit])
        #expect(sut.frequencyDescription == "3x per week")
    }

    @Test("frequencyDescription é vazia sem hábito")
    @MainActor
    func frequencyDescriptionEmptyWhenHabitMissing() throws {
        let sut = try makeSUT(habitID: UUID(), allHabits: [])
        #expect(sut.frequencyDescription.isEmpty)
    }

    // MARK: - Archive

    @Test("archiveHabit arquiva o hábito e volta pra tela anterior")
    @MainActor
    func archiveHabitArchivesAndPops() throws {
        let habit = TestHelpers.makeHabit()
        let previousUpdatedAt = habit.updatedAt
        let spy = SpyNavigator()
        let sut = try makeSUT(habitID: habit.id, allHabits: [habit], navigator: spy)

        sut.archiveHabit()

        #expect(habit.isArchived)
        #expect(habit.updatedAt >= previousUpdatedAt)
        #expect(spy.popCount == 1)
    }

    @Test("archiveHabit não navega quando o hábito não existe")
    @MainActor
    func archiveHabitNoOpWhenHabitMissing() throws {
        let spy = SpyNavigator()
        let sut = try makeSUT(habitID: UUID(), allHabits: [], navigator: spy)

        sut.archiveHabit()

        #expect(spy.popCount == 0)
    }

    // MARK: - SUT

    @MainActor
    private func makeSUT(
        habitID: UUID,
        allHabits: [HabitModel],
        allLogs: [HabitLogModel] = [],
        navigator: SpyNavigator = SpyNavigator(),
        stats: StatsCalculatorAPI = SpyStatsCalculator()
    ) throws -> HabitDetailProvider.Mock {
        HabitDetailProvider.Mock(
            habitID: habitID,
            allHabits: allHabits,
            allLogs: allLogs,
            modelContext: try TestHelpers.makeContext(),
            navigator: navigator,
            stats: stats
        )
    }
}
