import Foundation

public struct HabitDTO: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var frequency: HabitFrequency
    public var targetCount: Int
    public var targetUnit: String
    public var routine: Routine
    public var isArchived: Bool
    public var categoryID: UUID?
    public var templateID: UUID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String = "#3B82F6",
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1,
        targetUnit: String = "",
        routine: Routine = .anytime,
        isArchived: Bool = false,
        categoryID: UUID? = nil,
        templateID: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.frequency = frequency
        self.targetCount = targetCount
        self.targetUnit = targetUnit
        self.routine = routine
        self.isArchived = isArchived
        self.categoryID = categoryID
        self.templateID = templateID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
