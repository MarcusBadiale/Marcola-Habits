import Foundation
import MCDomain
import SwiftData

@MainActor
enum TestHelpers {
    /// Containers vivos enquanto a suíte roda — sem isso o `ModelContainer` é liberado
    /// logo após `makeContext()` e o SwiftData trapeia (SIGTRAP) no primeiro write.
    private static var containers: [ModelContainer] = []

    static func makeContext() throws -> ModelContext {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        containers.append(container)
        return container.mainContext
    }

    // MARK: - Factories

    static func makeCategory(
        name: String = "Health",
        sortOrder: Int = 0
    ) -> CategoryModel {
        CategoryModel(name: name, icon: "heart.fill", colorHex: "#EF4444", sortOrder: sortOrder)
    }

    static func makeHabit(
        name: String = "Run",
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1,
        targetUnit: String = "",
        isArchived: Bool = false,
        category: CategoryModel? = nil
    ) -> HabitModel {
        HabitModel(
            name: name, icon: "figure.run", colorHex: "#3B82F6",
            frequency: frequency, targetCount: targetCount, targetUnit: targetUnit,
            routine: .anytime, isArchived: isArchived, category: category
        )
    }

    /// Log ancorado em `daysAgo` dias atrás (0 = hoje), já no `startOfDay`.
    static func makeLog(
        habit: HabitModel?,
        daysAgo: Int = 0,
        completed: Bool = true,
        count: Int = 0
    ) -> HabitLogModel {
        let today = Calendar.current.startOfDay(for: .now)
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
        return HabitLogModel(date: date, completed: completed, count: count, habit: habit)
    }

    static var today: Date {
        Calendar.current.startOfDay(for: .now)
    }
}
