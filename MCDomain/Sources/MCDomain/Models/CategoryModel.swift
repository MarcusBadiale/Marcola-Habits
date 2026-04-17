import Foundation
import SwiftData

@Model
public final class CategoryModel {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var sortOrder: Int
    public var isDefault: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var syncStatus: SyncStatus

    @Relationship(deleteRule: .cascade, inverse: \HabitModel.category)
    public var habits: [HabitModel]

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = .now
        self.updatedAt = .now
        self.syncStatus = .pendingUpload
        self.habits = []
    }
}
