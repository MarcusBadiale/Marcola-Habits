import Testing
import SwiftData
@testable import MCDomain

@Suite("SeedDataProvider")
struct SeedDataProviderTests {

    // MARK: - defaultCategories

    @Test("retorna 5 categorias default", .tags(.seed))
    func categoriesCount() {
        let categories = SeedDataProvider.defaultCategories()
        #expect(categories.count == 5)
    }

    @Test("todas as categorias são marcadas como default", .tags(.seed))
    func categoriesAreDefault() {
        let categories = SeedDataProvider.defaultCategories()
        #expect(categories.allSatisfy { $0.isDefault })
    }

    @Test("nomes das categorias são únicos", .tags(.seed))
    func categoryNamesUnique() {
        let categories = SeedDataProvider.defaultCategories()
        let names = categories.map { $0.name }
        #expect(Set(names).count == names.count)
    }

    @Test("categorias têm sortOrder sequencial", .tags(.seed))
    func categoriesSortOrder() {
        let categories = SeedDataProvider.defaultCategories()
        let sorted = categories.sorted { $0.sortOrder < $1.sortOrder }
        for (index, category) in sorted.enumerated() {
            #expect(category.sortOrder == index)
        }
    }

    @Test("categorias têm icon e colorHex não vazios", .tags(.seed))
    func categoriesHaveIconAndColor() {
        let categories = SeedDataProvider.defaultCategories()
        #expect(categories.allSatisfy { !$0.icon.isEmpty && !$0.colorHex.isEmpty })
    }

    // MARK: - defaultTemplates

    @Test("retorna 10 templates default", .tags(.seed))
    func templatesCount() {
        let templates = SeedDataProvider.defaultTemplates()
        #expect(templates.count == 10)
    }

    @Test("nomes dos templates são únicos", .tags(.seed))
    func templateNamesUnique() {
        let templates = SeedDataProvider.defaultTemplates()
        let names = templates.map { $0.name }
        #expect(Set(names).count == names.count)
    }

    @Test("todos os templates têm categoryName referenciando categorias existentes", .tags(.seed))
    func templatesCategoryNamesValid() {
        let categoryNames = Set(SeedDataProvider.defaultCategories().map { $0.name })
        let templates = SeedDataProvider.defaultTemplates()
        #expect(templates.allSatisfy { categoryNames.contains($0.categoryName) })
    }

    @Test("templates têm targetCount maior que zero", .tags(.seed))
    func templatesTargetCountPositive() {
        let templates = SeedDataProvider.defaultTemplates()
        #expect(templates.allSatisfy { $0.defaultTargetCount > 0 })
    }

    // MARK: - populate

    @Test("populate insere categorias e templates no contexto", .tags(.seed))
    @MainActor
    func populateInsertsData() throws {
        let schema = Schema([Category.self, Habit.self, HabitLog.self, HabitTemplate.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        SeedDataProvider.populate(context)
        try context.save()

        let categories = try context.fetch(FetchDescriptor<Category>())
        let templates = try context.fetch(FetchDescriptor<HabitTemplate>())

        #expect(categories.count == 5)
        #expect(templates.count == 10)
    }
}
