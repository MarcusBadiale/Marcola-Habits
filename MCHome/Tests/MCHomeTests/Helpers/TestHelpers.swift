import MCDomain
import SwiftData

@MainActor
enum TestHelpers {
    static func makeContext() throws -> ModelContext {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return container.mainContext
    }
}
