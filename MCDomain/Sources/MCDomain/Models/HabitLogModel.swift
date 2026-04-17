import Foundation
import SwiftData
import MCShared

@Model
public final class HabitLogModel {
    public var id: UUID
    public var date: Date
    public var completed: Bool
    public var count: Int
    public var note: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var syncStatus: SyncStatus

    public var habit: HabitModel?

    public init(
        id: UUID = UUID(),
        date: Date,
        completed: Bool = false,
        count: Int = 0,
        note: String? = nil,
        habit: HabitModel? = nil
    ) {
        self.id = id
        self.date = date.startOfDay
        self.completed = completed
        self.count = count
        self.note = note
        self.habit = habit
        self.createdAt = .now
        self.updatedAt = .now
        self.syncStatus = .pendingUpload
    }
}
