import Foundation
import MCDomain

/// Dublê de `StatsCalculatorAPI` — registra as chamadas e devolve valores fixos.
/// `@unchecked Sendable` porque o protocolo é `Sendable` e o spy guarda estado mutável.
final class SpyStatsCalculator: StatsCalculatorAPI, @unchecked Sendable {

    // MARK: - Chamadas

    var currentStreakCalls: [(habitID: UUID, logs: [HabitLogDTO])] = []
    var bestStreakCalls: [(habitID: UUID, logs: [HabitLogDTO])] = []
    var completionRateCalls: [(logs: [HabitLogDTO], habits: [HabitDTO], days: Int)] = []
    var completionRatesCalls: [(logs: [HabitLogDTO], habits: [HabitDTO], days: Int)] = []
    var activityCalls: [(logs: [HabitLogDTO], habits: [HabitDTO], days: Int)] = []

    // MARK: - Stubs

    var stubbedCurrentStreak = 0
    var stubbedCurrentStreakByHabit: [UUID: Int] = [:]
    var stubbedBestStreak = 0
    /// Permite testar a agregação `max` do melhor streak global.
    var stubbedBestStreakByHabit: [UUID: Int] = [:]
    var stubbedCompletionRate: Double = 0
    var stubbedCompletionRates: [UUID: Double] = [:]
    /// Quando setado, `activity` devolve uma linha por hábito recebido com estes dias.
    var stubbedActivityDays: [DayActivityDTO] = []
    /// Quando não vazio, tem precedência sobre `stubbedActivityDays`.
    var stubbedActivity: [HabitActivityDTO] = []

    // MARK: - StatsCalculatorAPI

    func currentStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int {
        currentStreakCalls.append((habitID, logs))
        return stubbedCurrentStreakByHabit[habitID] ?? stubbedCurrentStreak
    }

    func bestStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int {
        bestStreakCalls.append((habitID, logs))
        return stubbedBestStreakByHabit[habitID] ?? stubbedBestStreak
    }

    func completionRate(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> Double {
        completionRateCalls.append((logs, habits, days))
        return stubbedCompletionRate
    }

    func completionRates(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [UUID: Double] {
        completionRatesCalls.append((logs, habits, days))
        return stubbedCompletionRates
    }

    func activity(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [HabitActivityDTO] {
        activityCalls.append((logs, habits, days))
        guard stubbedActivity.isEmpty else { return stubbedActivity }
        return habits.map { HabitActivityDTO(habitID: $0.id, days: stubbedActivityDays) }
    }
}
