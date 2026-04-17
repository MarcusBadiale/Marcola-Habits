import Testing
import SwiftData
import Foundation
@testable import MCDomain

@Suite("Mappers — @Model -> DTO")
struct MappersTests {

    // MARK: - Category+DTO

    @Test("Category.toDTO() preserva todos os campos", .tags(.domain))
    @MainActor
    func categoryToDTO() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let category = Category(
            name: "Saúde",
            icon: "heart.fill",
            colorHex: "#EF4444",
            sortOrder: 2,
            isDefault: true
        )
        context.insert(category)

        let dto = category.toDTO()

        #expect(dto.id == category.id)
        #expect(dto.name == category.name)
        #expect(dto.icon == category.icon)
        #expect(dto.colorHex == category.colorHex)
        #expect(dto.sortOrder == category.sortOrder)
        #expect(dto.isDefault == category.isDefault)
    }

    // MARK: - Habit+DTO

    @Test("Habit.toDTO() preserva todos os campos", .tags(.domain))
    @MainActor
    func habitToDTO() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let category = Category(name: "Saúde", icon: "heart.fill", colorHex: "#EF4444")
        context.insert(category)

        let habit = Habit(
            name: "Correr",
            icon: "figure.run",
            colorHex: "#3B82F6",
            frequency: .specificDays([.monday, .wednesday, .friday]),
            targetCount: 30,
            targetUnit: "minutos",
            routine: .morning,
            category: category
        )
        context.insert(habit)

        let dto = habit.toDTO()

        #expect(dto.id == habit.id)
        #expect(dto.name == habit.name)
        #expect(dto.icon == habit.icon)
        #expect(dto.colorHex == habit.colorHex)
        #expect(dto.frequency == habit.frequency)
        #expect(dto.targetCount == habit.targetCount)
        #expect(dto.targetUnit == habit.targetUnit)
        #expect(dto.routine == habit.routine)
        #expect(dto.isArchived == habit.isArchived)
        #expect(dto.categoryID == category.id)
        #expect(dto.templateID == nil)
    }

    @Test("Habit.toDTO() com category nil resulta em categoryID nil", .tags(.domain))
    @MainActor
    func habitToDTONilCategory() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let habit = Habit(name: "Meditar", icon: "brain.head.profile")
        context.insert(habit)

        let dto = habit.toDTO()

        #expect(dto.categoryID == nil)
    }

    // MARK: - HabitLog+DTO

    @Test("HabitLog.toDTO() preserva todos os campos", .tags(.domain))
    @MainActor
    func habitLogToDTO() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let habit = Habit(name: "Meditar", icon: "brain.head.profile")
        context.insert(habit)

        let today = Date.now
        let log = HabitLog(date: today, completed: true, count: 1, note: "boa sessão", habit: habit)
        context.insert(log)

        let dto = log.toDTO()

        #expect(dto.id == log.id)
        #expect(dto.habitID == habit.id)
        #expect(dto.completed == log.completed)
        #expect(dto.count == log.count)
        #expect(dto.note == log.note)
    }

    // MARK: - Helpers

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Category.self, Habit.self, HabitLog.self, HabitTemplate.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
}
