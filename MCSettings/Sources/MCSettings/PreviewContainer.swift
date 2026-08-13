import MCDomain
import SwiftData

enum PreviewContainer {
    @MainActor
    static func make() -> ModelContainer {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        SeedDataProvider.populate(container.mainContext)
        return container
    }
}
