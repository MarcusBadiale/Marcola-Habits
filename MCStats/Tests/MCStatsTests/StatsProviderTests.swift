import Foundation
import MCDomain
import MCStatsAPI
import SwiftData
import Testing
@testable import MCStats

@Suite("StatsProvider")
struct StatsProviderTests {

    // MARK: - Recorte

    @Test("activeHabits ignora arquivados")
    @MainActor
    func activeHabitsIgnoresArchived() {
        let active = TestHelpers.makeHabit(name: "Run")
        let archived = TestHelpers.makeHabit(name: "Old", isArchived: true)
        let sut = makeSUT(allHabits: [active, archived])

        #expect(sut.activeHabits.map(\.name) == ["Run"])
    }

    @Test("activeHabits ordena por nome")
    @MainActor
    func activeHabitsSortedByName() {
        let habits = ["Run", "Cook", "Meditate"].map { TestHelpers.makeHabit(name: $0) }
        let sut = makeSUT(allHabits: habits)

        #expect(sut.activeHabits.map(\.name) == ["Cook", "Meditate", "Run"])
    }

    @Test("isEmpty quando só existe hábito arquivado")
    @MainActor
    func isEmptyWithOnlyArchived() {
        let sut = makeSUT(allHabits: [TestHelpers.makeHabit(isArchived: true)])

        #expect(sut.isEmpty)
        #expect(sut.summary.habits.isEmpty)
    }

    @Test("isEmpty falso com hábito ativo")
    @MainActor
    func isEmptyFalseWithActiveHabit() {
        let sut = makeSUT(allHabits: [TestHelpers.makeHabit()])

        #expect(!sut.isEmpty)
    }

    // MARK: - Navegação

    @Test("goToHabitStats empurra a rota de detalhe com o id do hábito")
    @MainActor
    func goToHabitStatsPushesRoute() {
        let habit = TestHelpers.makeHabit()
        let spy = SpyNavigator()
        // `var` porque o `@Mockable` marca toda função do Mock como `mutating`.
        var sut = makeSUT(allHabits: [habit], navigator: spy)

        sut.goToHabitStats(habit)

        #expect(spy.pushCalls.count == 1)
        #expect(spy.pushCalls.first?.route == StatsRoutes.habitStats)
        #expect(spy.pushCalls.first?.params["id"] as? UUID == habit.id)
    }

    // MARK: - Integração com o calculator real

    /// Canário: o spy esconderia um desalinhamento de `startOfDay`/calendário entre o domínio e a
    /// feature. Com o `StatsCalculator` real, um log de hoje tem que virar a última célula.
    @Test("com o calculator real, o log de hoje é a última célula da tira")
    @MainActor
    func realCalculatorMarksTodayAsCompleted() throws {
        let habit = TestHelpers.makeHabit()
        let log = TestHelpers.makeLog(habit: habit, daysAgo: 0, completed: true)
        let sut = makeSUT(allHabits: [habit], allLogs: [log], stats: StatsCalculator())

        let row = try #require(sut.summary.habits.first)

        #expect(row.days.count == StatsPeriod.month.days)
        #expect(row.days.last?.state == .completed)
        #expect(row.days.last?.date == TestHelpers.today)
    }

    @Test("com o calculator real, hábito sem log nenhum fica com taxa zero")
    @MainActor
    func realCalculatorZeroRateWithoutLogs() {
        let habit = TestHelpers.makeHabit()
        let sut = makeSUT(allHabits: [habit], stats: StatsCalculator())

        #expect(sut.summary.rate == 0)
        #expect(sut.summary.bestStreak == 0)
    }

    // MARK: - SUT

    @MainActor
    private func makeSUT(
        allHabits: [HabitModel] = [],
        allLogs: [HabitLogModel] = [],
        navigator: SpyNavigator = SpyNavigator(),
        stats: StatsCalculatorAPI = SpyStatsCalculator(),
        period: StatsPeriod = .month
    ) -> StatsProvider.Mock {
        StatsProvider.Mock(
            allHabits: allHabits,
            allLogs: allLogs,
            navigator: navigator,
            stats: stats,
            period: period
        )
    }
}
