import MCDomain
import MCShared
import SwiftData
import Foundation

@MainActor
public enum DemoSeedData {

    public static func populate(_ context: ModelContext) {
        SeedDataProvider.populate(context)
        insertArchivedHabits(context)
    }

    /// O `SeedDataProvider` (MCDomain) não cria nenhum hábito arquivado, e mexer nele quebraria as
    /// asserções de contagem em `SeedDataProviderTests`. Como a tela de arquivados só é exercitada
    /// nos Demo Apps, o hábito arquivado é adicionado aqui — invisível pras outras features, que
    /// todas filtram `!isArchived`.
    private static func insertArchivedHabits(_ context: ModelContext) {
        let categories = (try? context.fetch(FetchDescriptor<CategoryModel>())) ?? []
        let health = categories.first { $0.name == "Saúde" }

        let archived = HabitModel(
            name: "Correr 5km",
            icon: "figure.run",
            colorHex: "#EF4444",
            frequency: .specificDays([.tuesday, .thursday]),
            targetCount: 5,
            targetUnit: "km",
            routine: .morning,
            isArchived: true,
            category: health
        )
        context.insert(archived)
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
