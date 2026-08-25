import MCDomain
import MCMacros
import MCNavigationAPI
import MCShared
import MCStatsAPI
import SwiftData
import SwiftUI

@Mockable
struct StatsProvider: MCProvider {

    // @Query sem filtro de propósito: o `.Mock` troca @Query por `var`, então um predicate aqui
    // seria lógica que nenhum teste alcança. O recorte vive em `activeHabits`.
    @Query var allHabits: [HabitModel]
    @Query var allLogs: [HabitLogModel]

    @State var period: StatsPeriod = .month

    @Environment(\.navigator) var navigator: NavigatorAPI
    @Environment(\.statsCalculator) var stats: StatsCalculatorAPI

    // MARK: - Recorte

    var activeHabits: [HabitModel] {
        allHabits
            .filter { !$0.isArchived }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var isEmpty: Bool { activeHabits.isEmpty }

    // MARK: - Agregados

    var summary: StatsSummary {
        let habits = activeHabits
        guard !habits.isEmpty else { return .empty }

        let habitDTOs = habits.map { $0.toDTO() }
        let logDTOs = activeLogDTOs
        let days = period.days

        let rates = stats.completionRates(logs: logDTOs, habits: habitDTOs, days: days)
        let activity = Dictionary(
            stats.activity(logs: logDTOs, habits: habitDTOs, days: days).map { ($0.habitID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return StatsSummary(
            rate: stats.completionRate(logs: logDTOs, habits: habitDTOs, days: days),
            // `bestStreak` filtra por habitID internamente, então recebe a lista completa de logs.
            bestStreak: habits.reduce(0) { best, habit in
                max(best, stats.bestStreak(habitID: habit.id, logs: logDTOs))
            },
            habits: habits.map { habit in
                StatsHabitSummary(
                    habit: habit,
                    streak: stats.currentStreak(habitID: habit.id, logs: logDTOs),
                    rate: rates[habit.id] ?? 0,
                    days: activity[habit.id]?.days ?? []
                )
            }
        )
    }

    // MARK: - Navegação

    func goToHabitStats(_ habit: HabitModel) {
        navigator.push(StatsRoutes.habitStats, params: ["id": habit.id])
    }

    // MARK: - Privados

    /// Logs dos hábitos ativos, já em DTO. Log de hábito arquivado ou órfão fica de fora.
    private var activeLogDTOs: [HabitLogDTO] {
        let ids = Set(allHabits.filter { !$0.isArchived }.map(\.id))
        return allLogs.compactMap { log in
            guard let habitID = log.habit?.id, ids.contains(habitID) else { return nil }
            return log.toDTO()
        }
    }
}
