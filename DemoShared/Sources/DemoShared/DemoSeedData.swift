import MCDomain
import MCShared
import SwiftData
import Foundation

@MainActor
public enum DemoSeedData {

    public static func populate(_ context: ModelContext) {
        SeedDataProvider.populate(context)
    }

    public static func makeContainer() -> ModelContainer {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            populate(container.mainContext)
            return container
        } catch {
            fatalError("Failed to create demo container: \(error)")
        }
    }
}
