import Foundation

public extension HabitLog {
    func toDTO() -> HabitLogDTO {
        HabitLogDTO(
            id: id,
            habitID: habit?.id ?? UUID(),
            date: date,
            completed: completed,
            count: count,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
