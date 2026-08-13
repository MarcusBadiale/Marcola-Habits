import Foundation
import MCDomain
import Testing
@testable import MCSettings

@Suite("HabitExportBuilder")
struct HabitExportBuilderTests {

    // MARK: - Fixtures

    private static let exportedAt = Date(timeIntervalSince1970: 1_700_000_000)

    /// Os DTOs default carimbam `createdAt`/`updatedAt` com `.now`, que tem precisão maior que a
    /// do formato (milissegundo). Fixar os timestamps num valor alinhado ao milissegundo deixa o
    /// round-trip exato e o teste determinístico.
    private static let stamp = Date(timeIntervalSince1970: 1_699_999_999.5)

    private func makeCategory(name: String = "Health", sortOrder: Int = 0) -> CategoryDTO {
        CategoryDTO(
            name: name, icon: "heart.fill", colorHex: "#EF4444", sortOrder: sortOrder,
            createdAt: Self.stamp, updatedAt: Self.stamp
        )
    }

    private func makeHabit(
        name: String = "Run",
        frequency: HabitFrequency = .daily,
        categoryID: UUID? = nil
    ) -> HabitDTO {
        HabitDTO(
            name: name, icon: "figure.run", colorHex: "#3B82F6",
            frequency: frequency, targetCount: 1, targetUnit: "km",
            routine: .morning, categoryID: categoryID,
            createdAt: Self.stamp, updatedAt: Self.stamp
        )
    }

    private func makeLog(habitID: UUID, daysAgo: Int) -> HabitLogDTO {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Self.exportedAt)!
        return HabitLogDTO(
            habitID: habitID, date: date, completed: true, count: 1,
            createdAt: Self.stamp, updatedAt: Self.stamp
        )
    }

    private func makeEnvelope(
        categories: [CategoryDTO] = [],
        habits: [HabitDTO] = [],
        logs: [HabitLogDTO] = []
    ) -> HabitExportEnvelope {
        HabitExportBuilder.makeEnvelope(
            categories: categories, habits: habits, logs: logs,
            exportedAt: Self.exportedAt, appVersion: "1.0.0 (1)"
        )
    }

    // MARK: - Envelope

    @Test("carimba o schemaVersion corrente")
    func schemaVersion() {
        #expect(makeEnvelope().schemaVersion == 1)
        #expect(HabitExportEnvelope.currentSchemaVersion == 1)
    }

    @Test("preserva as três coleções")
    func contagens() {
        let habit = makeHabit()
        let envelope = makeEnvelope(
            categories: [makeCategory()],
            habits: [habit],
            logs: [makeLog(habitID: habit.id, daysAgo: 0), makeLog(habitID: habit.id, daysAgo: 1)]
        )

        #expect(envelope.categories.count == 1)
        #expect(envelope.habits.count == 1)
        #expect(envelope.logs.count == 2)
        #expect(envelope.exportedAt == Self.exportedAt)
        #expect(envelope.appVersion == "1.0.0 (1)")
    }

    @Test("ordena categorias por sortOrder, hábitos por nome e logs por data")
    func ordenacao() {
        let habit = makeHabit()
        let envelope = makeEnvelope(
            categories: [makeCategory(name: "B", sortOrder: 2), makeCategory(name: "A", sortOrder: 1)],
            habits: [makeHabit(name: "Zebra"), makeHabit(name: "Alpha")],
            logs: [makeLog(habitID: habit.id, daysAgo: 0), makeLog(habitID: habit.id, daysAgo: 5)]
        )

        #expect(envelope.categories.map(\.name) == ["A", "B"])
        #expect(envelope.habits.map(\.name) == ["Alpha", "Zebra"])
        #expect(envelope.logs[0].date < envelope.logs[1].date)
    }

    // MARK: - Encode

    @Test("dois encodes dos mesmos dados produzem bytes idênticos")
    func saidaDeterministica() throws {
        let envelope = makeEnvelope(categories: [makeCategory()], habits: [makeHabit()])

        let first = try HabitExportBuilder.encode(envelope)
        let second = try HabitExportBuilder.encode(envelope)

        #expect(first == second)
    }

    @Test("datas saem em ISO8601 UTC com milissegundos")
    func datasISO8601ComMilissegundos() throws {
        let data = try HabitExportBuilder.encode(makeEnvelope())
        let json = try #require(String(data: data, encoding: .utf8))

        // 1_700_000_000 = 2023-11-14T22:13:20Z
        #expect(json.contains("2023-11-14T22:13:20.000Z"))
    }

    /// O `.iso8601` padrão do JSONEncoder trunca no segundo, o que empataria dois `updatedAt`
    /// da mesma segundo no last-write-wins da Fase 7. Este teste é o que trava essa regressão.
    @Test("milissegundos sobrevivem ao round-trip")
    func milissegundosPreservados() throws {
        let precise = Date(timeIntervalSince1970: 1_700_000_000.125)
        let category = CategoryDTO(
            name: "Health", icon: "heart.fill", colorHex: "#EF4444",
            createdAt: precise, updatedAt: precise
        )

        let data = try HabitExportBuilder.encode(makeEnvelope(categories: [category]))
        let decoded = try HabitExportBuilder.makeDecoder()
            .decode(HabitExportEnvelope.self, from: data)

        #expect(decoded.categories.first?.updatedAt == precise)
    }

    // MARK: - Round-trip

    @Test("round-trip preserva um hábito com frequência de dias específicos")
    func roundTripFrequenciaComValorAssociado() throws {
        let category = makeCategory()
        let habit = makeHabit(
            name: "Gym",
            frequency: .specificDays([.tuesday, .thursday]),
            categoryID: category.id
        )
        let log = makeLog(habitID: habit.id, daysAgo: 3)

        let data = try HabitExportBuilder.encode(
            makeEnvelope(categories: [category], habits: [habit], logs: [log])
        )
        let decoded = try HabitExportBuilder.makeDecoder()
            .decode(HabitExportEnvelope.self, from: data)

        #expect(decoded.schemaVersion == 1)
        #expect(decoded.categories == [category])
        #expect(decoded.habits == [habit])
        #expect(decoded.logs == [log])
        #expect(decoded.habits.first?.frequency == .specificDays([.tuesday, .thursday]))
    }

    @Test("round-trip preserva timesPerWeek")
    func roundTripTimesPerWeek() throws {
        let habit = makeHabit(name: "Read", frequency: .timesPerWeek(3))

        let data = try HabitExportBuilder.encode(makeEnvelope(habits: [habit]))
        let decoded = try HabitExportBuilder.makeDecoder()
            .decode(HabitExportEnvelope.self, from: data)

        #expect(decoded.habits.first?.frequency == .timesPerWeek(3))
    }
}
