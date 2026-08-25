import Foundation
import MCDomain
import SwiftData
import Testing
@testable import MCSettings

@Suite("ArchivedHabitsProvider")
struct ArchivedHabitsProviderTests {

    @MainActor
    private func makeSUT(
        habits: [HabitModel],
        pendingDeletionID: UUID? = nil
    ) throws -> ArchivedHabitsProvider.Mock {
        ArchivedHabitsProvider.Mock(
            allHabits: habits,
            modelContext: try TestHelpers.makeContext(),
            pendingDeletionID: pendingDeletionID
        )
    }

    // MARK: - Recorte

    @Test @MainActor
    func mostraSoOsArquivados() throws {
        let sut = try makeSUT(habits: [
            TestHelpers.makeHabit(name: "Run", isArchived: true),
            TestHelpers.makeHabit(name: "Read"),
            TestHelpers.makeHabit(name: "Gym", isArchived: true),
        ])

        let todosArquivados = sut.archivedHabits.allSatisfy(\.isArchived)

        #expect(sut.archivedHabits.count == 2)
        #expect(todosArquivados)
        #expect(sut.isEmpty == false)
    }

    @Test @MainActor
    func vazioQuandoNadaFoiArquivado() throws {
        let sut = try makeSUT(habits: [TestHelpers.makeHabit(name: "Run")])

        #expect(sut.isEmpty)
        #expect(sut.archivedHabits.isEmpty)
    }

    @Test @MainActor
    func ordenaDoArquivadoMaisRecenteProMaisAntigo() throws {
        let antigo = TestHelpers.makeHabit(name: "Antigo", isArchived: true)
        let recente = TestHelpers.makeHabit(name: "Recente", isArchived: true)
        antigo.updatedAt = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        recente.updatedAt = .now

        let sut = try makeSUT(habits: [antigo, recente])

        #expect(sut.archivedHabits.map(\.name) == ["Recente", "Antigo"])
    }

    @Test @MainActor
    func contaOsLogsDoHabito() throws {
        let habit = TestHelpers.makeHabit(name: "Run", isArchived: true)
        habit.logs = [
            TestHelpers.makeLog(habit: habit, daysAgo: 0),
            TestHelpers.makeLog(habit: habit, daysAgo: 1),
        ]

        let sut = try makeSUT(habits: [habit])

        #expect(sut.logCount(for: habit) == 2)
    }

    // MARK: - Desarquivar

    @Test @MainActor
    func desarquivarLimpaAFlagEMexeNoUpdatedAt() throws {
        let habit = TestHelpers.makeHabit(name: "Run", isArchived: true)
        habit.updatedAt = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        let antes = habit.updatedAt

        let sut = try makeSUT(habits: [habit])
        sut.unarchive(habit)

        #expect(habit.isArchived == false)
        #expect(habit.updatedAt > antes)
    }

    // MARK: - Ciclo de delete

    @Test @MainActor
    func pedirDeleteMarcaOPendente() throws {
        let habit = TestHelpers.makeHabit(name: "Run", isArchived: true)
        var sut = try makeSUT(habits: [habit])

        #expect(sut.isConfirmingDelete == false)

        sut.requestDelete(habit)

        #expect(sut.pendingDeletionID == habit.id)
        #expect(sut.pendingDeletion?.id == habit.id)
        #expect(sut.isConfirmingDelete)
    }

    @Test @MainActor
    func cancelarLimpaOPendente() throws {
        let habit = TestHelpers.makeHabit(name: "Run", isArchived: true)
        var sut = try makeSUT(habits: [habit], pendingDeletionID: habit.id)

        sut.cancelDelete()

        #expect(sut.pendingDeletionID == nil)
        #expect(sut.isConfirmingDelete == false)
    }

    /// Um id que não corresponde a nenhum hábito arquivado não resolve — é o que impede o
    /// diálogo de aparecer sobre um hábito que já saiu da lista.
    @Test @MainActor
    func pendenteDesconhecidoNaoResolve() throws {
        let sut = try makeSUT(
            habits: [TestHelpers.makeHabit(name: "Run", isArchived: true)],
            pendingDeletionID: UUID()
        )

        #expect(sut.pendingDeletion == nil)
        #expect(sut.isConfirmingDelete == false)
    }

    @Test @MainActor
    func confirmarSemPendenteNaoFazNada() throws {
        var sut = try makeSUT(habits: [TestHelpers.makeHabit(name: "Run", isArchived: true)])

        sut.confirmDelete()

        #expect(sut.pendingDeletionID == nil)
        #expect(sut.archivedHabits.count == 1)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil))
    @MainActor
    func confirmarRemoveDoContexto() throws {
        let context = try TestHelpers.makeContext()
        let habit = TestHelpers.makeHabit(name: "Run", isArchived: true)
        context.insert(habit)

        var sut = ArchivedHabitsProvider.Mock(
            allHabits: [habit],
            modelContext: context,
            pendingDeletionID: habit.id
        )

        sut.confirmDelete()

        let restantes = try context.fetch(FetchDescriptor<HabitModel>())
        #expect(restantes.isEmpty)
        #expect(sut.pendingDeletionID == nil)
    }
}
