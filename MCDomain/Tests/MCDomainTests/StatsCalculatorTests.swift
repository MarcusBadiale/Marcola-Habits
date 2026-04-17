import Testing
import Foundation
@testable import MCDomain

@Suite("StatsCalculator")
struct StatsCalculatorTests {

    let sut = StatsCalculator()

    // MARK: - currentStreak

    @Test("streak com 5 dias consecutivos", .tags(.stats))
    func currentStreakConsecutive() {
        let habitID = UUID()
        let logs = (0..<5).map { daysAgo in
            makeLog(habitID: habitID, daysAgo: daysAgo, completed: true)
        }
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 5)
    }

    @Test("streak quebrado por dia faltando", .tags(.stats))
    func currentStreakBroken() {
        let habitID = UUID()
        let logs = [
            makeLog(habitID: habitID, daysAgo: 0, completed: true),
            makeLog(habitID: habitID, daysAgo: 1, completed: true),
            makeLog(habitID: habitID, daysAgo: 3, completed: true),
        ]
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 2)
    }

    @Test("streak zero sem logs", .tags(.stats))
    func currentStreakEmpty() {
        let habitID = UUID()
        #expect(sut.currentStreak(habitID: habitID, logs: []) == 0)
    }

    @Test("streak zero quando log incompleto", .tags(.stats))
    func currentStreakNotCompleted() {
        let habitID = UUID()
        let logs = [makeLog(habitID: habitID, daysAgo: 0, completed: false)]
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 0)
    }

    @Test("streak conta a partir de ontem quando hoje não foi completado", .tags(.stats))
    func currentStreakFromYesterday() {
        let habitID = UUID()
        let logs = [
            makeLog(habitID: habitID, daysAgo: 1, completed: true),
            makeLog(habitID: habitID, daysAgo: 2, completed: true),
            makeLog(habitID: habitID, daysAgo: 3, completed: true),
        ]
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 3)
    }

    // MARK: - bestStreak

    @Test("best streak maior que current", .tags(.stats))
    func bestStreakLargerThanCurrent() {
        let habitID = UUID()
        let logs = [
            makeLog(habitID: habitID, daysAgo: 10, completed: true),
            makeLog(habitID: habitID, daysAgo: 11, completed: true),
            makeLog(habitID: habitID, daysAgo: 12, completed: true),
            makeLog(habitID: habitID, daysAgo: 13, completed: true),
            makeLog(habitID: habitID, daysAgo: 0, completed: true),
            makeLog(habitID: habitID, daysAgo: 1, completed: true),
        ]
        #expect(sut.bestStreak(habitID: habitID, logs: logs) == 4)
    }

    @Test("best streak zero sem logs", .tags(.stats))
    func bestStreakEmpty() {
        let habitID = UUID()
        #expect(sut.bestStreak(habitID: habitID, logs: []) == 0)
    }

    @Test("best streak igual a 1 com dia único", .tags(.stats))
    func bestStreakSingleDay() {
        let habitID = UUID()
        let logs = [makeLog(habitID: habitID, daysAgo: 0, completed: true)]
        #expect(sut.bestStreak(habitID: habitID, logs: logs) == 1)
    }

    // MARK: - weeklyRate

    @Test("weekly rate 100% quando todos completados", .tags(.stats))
    func weeklyRateAllCompleted() {
        let rate = sut.weeklyRate(totalHabits: 5, completedToday: 5, daysInWeek: 7)
        #expect(abs(rate - 1.0) < 0.001)
    }

    @Test("weekly rate 0 sem hábitos", .tags(.stats))
    func weeklyRateEmpty() {
        #expect(sut.weeklyRate(totalHabits: 0, completedToday: 0, daysInWeek: 7) == 0.0)
    }

    @Test("weekly rate 50% com metade completada", .tags(.stats))
    func weeklyRateHalf() {
        let rate = sut.weeklyRate(totalHabits: 4, completedToday: 2, daysInWeek: 7)
        #expect(abs(rate - 0.5) < 0.001)
    }

    // MARK: - heatmap

    @Test("heatmap retorna ratio correto por dia", .tags(.stats))
    func heatmapRatio() {
        let habitA = UUID()
        let habitB = UUID()
        let today = Calendar.current.startOfDay(for: .now)
        let logs = [
            makeLog(habitID: habitA, daysAgo: 0, completed: true),
            makeLog(habitID: habitB, daysAgo: 0, completed: false),
        ]
        let map = sut.heatmap(logs: logs, days: 30)
        let ratio = map[today]
        #expect(ratio != nil)
        #expect(abs((ratio ?? 0) - 0.5) < 0.001)
    }

    @Test("heatmap vazio sem logs", .tags(.stats))
    func heatmapEmpty() {
        let map = sut.heatmap(logs: [], days: 30)
        #expect(map.isEmpty)
    }

    @Test("heatmap ignora logs fora do range", .tags(.stats))
    func heatmapOutOfRange() {
        let habitID = UUID()
        let logs = [makeLog(habitID: habitID, daysAgo: 60, completed: true)]
        let map = sut.heatmap(logs: logs, days: 30)
        #expect(map.isEmpty)
    }

    // MARK: - Helpers

    private func makeLog(habitID: UUID, daysAgo: Int, completed: Bool) -> HabitLogDTO {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return HabitLogDTO(
            id: UUID(),
            habitID: habitID,
            date: date,
            completed: completed,
            count: completed ? 1 : 0
        )
    }
}
