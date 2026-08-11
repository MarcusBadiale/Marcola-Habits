import Foundation
@testable import MCDomain

/// Factories compartilhados pelas suítes do `StatsCalculator`.
enum StatsFixtures {

    static var today: Date {
        Calendar.current.startOfDay(for: .now)
    }

    /// `startOfDay` de hoje menos `daysAgo`. Aceita valor negativo para gerar data futura.
    static func day(_ daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
    }

    static func makeLog(habitID: UUID, daysAgo: Int, completed: Bool = true) -> HabitLogDTO {
        HabitLogDTO(
            id: UUID(),
            habitID: habitID,
            date: day(daysAgo),
            completed: completed,
            count: completed ? 1 : 0
        )
    }

    static func makeHabit(
        id: UUID = UUID(),
        name: String = "Habit",
        frequency: HabitFrequency = .daily,
        isArchived: Bool = false
    ) -> HabitDTO {
        HabitDTO(
            id: id,
            name: name,
            icon: "star.fill",
            frequency: frequency,
            isArchived: isArchived
        )
    }

    /// Um log completo em cada dia do intervalo `0..<days` (hoje inclusive).
    static func completeEveryDay(habitID: UUID, days: Int) -> [HabitLogDTO] {
        (0..<days).map { makeLog(habitID: habitID, daysAgo: $0) }
    }

    /// Quantos dias atrás caiu a última ocorrência daquele dia da semana — sempre em `0...6`.
    /// É o que deixa os testes de `.specificDays` independentes do dia em que a suíte roda.
    static func daysAgoOfLastOccurrence(of weekday: Weekday) -> Int {
        let todayWeekday = Calendar.current.component(.weekday, from: today)
        return (todayWeekday - weekday.rawValue + 7) % 7
    }

    /// O dia da semana de `hoje - daysAgo`.
    static func weekday(daysAgo: Int) -> Weekday? {
        Weekday(rawValue: Calendar.current.component(.weekday, from: day(daysAgo)))
    }

    /// Os `daysAgo` do período que caem nos dias da semana pedidos — uma rotina fixa
    /// (ex: seg/qua/sex) ancorada no calendário, e não em offsets crus a partir de hoje.
    static func daysAgo(matching weekdays: Set<Weekday>, withinLastDays days: Int) -> [Int] {
        (0..<days).filter { weekday(daysAgo: $0).map(weekdays.contains) ?? false }
    }

    /// O dia da semana de hoje, para montar `.specificDays` que casa (ou não) com o período.
    static var todayWeekday: Weekday {
        Weekday(rawValue: Calendar.current.component(.weekday, from: today))!
    }

    /// O dia da semana de amanhã — útil para montar um `.specificDays` que NÃO inclui hoje.
    static var tomorrowWeekday: Weekday {
        let raw = Calendar.current.component(.weekday, from: today) % 7 + 1
        return Weekday(rawValue: raw)!
    }
}
