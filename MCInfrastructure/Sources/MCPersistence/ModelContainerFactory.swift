import SwiftData
import MCDomain

public enum ModelContainerFactory {

    public static func makeProduction() throws -> ModelContainer {
        let schema = Schema([Category.self, Habit.self, HabitLog.self, HabitTemplate.self])
        let config = ModelConfiguration(schema: schema)
        return try ModelContainer(for: schema, configurations: config)
    }

    public static func makeInMemory() throws -> ModelContainer {
        let schema = Schema([Category.self, Habit.self, HabitLog.self, HabitTemplate.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    @MainActor
    public static func makeSeeded() throws -> ModelContainer {
        let container = try makeInMemory()
        SeedDataProvider.populate(container.mainContext)
        return container
    }
}
