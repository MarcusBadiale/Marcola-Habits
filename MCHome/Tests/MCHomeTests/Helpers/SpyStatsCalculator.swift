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

    // Stubs mudos: nenhum provider do MCHome consome estes métodos — quem os exercita é o MCStats,
    // que tem a sua própria cópia do spy, essa sim registrando as chamadas.

    func completionRate(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> Double { 0 }

    func completionRates(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [UUID: Double] { [:] }

    func activity(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [HabitActivityDTO] { [] }
}
