import Foundation

public struct HabitTemplateDTO: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var categoryName: String
    public var defaultFrequency: HabitFrequency
    public var defaultTargetCount: Int
    public var defaultTargetUnit: String

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        categoryName: String,
        defaultFrequency: HabitFrequency = .daily,
        defaultTargetCount: Int = 1,
        defaultTargetUnit: String = ""
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.categoryName = categoryName
        self.defaultFrequency = defaultFrequency
        self.defaultTargetCount = defaultTargetCount
        self.defaultTargetUnit = defaultTargetUnit
    }
}
