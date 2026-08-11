import Foundation
import MCDomain

/// Dublê de `StatsCalculatorAPI` — registra as chamadas e devolve valores fixos.
/// `@unchecked Sendable` porque o protocolo é `Sendable` e o spy guarda estado mutável.
final class SpyStatsCalculator: StatsCalculatorAPI, @unchecked Sendable {

    var currentStreakCalls: [(habitID: UUID, logs: [HabitLogDTO])] = []
    var bestStreakCalls: [(habitID: UUID, logs: [HabitLogDTO])] = []

    var stubbedCurrentStreak = 0
    var stubbedBestStreak = 0

    func currentStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int {
        currentStreakCalls.append((habitID, logs))
        return stubbedCurrentStreak
    }

    func bestStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int {
        bestStreakCalls.append((habitID, logs))
        return stubbedBestStreak
    }

    func weeklyRate(totalHabits: Int, completedToday: Int, daysInWeek: Int) -> Double { 0 }

    func heatmap(logs: [HabitLogDTO], days: Int) -> [Date: Double] { [:] }
}
