import MCDomain
import MCMacros
import MCShared
import SwiftData
import SwiftUI

@Mockable
struct HabitStatsProvider: MCProvider {

    let habitID: UUID

    @Query var allHabits: [HabitModel]
    @Query var allLogs: [HabitLogModel]

    @State var period: StatsPeriod = .month

    @Environment(\.statsCalculator) var stats: StatsCalculatorAPI

    init(habitID: UUID) {
        self.habitID = habitID
    }

    // Sem `navigator`: a volta é o back button do NavigationStack, sem `pop()` programático.

    var habit: HabitModel? {
        allHabits.first { $0.id == habitID }
    }

    var summary: HabitStatsSummary {
        guard let habit else { return .empty }

        let logDTOs = logDTOs
        let habitDTOs = [habit.toDTO()]
        let days = period.days

        return HabitStatsSummary(
            currentStreak: stats.currentStreak(habitID: habitID, logs: logDTOs),
            bestStreak: stats.bestStreak(habitID: habitID, logs: logDTOs),
            rate: stats.completionRate(logs: logDTOs, habits: habitDTOs, days: days),
            days: stats.activity(logs: logDTOs, habits: habitDTOs, days: days).first?.days ?? []
        )
    }

    /// Computed property e não função — o `@Mockable` marca toda função do `Mock` como `mutating`,
    /// e `summary` não poderia chamá-la.
    private var logDTOs: [HabitLogDTO] {
        allLogs.compactMap { log in
            guard log.habit?.id == habitID else { return nil }
            return log.toDTO()
        }
    }
}
