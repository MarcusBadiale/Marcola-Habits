import MCDomain
import MCMacros
import MCNavigationAPI
import MCShared
import SwiftData
import SwiftUI

@Mockable
struct HabitDetailProvider: MCProvider {
    let habitID: UUID

    @Query var allHabits: [HabitModel]
    @Query var allLogs: [HabitLogModel]

    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.navigator) var navigator: NavigatorAPI
    @Environment(\.statsCalculator) var stats: StatsCalculatorAPI

    init(habitID: UUID) {
        self.habitID = habitID
    }

    var habit: HabitModel? {
        allHabits.first { $0.id == habitID }
    }

    var recentLogs: [HabitLogModel] {
        guard let habit else { return [] }
        return allLogs
            .filter { $0.habit?.id == habit.id }
            .sorted { $0.date > $1.date }
            .prefix(14)
            .map { $0 }
    }

    var currentStreak: Int {
        guard let habit else { return 0 }
        return stats.currentStreak(
            habitID: habit.id,
            logs: allLogs.filter { $0.habit?.id == habit.id }.map { $0.toDTO() }
        )
    }

    var frequencyDescription: String {
        guard let habit else { return "" }
        switch habit.frequency {
        case .daily:
            return "Every day"
        case .specificDays(let days):
            let names = days.sorted(by: { $0.rawValue < $1.rawValue }).map { day -> String in
                switch day {
                case .sunday: "Sun"
                case .monday: "Mon"
                case .tuesday: "Tue"
                case .wednesday: "Wed"
                case .thursday: "Thu"
                case .friday: "Fri"
                case .saturday: "Sat"
                }
            }
            return names.joined(separator: ", ")
        case .timesPerWeek(let times):
            return "\(times)x per week"
        }
    }

    func archiveHabit() {
        guard let habit else { return }
        habit.isArchived = true
        habit.updatedAt = Date.now
        navigator.pop()
    }
}
