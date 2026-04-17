import Foundation
import SwiftData

@Model
public final class HabitTemplate {
    public var id: UUID
    public var name: String
    public var icon: String
    public var categoryName: String
    public var defaultFrequencyType: FrequencyType
    public var defaultFrequencyDays: [Int]
    public var defaultFrequencyTimesPerWeek: Int
    public var defaultTargetCount: Int
    public var defaultTargetUnit: String

    public var defaultFrequency: HabitFrequency {
        get {
            switch defaultFrequencyType {
            case .daily: .daily
            case .specificDays: .specificDays(Set(defaultFrequencyDays.compactMap(Weekday.init(rawValue:))))
            case .timesPerWeek: .timesPerWeek(defaultFrequencyTimesPerWeek)
            }
        }
        set {
            switch newValue {
            case .daily:
                defaultFrequencyType = .daily
                defaultFrequencyDays = []
                defaultFrequencyTimesPerWeek = 0
            case .specificDays(let days):
                defaultFrequencyType = .specificDays
                defaultFrequencyDays = days.map(\.rawValue).sorted()
                defaultFrequencyTimesPerWeek = 0
            case .timesPerWeek(let times):
                defaultFrequencyType = .timesPerWeek
                defaultFrequencyDays = []
                defaultFrequencyTimesPerWeek = times
            }
        }
    }

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
        self.defaultTargetCount = defaultTargetCount
        self.defaultTargetUnit = defaultTargetUnit

        switch defaultFrequency {
        case .daily:
            self.defaultFrequencyType = .daily
            self.defaultFrequencyDays = []
            self.defaultFrequencyTimesPerWeek = 0
        case .specificDays(let days):
            self.defaultFrequencyType = .specificDays
            self.defaultFrequencyDays = days.map(\.rawValue).sorted()
            self.defaultFrequencyTimesPerWeek = 0
        case .timesPerWeek(let times):
            self.defaultFrequencyType = .timesPerWeek
            self.defaultFrequencyDays = []
            self.defaultFrequencyTimesPerWeek = times
        }
    }
}
