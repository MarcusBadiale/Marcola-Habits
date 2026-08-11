import Foundation

/// Helpers de janela de tempo compartilhados por `+Completion` e `+Activity`.
/// São `internal` (e não `private`) de propósito: `private` numa extensão limita a visibilidade ao
/// arquivo, e estes helpers precisam ser vistos pelos dois arquivos de extensão.
extension StatsCalculator {

    /// Dias (`startOfDay`) do período, do mais antigo até hoje. Vazio quando `days <= 0`.
    func periodDays(days: Int) -> [Date] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<days).reversed().compactMap { offset in
            // Re-normaliza depois do `byAdding`: numa transição de DST em que meia-noite não existe,
            // o resultado sai 01:00 e a data deixaria de casar com o `startOfDay` dos logs.
            calendar.date(byAdding: .day, value: -offset, to: today)
                .map { calendar.startOfDay(for: $0) }
        }
    }

    /// Dias completados por hábito. O `Set` deduplica dois logs completados no mesmo dia.
    func completedDaysByHabit(logs: [HabitLogDTO]) -> [UUID: Set<Date>] {
        let calendar = Calendar.current
        return logs.reduce(into: [:]) { result, log in
            guard log.completed else { return }
            result[log.habitID, default: []].insert(calendar.startOfDay(for: log.date))
        }
    }

    /// Agrupa os dias do período por semana do calendário, preservando a ordem.
    /// As semanas das bordas do período vêm parciais — é isso que o `weeklyTarget` pró-rateia.
    func weekBuckets(_ period: [Date]) -> [[Date]] {
        let calendar = Calendar.current
        var buckets: [[Date]] = []
        var currentWeekStart: Date?

        for day in period {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start ?? day
            if weekStart == currentWeekStart, !buckets.isEmpty {
                buckets[buckets.count - 1].append(day)
            } else {
                buckets.append([day])
                currentWeekStart = weekStart
            }
        }
        return buckets
    }

    func weekday(of date: Date) -> Weekday? {
        Weekday(rawValue: Calendar.current.component(.weekday, from: date))
    }

    /// O hábito tinha obrigação *naquele dia específico*?
    /// `.timesPerWeek` não tem — a obrigação dele é da semana, não de um dia.
    func hasObligation(_ frequency: HabitFrequency, on day: Date) -> Bool {
        switch frequency {
        case .daily:
            return true
        case .specificDays(let scheduled):
            return weekday(of: day).map(scheduled.contains) ?? false
        case .timesPerWeek:
            return false
        }
    }

    /// Uma conclusão nesse dia conta como progresso da semana?
    ///
    /// Difere de `hasObligation` apenas no `.timesPerWeek`: como a obrigação é semanal, qualquer dia
    /// serve. Já no `.specificDays`, completar numa terça não paga a segunda que ficou em aberto.
    func countsAsProgress(_ frequency: HabitFrequency, on day: Date) -> Bool {
        switch frequency {
        case .daily, .timesPerWeek:
            return true
        case .specificDays(let scheduled):
            return weekday(of: day).map(scheduled.contains) ?? false
        }
    }
}
