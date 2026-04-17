import Foundation

public struct HabitLogDTO: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var habitID: UUID
    public var date: Date
    public var completed: Bool
    public var count: Int
    public var note: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        habitID: UUID,
        date: Date,
        completed: Bool = false,
        count: Int = 0,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.completed = completed
        self.count = count
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
