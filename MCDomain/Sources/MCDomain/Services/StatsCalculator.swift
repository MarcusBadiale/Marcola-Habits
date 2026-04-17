import Foundation

public struct StatsCalculator: StatsCalculatorAPI {

    public init() {}

    /// Conta dias consecutivos completados para trás a partir de hoje (ou ontem se hoje ainda não foi completado).
    public func currentStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int {
        let completedDates = completedDaySet(habitID: habitID, logs: logs)
        guard !completedDates.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Começa em hoje; se hoje não foi completado, testa a partir de ontem
        var checkDate = completedDates.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)!

        var streak = 0
        while completedDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    /// Maior sequência consecutiva de dias completados no histórico.
    public func bestStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int {
        let completedDates = completedDaySet(habitID: habitID, logs: logs)
        guard !completedDates.isEmpty else { return 0 }

        let sorted = completedDates.sorted()
        let calendar = Calendar.current

        var best = 1
        var current = 1

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            if let diff = calendar.dateComponents([.day], from: prev, to: curr).day, diff == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    /// Taxa de conclusão simples: completedToday / totalHabits. Retorna 0 se totalHabits == 0.
    public func weeklyRate(totalHabits: Int, completedToday: Int, daysInWeek: Int) -> Double {
        guard totalHabits > 0 else { return 0.0 }
        return Double(completedToday) / Double(totalHabits)
    }

    /// Mapa de [Date: Double] com a taxa de completion (0.0–1.0) por dia nos últimos `days` dias.
    /// Dias sem nenhum log registrado ficam ausentes do dicionário.
    public func heatmap(logs: [HabitLogDTO], days: Int) -> [Date: Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Agrupa logs por dia
        var byDay: [Date: (total: Int, completed: Int)] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            let cutoff = calendar.date(byAdding: .day, value: -(days - 1), to: today)!
            guard day >= cutoff && day <= today else { continue }
            var entry = byDay[day, default: (0, 0)]
            entry.total += 1
            if log.completed { entry.completed += 1 }
            byDay[day] = entry
        }

        return byDay.reduce(into: [:]) { result, pair in
            let (day, counts) = pair
            result[day] = counts.total > 0 ? Double(counts.completed) / Double(counts.total) : 0.0
        }
    }

    // MARK: - Private helpers

    private func completedDaySet(habitID: UUID, logs: [HabitLogDTO]) -> Set<Date> {
        let calendar = Calendar.current
        return Set(
            logs
                .filter { $0.habitID == habitID && $0.completed }
                .map { calendar.startOfDay(for: $0.date) }
        )
    }
}
