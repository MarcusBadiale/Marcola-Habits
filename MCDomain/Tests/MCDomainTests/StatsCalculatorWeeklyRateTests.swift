import Testing
import Foundation
@testable import MCDomain

/// A medida é semanal (não diária), e é isso que tira a penalização do `.timesPerWeek`.
/// `completionRates` (a versão por hábito) vive aqui junto porque compartilha a mesma matemática.
@Suite("StatsCalculator — Medida semanal")
struct StatsCalculatorWeeklyRateTests {

    let sut = StatsCalculator()

    // MARK: - timesPerWeek

    @Test("timesPerWeek completando todos os dias dá 1.0", .tags(.stats))
    func rateTimesPerWeekAllDaysCompleted() {
        let habit = StatsFixtures.makeHabit(frequency: .timesPerWeek(3))
        let logs = StatsFixtures.completeEveryDay(habitID: habit.id, days: 7)

        #expect(abs(sut.completionRate(logs: logs, habits: [habit], days: 7) - 1.0) < 0.001)
    }

    @Test("timesPerWeek sem conclusão nenhuma dá 0", .tags(.stats))
    func rateTimesPerWeekWithoutLogs() {
        let habit = StatsFixtures.makeHabit(frequency: .timesPerWeek(3))

        #expect(sut.completionRate(logs: [], habits: [habit], days: 7) == 0)
    }

    @Test("timesPerWeek não é mais penalizado como se fosse diário", .tags(.stats))
    func rateTimesPerWeekBeatsDailyForSameCompletions() {
        // A mesma rotina — seg/qua/sex, 4 semanas — medida com as duas frequências.
        // Antes da medida semanal, `.timesPerWeek(3)` era tratado como agendado todo dia e pontuava
        // igual a um hábito diário: ~43%, punindo quem cumpriu exatamente o combinado.
        let threeTimes = StatsFixtures.makeHabit(frequency: .timesPerWeek(3))
        let daily = StatsFixtures.makeHabit(frequency: .daily)
        let routine = StatsFixtures.daysAgo(
            matching: [.monday, .wednesday, .friday],
            withinLastDays: 28
        )

        let weeklyRate = sut.completionRate(
            logs: routine.map { StatsFixtures.makeLog(habitID: threeTimes.id, daysAgo: $0) },
            habits: [threeTimes],
            days: 28
        )
        let dailyRate = sut.completionRate(
            logs: routine.map { StatsFixtures.makeLog(habitID: daily.id, daysAgo: $0) },
            habits: [daily],
            days: 28
        )

        // Em 28 dias há exatamente 4 de cada dia da semana, então a rotina tem 12 conclusões.
        #expect(routine.count == 12)
        #expect(abs(dailyRate - 12.0 / 28.0) < 0.001)
        #expect(weeklyRate > 0.85)
    }

    @Test("timesPerWeek(7) equivale a diário", .tags(.stats))
    func rateSevenTimesPerWeekMatchesDaily() {
        let sevenTimes = StatsFixtures.makeHabit(frequency: .timesPerWeek(7))
        let daily = StatsFixtures.makeHabit(frequency: .daily)

        let weeklyRate = sut.completionRate(
            logs: StatsFixtures.completeEveryDay(habitID: sevenTimes.id, days: 7),
            habits: [sevenTimes],
            days: 7
        )
        let dailyRate = sut.completionRate(
            logs: StatsFixtures.completeEveryDay(habitID: daily.id, days: 7),
            habits: [daily],
            days: 7
        )

        #expect(abs(weeklyRate - 1.0) < 0.001)
        #expect(abs(weeklyRate - dailyRate) < 0.001)
    }

    @Test("semana parcial na borda do período é pró-rateada", .tags(.stats))
    func rateProRatesPartialWeek() {
        // 7x por semana num período de 3 dias: o target é 3, não 7.
        let habit = StatsFixtures.makeHabit(frequency: .timesPerWeek(7))
        let logs = StatsFixtures.completeEveryDay(habitID: habit.id, days: 3)

        #expect(abs(sut.completionRate(logs: logs, habits: [habit], days: 3) - 1.0) < 0.001)
    }

    @Test("crédito de uma semana não passa do target pró-rateado dela", .tags(.stats))
    func rateDoesNotCarryCreditAcrossWeeks() {
        // Aresta conhecida de medir por semana: concentrar as conclusões numa semana não paga a
        // obrigação das outras. Um 3x/semana que fez 3 dias e parou não fica em 100% do mês — o
        // crédito é clampado no target daquela semana. Comparar com o teste de rotina seg/qua/sex,
        // onde as conclusões estão distribuídas e a taxa sobe pra ~0.96.
        let habit = StatsFixtures.makeHabit(frequency: .timesPerWeek(3))
        let logs = StatsFixtures.completeEveryDay(habitID: habit.id, days: 3)

        #expect(sut.completionRate(logs: logs, habits: [habit], days: 28) < 0.2)
    }

    // MARK: - completionRates (por hábito)

    @Test("tem entrada para todo hábito recebido, inclusive zerado", .tags(.stats))
    func ratesHaveEntryForEveryHabit() {
        let a = StatsFixtures.makeHabit()
        let b = StatsFixtures.makeHabit()
        let logs = StatsFixtures.completeEveryDay(habitID: a.id, days: 4)

        let rates = sut.completionRates(logs: logs, habits: [a, b], days: 4)

        #expect(rates.count == 2)
        #expect(abs((rates[a.id] ?? -1) - 1.0) < 0.001)
        #expect(rates[b.id] == 0)
    }

    @Test("vazio sem hábitos", .tags(.stats))
    func ratesEmptyWithoutHabits() {
        #expect(sut.completionRates(logs: [], habits: [], days: 7).isEmpty)
    }

    @Test("chave presente com 0 quando days não é positivo", .tags(.stats))
    func ratesZeroWhenDaysNotPositive() {
        let habit = StatsFixtures.makeHabit()
        let logs = StatsFixtures.completeEveryDay(habitID: habit.id, days: 3)

        let rates = sut.completionRates(logs: logs, habits: [habit], days: 0)

        #expect(rates.count == 1)
        #expect(rates[habit.id] == 0)
    }

    @Test("a taxa agregada não é a média das taxas por hábito", .tags(.stats))
    func aggregateRateDiffersFromMeanOfPerHabitRates() {
        // A: diário, 7 de 7. B: um dia da semana só, 0 de 1.
        let a = StatsFixtures.makeHabit()
        let b = StatsFixtures.makeHabit(frequency: .specificDays([StatsFixtures.tomorrowWeekday]))
        let logs = StatsFixtures.completeEveryDay(habitID: a.id, days: 7)

        let aggregate = sut.completionRate(logs: logs, habits: [a, b], days: 7)
        let rates = sut.completionRates(logs: logs, habits: [a, b], days: 7)
        let mean = rates.values.reduce(0, +) / Double(rates.count)

        #expect(abs(aggregate - 0.875) < 0.001)   // 7 feitos de 8 agendados
        #expect(abs(mean - 0.5) < 0.001)          // média de 1.0 e 0.0
    }
}
