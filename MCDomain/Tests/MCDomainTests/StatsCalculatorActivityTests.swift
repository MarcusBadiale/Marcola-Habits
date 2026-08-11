import Testing
import Foundation
@testable import MCDomain

@Suite("StatsCalculator — Activity")
struct StatsCalculatorActivityTests {

    let sut = StatsCalculator()

    // MARK: - Forma do resultado

    @Test("uma entrada por hábito recebido, na ordem recebida", .tags(.stats))
    func activityHasOneRowPerHabitInOrder() {
        let a = StatsFixtures.makeHabit(name: "A")
        let b = StatsFixtures.makeHabit(name: "B")

        let rows = sut.activity(logs: [], habits: [a, b], days: 7)

        #expect(rows.map(\.habitID) == [a.id, b.id])
    }

    @Test("uma célula por dia do período", .tags(.stats), arguments: [7, 30, 90])
    func activityHasOneCellPerDay(days: Int) {
        let habit = StatsFixtures.makeHabit()

        let row = sut.activity(logs: [], habits: [habit], days: days).first

        #expect(row?.days.count == days)
    }

    @Test("dias contíguos, do mais antigo até hoje, sempre em startOfDay", .tags(.stats))
    func activityDaysAreContiguousAndNormalized() throws {
        let habit = StatsFixtures.makeHabit()
        let row = try #require(sut.activity(logs: [], habits: [habit], days: 30).first)
        let calendar = Calendar.current

        #expect(row.days.map(\.date) == row.days.map(\.date).sorted())
        #expect(row.days.last?.date == StatsFixtures.today)
        #expect(row.days.allSatisfy { $0.date == calendar.startOfDay(for: $0.date) })

        for (previous, current) in zip(row.days, row.days.dropFirst()) {
            let diff = calendar.dateComponents([.day], from: previous.date, to: current.date).day
            #expect(diff == 1)
        }
    }

    @Test("vazio sem hábitos", .tags(.stats))
    func activityEmptyWithoutHabits() {
        #expect(sut.activity(logs: [], habits: [], days: 7).isEmpty)
    }

    @Test("entrada sem dias quando days não é positivo", .tags(.stats), arguments: [0, -3])
    func activityHasNoDaysWhenDaysNotPositive(days: Int) {
        let habit = StatsFixtures.makeHabit()

        let rows = sut.activity(logs: [], habits: [habit], days: days)

        #expect(rows.count == 1)
        #expect(rows.first?.days.isEmpty == true)
    }

    // MARK: - Estados

    @Test("hábito diário sem logs fica todo missed", .tags(.stats))
    func activityAllMissedForDailyWithoutLogs() throws {
        let habit = StatsFixtures.makeHabit()
        let row = try #require(sut.activity(logs: [], habits: [habit], days: 7).first)

        #expect(row.days.allSatisfy { $0.state == .missed })
    }

    @Test("dia com log completo fica completed", .tags(.stats))
    func activityCompletedDay() throws {
        let habit = StatsFixtures.makeHabit()
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0)]

        let row = try #require(sut.activity(logs: logs, habits: [habit], days: 3).first)

        #expect(row.days.last?.state == .completed)
        #expect(row.days.dropLast().allSatisfy { $0.state == .missed })
    }

    @Test("specificDays: dia fora do agendamento fica notScheduled", .tags(.stats))
    func activityNotScheduledOutsideSpecificDays() throws {
        let habit = StatsFixtures.makeHabit(frequency: .specificDays([StatsFixtures.todayWeekday]))
        let row = try #require(sut.activity(logs: [], habits: [habit], days: 7).first)

        // Numa janela de 7 dias, exatamente um dia casa com o weekday agendado — e é hoje.
        #expect(row.days.filter { $0.state == .missed }.count == 1)
        #expect(row.days.last?.state == .missed)
        #expect(row.days.dropLast().allSatisfy { $0.state == .notScheduled })
    }

    @Test("timesPerWeek nunca fica missed — a obrigação dele é semanal", .tags(.stats))
    func activityNeverMissedForTimesPerWeek() throws {
        let habit = StatsFixtures.makeHabit(frequency: .timesPerWeek(3))
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 1)]

        let row = try #require(sut.activity(logs: logs, habits: [habit], days: 7).first)

        #expect(row.days.contains { $0.state == .completed })
        #expect(!row.days.contains { $0.state == .missed })
        #expect(row.days.filter { $0.state == .notScheduled }.count == 6)
    }

    @Test("conclusão em dia não agendado ainda fica completed", .tags(.stats))
    func activityCompletedOutsideSchedule() throws {
        let habit = StatsFixtures.makeHabit(frequency: .specificDays([StatsFixtures.tomorrowWeekday]))
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0)]

        let row = try #require(sut.activity(logs: logs, habits: [habit], days: 7).first)

        #expect(row.days.last?.state == .completed)
    }

    // MARK: - Filtros de log

    @Test("log incompleto não vira completed", .tags(.stats))
    func activityIgnoresIncompleteLog() throws {
        let habit = StatsFixtures.makeHabit()
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: 0, completed: false)]

        let row = try #require(sut.activity(logs: logs, habits: [habit], days: 3).first)

        #expect(!row.days.contains { $0.state == .completed })
    }

    @Test("log futuro não cria célula nem afeta o período", .tags(.stats))
    func activityIgnoresFutureLog() throws {
        let habit = StatsFixtures.makeHabit()
        let logs = [StatsFixtures.makeLog(habitID: habit.id, daysAgo: -1)]

        let row = try #require(sut.activity(logs: logs, habits: [habit], days: 3).first)

        #expect(row.days.count == 3)
        #expect(row.days.last?.date == StatsFixtures.today)
        #expect(!row.days.contains { $0.state == .completed })
    }

    @Test("log de outro hábito não vaza para a linha errada", .tags(.stats))
    func activityDoesNotLeakLogsBetweenHabits() throws {
        let a = StatsFixtures.makeHabit(name: "A")
        let b = StatsFixtures.makeHabit(name: "B")
        let logs = [StatsFixtures.makeLog(habitID: a.id, daysAgo: 0)]

        let rows = sut.activity(logs: logs, habits: [a, b], days: 3)

        #expect(rows.first?.days.last?.state == .completed)
        #expect(rows.last?.days.last?.state == .missed)
    }

    @Test("escopo de um hábito só — o uso da tela de detalhe", .tags(.stats))
    func activitySingleHabitScope() throws {
        let habit = StatsFixtures.makeHabit()
        let logs = StatsFixtures.completeEveryDay(habitID: habit.id, days: 3)

        let rows = sut.activity(logs: logs, habits: [habit], days: 7)
        let row = try #require(rows.first)

        #expect(rows.count == 1)
        #expect(row.days.count == 7)
        #expect(row.days.filter { $0.state == .completed }.count == 3)
    }
}
