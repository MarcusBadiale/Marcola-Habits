import MarcolasPattern
import MCDomain
import MCNavigation
import MCShared
import SwiftData
import SwiftUI

@MCViewModel
struct HabitDetailViewModel {
    let habitID: UUID

    @Query var allHabits: [HabitModel]
    @Query var allLogs: [HabitLogModel]

    @Environment(\.modelContext) var modelContext
    @Environment(Navigator.self) var navigator

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
        var count = 0
        var date = Date.now.startOfDay
        let habitLogs = allLogs.filter { $0.habit?.id == habit.id }
        while true {
            let log = habitLogs.first { $0.date.isInSameDay(date) }
            guard let log, log.completed || log.count >= habit.targetCount else { break }
            count += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }

    var frequencyDescription: String {
        guard let habit else { return "" }
        switch habit.frequency {
        case .daily:
            return "Todos os dias"
        case .specificDays(let days):
            let names = days.sorted(by: { $0.rawValue < $1.rawValue }).map { weekdayName($0) }
            return names.joined(separator: ", ")
        case .timesPerWeek(let times):
            return "\(times)x por semana"
        }
    }

    func archiveHabit() {
        guard let habit else { return }
        habit.isArchived = true
        habit.updatedAt = Date.now
        navigator.pop()
    }

    private func weekdayName(_ day: Weekday) -> String {
        switch day {
        case .sunday: "Dom"
        case .monday: "Seg"
        case .tuesday: "Ter"
        case .wednesday: "Qua"
        case .thursday: "Qui"
        case .friday: "Sex"
        case .saturday: "Sáb"
        }
    }
}
