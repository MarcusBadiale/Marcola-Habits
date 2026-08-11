import Testing
import Foundation
@testable import MCDomain

@Suite("StatsCalculator — Completion Rate")
struct StatsCalculatorCompletionRateTests {

    let sut = StatsCalculator()

    // MARK: - Casos básicos

    @Test("taxa 1.0 quando todos os dias agendados foram completados", .tags(.stats))
    func rateAllCompleted() {
        let a = StatsFixtures.makeHabit()
        let b = StatsFixtures.makeHabit()
        let logs = StatsFixtures.completeEveryDay(habitID: a.id, days: 7)
            + StatsFixtures.completeEveryDay(habitID: b.id, days: 7)

        #expect(abs(sut.completionRate(logs: logs, habits: [a, b], days: 7) - 1.0) < 0.001)
    }

    @Test("taxa 0.5 com um hábito completo e outro zerado", .tags(.stats))
    func rateHalf() {
        let a = StatsFixtures.makeHabit()
        let b = StatsFixtures.makeHabit()
        let logs = StatsFixtures.completeEveryDay(habitID: a.id, days: 4)

        #expect(abs(sut.completionRate(logs: logs, habits: [a, b], days: 4) - 0.5) < 0.001)
    }

    @Test("taxa 0 sem hábitos", .tags(.stats))
    func rateZeroWithoutHabits() {
        let logs = StatsFixtures.completeEveryDay(habitID: UUID(), days: 7)
        #expect(sut.completionRate(logs: logs, habits: [], days: 7) == 0)
    }

    @Test("taxa 0 quando days não é positivo", .tags(.stats), arguments: [0, -5])
    func rateZeroWhenDaysNotPositive(days: Int) {
        let habit = StatsFixtures.makeHabit()
        let logs = StatsFixtures.completeEveryDay(habitID: habit.id, days: 3)

        #expect(sut.completionRate(logs: logs, habits: [habit], days: days) == 0)
    }

    // MARK: - Bordas do período

    @Test("dia mais antigo do período conta", .tags(.stats))
    func rateIncludesOldestDayOfPeriod() {
        let habit = StatsFixtures.makeHabit()
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 6)]

        let rate = sut.completionRate(logs: logs, habits: [habit], days: 7)
        #expect(abs(rate - 1.0 / 7.0) < 0.001)
    }

    @Test("dia logo fora do período não conta", .tags(.stats))
    func rateExcludesDayJustOutsidePeriod() {
        let habit = StatsFixtures.makeHabit()
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 7)]

        #expect(sut.completionRate(logs: logs, habits: [habit], days: 7) == 0)
    }

    @Test("log futuro é ignorado", .tags(.stats))
    func rateIgnoresFutureLogs() {
        let habit = StatsFixtures.makeHabit()
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: -1)]

        #expect(sut.completionRate(logs: logs, habits: [habit], days: 7) == 0)
    }

    @Test("dia intermediário sem log conta como falha", .tags(.stats))
    func rateCountsIntermediateDayWithoutLogAsFailure() {
        let habit = StatsFixtures.makeHabit()
        let logs = [
            StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0),
            StatsFixtures.makeLog(habitID: habit.id, daysAgo: 2),
        ]

        let rate = sut.completionRate(logs: logs, habits: [habit], days: 3)
        #expect(abs(rate - 2.0 / 3.0) < 0.001)
    }

    // MARK: - Filtros de log

    @Test("log incompleto é ignorado", .tags(.stats))
    func rateIgnoresIncompleteLogs() {
        let habit = StatsFixtures.makeHabit()
        let logs = (0..<3).map {
            StatsFixtures.makeLog(habitID: habit.id, daysAgo: $0, completed: false)
        }

        #expect(sut.completionRate(logs: logs, habits: [habit], days: 3) == 0)
    }

    @Test("log de hábito desconhecido é ignorado", .tags(.stats))
    func rateIgnoresLogsOfUnknownHabit() {
        let habit = StatsFixtures.makeHabit()
        let logs = StatsFixtures.completeEveryDay(habitID: UUID(), days: 3)

        #expect(sut.completionRate(logs: logs, habits: [habit], days: 3) == 0)
    }

    @Test("dois logs completos no mesmo dia contam como um", .tags(.stats))
    func rateDeduplicatesLogsOnSameDay() {
        let habit = StatsFixtures.makeHabit()
        let logs = [
            StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0),
            StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0),
        ]

        #expect(abs(sut.completionRate(logs: logs, habits: [habit], days: 1) - 1.0) < 0.001)
    }

    @Test("hábito arquivado passado in conta — filtrar é política do caller", .tags(.stats))
    func rateCountsArchivedHabitWhenPassedIn() {
        let habit = StatsFixtures.makeHabit(isArchived: true)
        let logs = StatsFixtures.completeEveryDay(habitID: habit.id, days: 3)

        #expect(abs(sut.completionRate(logs: logs, habits: [habit], days: 3) - 1.0) < 0.001)
    }

    // MARK: - specificDays

    @Test("só os dias agendados entram no denominador", .tags(.stats))
    func rateCountsOnlyScheduledDays() {
        let weekday = StatsFixtures.todayWeekday
        let habit = StatsFixtures.makeHabit(frequency: .specificDays([weekday]))
        // Numa janela de 7 dias existe exatamente uma ocorrência de cada dia da semana.
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0)]

        #expect(abs(sut.completionRate(logs: logs, habits: [habit], days: 7) - 1.0) < 0.001)
    }

    @Test("conclusão em dia não agendado não paga o dia agendado", .tags(.stats))
    func rateIgnoresCompletionOnUnscheduledDay() {
        // Hábito agendado só para amanhã-da-semana; a única conclusão é hoje.
        let habit = StatsFixtures.makeHabit(frequency: .specificDays([StatsFixtures.tomorrowWeekday]))
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0)]

        #expect(sut.completionRate(logs: logs, habits: [habit], days: 7) == 0)
    }

    @Test("taxa 0 quando nada está agendado no período", .tags(.stats))
    func rateZeroWhenNothingScheduled() {
        let habit = StatsFixtures.makeHabit(frequency: .specificDays([]))

        #expect(sut.completionRate(logs: [], habits: [habit], days: 7) == 0)
    }
}
