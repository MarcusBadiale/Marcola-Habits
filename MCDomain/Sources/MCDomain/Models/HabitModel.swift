import Foundation
import SwiftData

@Model
public final class HabitModel {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var frequencyType: FrequencyType
    public var frequencyDays: [Int]
    public var frequencyTimesPerWeek: Int
    public var targetCount: Int
    public var targetUnit: String
    public var routine: Routine
    public var isArchived: Bool
    public var templateID: UUID?
    public var createdAt: Date
    public var updatedAt: Date
    public var syncStatus: SyncStatus

    public var category: CategoryModel?

    @Relationship(deleteRule: .cascade, inverse: \HabitLogModel.habit)
    public var logs: [HabitLogModel]

    public var frequency: HabitFrequency {
        get {
            switch frequencyType {
            case .daily: .daily
            case .specificDays: .specificDays(Set(frequencyDays.compactMap(Weekday.init(rawValue:))))
            case .timesPerWeek: .timesPerWeek(frequencyTimesPerWeek)
            }
        }
        set {
            switch newValue {
            case .daily:
                frequencyType = .daily
                frequencyDays = []
                frequencyTimesPerWeek = 0
            case .specificDays(let days):
                frequencyType = .specificDays
                frequencyDays = days.map(\.rawValue).sorted()
                frequencyTimesPerWeek = 0
            case .timesPerWeek(let times):
                frequencyType = .timesPerWeek
                frequencyDays = []
                frequencyTimesPerWeek = times
            }
        }
    }

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
        templateID: UUID? = nil,
        category: CategoryModel? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.targetCount = targetCount
        self.targetUnit = targetUnit
        self.routine = routine
        self.isArchived = isArchived
        self.templateID = templateID
        self.category = category
        self.createdAt = .now
        self.updatedAt = .now
        self.syncStatus = .pendingUpload
        self.logs = []

        switch frequency {
        case .daily:
            self.frequencyType = .daily
            self.frequencyDays = []
            self.frequencyTimesPerWeek = 0
        case .specificDays(let days):
            self.frequencyType = .specificDays
            self.frequencyDays = days.map(\.rawValue).sorted()
            self.frequencyTimesPerWeek = 0
        case .timesPerWeek(let times):
            self.frequencyType = .timesPerWeek
            self.frequencyDays = []
            self.frequencyTimesPerWeek = times
        }
    }

    public func isScheduled(for date: Date) -> Bool {
        frequency.isScheduled(for: date)
    }
}
