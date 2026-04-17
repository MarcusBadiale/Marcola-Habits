import Foundation

public enum HabitFrequency: Codable, Hashable, Sendable {
    case daily
    case specificDays(Set<Weekday>)
    case timesPerWeek(Int)

    public func isScheduled(for date: Date) -> Bool {
        switch self {
        case .daily:
            return true
        case .specificDays(let days):
            let weekday = Calendar.current.component(.weekday, from: date)
            guard let day = Weekday(rawValue: weekday) else { return false }
            return days.contains(day)
        case .timesPerWeek:
            return true
        }
    }
}
