import Testing
import Foundation
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

    // MARK: - defaultHabits

    @Test("retorna 6 hábitos default", .tags(.seed))
    func habitsCount() {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)
        #expect(habits.count == 6)
    }

    @Test("nomes dos hábitos são únicos", .tags(.seed))
    func habitNamesUnique() {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)
        let names = habits.map { $0.name }
        #expect(Set(names).count == names.count)
    }

    @Test("todos os hábitos têm categoria", .tags(.seed))
    func habitsHaveCategory() {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)
        #expect(habits.allSatisfy { $0.category != nil })
    }

    // MARK: - defaultLogs

    @Test("gera logs para todos os hábitos", .tags(.seed))
    func logsGeneratedForAllHabits() {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)
        let logs = SeedDataProvider.defaultLogs(for: habits)
        let habitsWithLogs = Set(logs.compactMap { $0.habit?.name })
        #expect(habitsWithLogs.count == habits.count)
    }

    @Test("todos os logs têm referência ao hábito", .tags(.seed))
    func logsHaveHabitReference() {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)
        let logs = SeedDataProvider.defaultLogs(for: habits)
        #expect(logs.allSatisfy { $0.habit != nil })
    }

    @Test("logs cobrem ao menos 90 dias — o maior recorte da tela de Stats", .tags(.seed))
    func logsCoverNinetyDays() throws {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)
        let logs = SeedDataProvider.defaultLogs(for: habits)

        let oldest = try #require(logs.map(\.date).min())
        let today = Calendar.current.startOfDay(for: .now)
        let span = try #require(Calendar.current.dateComponents([.day], from: oldest, to: today).day)

        #expect(span >= 90)
    }

    @Test("logs são determinísticos entre chamadas", .tags(.seed))
    func logsAreDeterministic() {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)

        // Comparar por (hábito, data, completed): os `id` são UUID novos a cada chamada.
        let fingerprint = { (logs: [HabitLogModel]) in
            logs.map { "\($0.habit?.name ?? "")|\($0.date.timeIntervalSince1970)|\($0.completed)" }
        }

        #expect(fingerprint(SeedDataProvider.defaultLogs(for: habits))
                == fingerprint(SeedDataProvider.defaultLogs(for: habits)))
    }

    @Test("hábitos do seed são anteriores ao histórico gerado", .tags(.seed))
    func habitsAreBackdatedBeforeHistory() {
        let categories = SeedDataProvider.defaultCategories()
        let habits = SeedDataProvider.defaultHabits(categories: categories)
        let today = Calendar.current.startOfDay(for: .now)

        #expect(habits.allSatisfy { habit in
            let days = Calendar.current.dateComponents([.day], from: habit.createdAt, to: today).day ?? 0
            return days >= SeedDataProvider.historyDays
        })
    }

    // MARK: - populate

    @Test("populate insere categorias, templates, hábitos e logs no contexto", .tags(.seed))
    @MainActor
    func populateInsertsData() throws {
        let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        SeedDataProvider.populate(context)
        try context.save()

        let categories = try context.fetch(FetchDescriptor<CategoryModel>())
        let templates = try context.fetch(FetchDescriptor<HabitTemplateModel>())
        let habits = try context.fetch(FetchDescriptor<HabitModel>())
        let logs = try context.fetch(FetchDescriptor<HabitLogModel>())

        #expect(categories.count == 5)
        #expect(templates.count == 10)
        #expect(habits.count == 6)
        #expect(logs.count > 0)
    }
}
