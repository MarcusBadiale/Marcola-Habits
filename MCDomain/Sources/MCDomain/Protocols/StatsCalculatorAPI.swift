import Foundation

public protocol StatsCalculatorAPI: Sendable {
    func currentStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int
    func bestStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int
    func weeklyRate(totalHabits: Int, completedToday: Int, daysInWeek: Int) -> Double
    func heatmap(logs: [HabitLogDTO], days: Int) -> [Date: Double]
}
