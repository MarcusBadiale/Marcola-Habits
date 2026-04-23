import MarcolasPattern
import MCDomain
import MCNavigationAPI
import MCShared
import SwiftData
import SwiftUI

@MCProvider
struct AddHabitProvider {
    @Query(sort: \CategoryModel.sortOrder) var categories: [CategoryModel]
    @Query var templates: [HabitTemplateModel]

    @State var name: String = ""
    @State var icon: String = "star.fill"
    @State var colorHex: String = "#3B82F6"
    @State var selectedCategoryID: UUID? = nil
    @State var frequencyType: FrequencyType = .daily
    @State var selectedDays: Set<Weekday> = []
    @State var timesPerWeek: Int = 3
    @State var targetCount: Int = 1
    @State var targetUnit: String = ""
    @State var routine: Routine = .anytime
    @State var showingTemplates: Bool = false

    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.navigator) var navigator: NavigatorAPI

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var frequency: HabitFrequency {
        switch frequencyType {
        case .daily: .daily
        case .specificDays: .specificDays(selectedDays)
        case .timesPerWeek: .timesPerWeek(timesPerWeek)
        }
    }

    func applyTemplate(_ template: HabitTemplateModel) {
        name = template.name
        icon = template.icon
        targetCount = template.defaultTargetCount
        targetUnit = template.defaultTargetUnit

        switch template.defaultFrequency {
        case .daily:
            frequencyType = .daily
        case .specificDays(let days):
            frequencyType = .specificDays
            selectedDays = days
        case .timesPerWeek(let times):
            frequencyType = .timesPerWeek
            timesPerWeek = times
        }

        if let cat = categories.first(where: { $0.name == template.categoryName }) {
            selectedCategoryID = cat.id
        }
    }

    func save() {
        let category = categories.first { $0.id == selectedCategoryID }
        let habit = HabitModel(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            colorHex: colorHex,
            frequency: frequency,
            targetCount: targetCount,
            targetUnit: targetUnit,
            routine: routine,
            category: category
        )
        modelContext.insert(habit)
        navigator.dismiss()
    }

    func cancel() {
        navigator.dismiss()
    }
}
