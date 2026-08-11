import Foundation

public extension StatsCalculator {

    /// Razão agregada do período: Σdone / Σtarget somados semana a semana, sobre todos os hábitos.
    ///
    /// Não é a média das taxas individuais. Hábito A diário 7/7 + hábito B só-segunda 0/1 dá 0,875
    /// aqui e 0,5 na média de `completionRates` — os dois números são corretos e não somam entre si.
    func completionRate(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> Double {
        let totals = weeklyTotals(logs: logs, habits: habits, days: days).values
        let target = totals.reduce(0) { $0 + $1.target }
        let done = totals.reduce(0) { $0 + $1.done }

        guard target > 0 else { return 0 }
        return done / target
    }

    /// A mesma métrica por hábito, numa única passada. Hábito sem nada agendado no período vira 0.
    func completionRates(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [UUID: Double] {
        weeklyTotals(logs: logs, habits: habits, days: days).mapValues { totals in
            totals.target > 0 ? totals.done / totals.target : 0
        }
    }
}

private extension StatsCalculator {

    /// `target` e `done` por hábito, somados semana a semana.
    ///
    /// `min(done, target)` clampa overachievement, então nenhuma razão passa de 1.0.
    ///
    /// Nota sobre as semanas parciais das bordas do período: como o crédito é clampado *por semana*,
    /// concentrar as conclusões numa das semanas não paga a obrigação da outra. Um `.timesPerWeek(3)`
    /// com 3 conclusões numa janela de 7 dias que atravessa duas semanas do calendário não dá 100% —
    /// dá o crédito da semana em que as conclusões caíram. É consequência direta de medir por semana.
    func weeklyTotals(
        logs: [HabitLogDTO],
        habits: [HabitDTO],
        days: Int
    ) -> [UUID: (target: Double, done: Double)] {
        let completedDays = completedDaysByHabit(logs: logs)
        let weeks = weekBuckets(periodDays(days: days))

        return habits.reduce(into: [:]) { result, habit in
            let done = completedDays[habit.id] ?? []
            var totals = (target: 0.0, done: 0.0)

            for week in weeks {
                let target = weeklyTarget(habit.frequency, in: week)
                guard target > 0 else { continue }
                let completed = Double(week.filter {
                    done.contains($0) && countsAsProgress(habit.frequency, on: $0)
                }.count)
                totals.target += target
                totals.done += min(completed, target)
            }

            result[habit.id] = totals
        }
    }

    /// Quantas conclusões o hábito devia ter naquela semana.
    /// Semana parcial (nas bordas do período) é pró-rateada para `.timesPerWeek`.
    func weeklyTarget(_ frequency: HabitFrequency, in week: [Date]) -> Double {
        switch frequency {
        case .daily:
            return Double(week.count)

        case .specificDays(let scheduled):
            return Double(week.filter { day in
                weekday(of: day).map(scheduled.contains) ?? false
            }.count)

        case .timesPerWeek(let times):
            return Double(times) * Double(week.count) / 7.0
        }
    }
}
