import Foundation
import MCDomain
import Testing
@testable import MCSettings

@Suite("ExportProvider")
struct ExportProviderTests {

    @MainActor
    private func makeSUT(
        categories: [CategoryModel] = [],
        habits: [HabitModel] = [],
        logs: [HabitLogModel] = []
    ) -> ExportProvider.Mock {
        ExportProvider.Mock(allCategories: categories, allHabits: habits, allLogs: logs)
    }

    @Test @MainActor
    func antesDeConstruirNaoTemDocumento() {
        let sut = makeSUT()

        #expect(sut.isReady == false)
        #expect(sut.sizeDetail == "—")
        #expect(sut.errorMessage == nil)
    }

    @Test @MainActor
    func construirGeraODocumento() {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(category: category)
        var sut = makeSUT(categories: [category], habits: [habit])

        sut.build()

        #expect(sut.isReady)
        #expect(sut.errorMessage == nil)
        #expect(sut.document?.data.isEmpty == false)
        #expect(sut.sizeDetail != "—")
    }

    @Test @MainActor
    func contagensRefletemOsQueries() {
        let category = TestHelpers.makeCategory()
        let habit = TestHelpers.makeHabit(category: category)
        let sut = makeSUT(
            categories: [category],
            habits: [habit],
            logs: [
                TestHelpers.makeLog(habit: habit, daysAgo: 0),
                TestHelpers.makeLog(habit: habit, daysAgo: 1),
            ]
        )

        #expect(sut.categoryCount == 1)
        #expect(sut.habitCount == 1)
        #expect(sut.logCount == 2)
    }

    /// `HabitLogModel.toDTO()` usa `habit?.id ?? UUID()`, então um log órfão exportaria um
    /// `habitID` inventado — diferente a cada export e apontando pra nada.
    @Test @MainActor
    func logOrfaoFicaForaDaContagem() {
        let habit = TestHelpers.makeHabit()
        let sut = makeSUT(
            habits: [habit],
            logs: [
                TestHelpers.makeLog(habit: habit, daysAgo: 0),
                TestHelpers.makeLog(habit: nil, daysAgo: 1),
            ]
        )

        #expect(sut.logCount == 1)
    }

    @Test @MainActor
    func logOrfaoFicaForaDoJSON() throws {
        let habit = TestHelpers.makeHabit()
        var sut = makeSUT(
            habits: [habit],
            logs: [
                TestHelpers.makeLog(habit: habit, daysAgo: 0),
                TestHelpers.makeLog(habit: nil, daysAgo: 1),
            ]
        )

        sut.build()

        let data = try #require(sut.document?.data)
        let envelope = try HabitExportBuilder.makeDecoder()
            .decode(HabitExportEnvelope.self, from: data)

        #expect(envelope.logs.count == 1)
        #expect(envelope.logs.first?.habitID == habit.id)
    }

    @Test @MainActor
    func jsonCarregaCategoriasHabitosELogs() throws {
        let category = TestHelpers.makeCategory(name: "Health")
        let habit = TestHelpers.makeHabit(name: "Run", category: category)
        var sut = makeSUT(
            categories: [category],
            habits: [habit],
            logs: [TestHelpers.makeLog(habit: habit, daysAgo: 0)]
        )

        sut.build()

        let data = try #require(sut.document?.data)
        let envelope = try HabitExportBuilder.makeDecoder()
            .decode(HabitExportEnvelope.self, from: data)

        #expect(envelope.schemaVersion == 1)
        #expect(envelope.categories.map(\.name) == ["Health"])
        #expect(envelope.habits.map(\.name) == ["Run"])
        #expect(envelope.logs.count == 1)
    }

    @Test @MainActor
    func exportarBancoVazioAindaGeraArquivoValido() throws {
        var sut = makeSUT()

        sut.build()

        let data = try #require(sut.document?.data)
        let envelope = try HabitExportBuilder.makeDecoder()
            .decode(HabitExportEnvelope.self, from: data)

        #expect(envelope.categories.isEmpty)
        #expect(envelope.habits.isEmpty)
        #expect(envelope.logs.isEmpty)
    }
}
