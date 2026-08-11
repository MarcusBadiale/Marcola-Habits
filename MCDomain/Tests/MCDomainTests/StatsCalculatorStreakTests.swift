import Testing
import Foundation
@testable import MCDomain

@Suite("StatsCalculator — Streaks")
struct StatsCalculatorStreakTests {

    let sut = StatsCalculator()

    // MARK: - currentStreak

    @Test("streak com 5 dias consecutivos", .tags(.stats))
    func currentStreakConsecutive() {
        let habitID = UUID()
        let logs = (0..<5).map { daysAgo in
            StatsFixtures.makeLog(habitID: habitID, daysAgo: daysAgo, completed: true)
        }
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 5)
    }

    @Test("streak quebrado por dia faltando", .tags(.stats))
    func currentStreakBroken() {
        let habitID = UUID()
        let logs = [
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 0, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 1, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 3, completed: true),
        ]
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 2)
    }

    @Test("streak zero sem logs", .tags(.stats))
    func currentStreakEmpty() {
        #expect(sut.currentStreak(habitID: UUID(), logs: []) == 0)
    }

    @Test("streak zero quando log incompleto", .tags(.stats))
    func currentStreakNotCompleted() {
        let habitID = UUID()
        let logs = [StatsFixtures.makeLog(habitID: habitID, daysAgo: 0, completed: false)]
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 0)
    }

    @Test("streak conta a partir de ontem quando hoje não foi completado", .tags(.stats))
    func currentStreakFromYesterday() {
        let habitID = UUID()
        let logs = [
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 1, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 2, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 3, completed: true),
        ]
        #expect(sut.currentStreak(habitID: habitID, logs: logs) == 3)
    }

    // MARK: - bestStreak

    @Test("best streak maior que current", .tags(.stats))
    func bestStreakLargerThanCurrent() {
        let habitID = UUID()
        let logs = [
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 10, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 11, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 12, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 13, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 0, completed: true),
            StatsFixtures.makeLog(habitID: habitID, daysAgo: 1, completed: true),
        ]
        #expect(sut.bestStreak(habitID: habitID, logs: logs) == 4)
    }

    @Test("best streak zero sem logs", .tags(.stats))
    func bestStreakEmpty() {
        #expect(sut.bestStreak(habitID: UUID(), logs: []) == 0)
    }

    @Test("best streak igual a 1 com dia único", .tags(.stats))
    func bestStreakSingleDay() {
        let habitID = UUID()
        let logs = [StatsFixtures.makeLog(habitID: habitID, daysAgo: 0, completed: true)]
        #expect(sut.bestStreak(habitID: habitID, logs: logs) == 1)
    }
}
