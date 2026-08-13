import MCDomain
import MCMacros
import MCShared
import SwiftData
import SwiftUI

@Mockable
struct ArchivedHabitsProvider: MCProvider {

    // Sem predicate no @Query — o recorte vive em `archivedHabits`, que é o que o `.Mock` testa.
    @Query var allHabits: [HabitModel]

    /// Guarda o `UUID` e não o `HabitModel`: segurar o modelo atravessando o diálogo de
    /// confirmação é como se acaba com uma referência invalidada na mão.
    @State var pendingDeletionID: UUID? = nil

    @Environment(\.modelContext) var modelContext: ModelContext

    var archivedHabits: [HabitModel] {
        allHabits
            .filter(\.isArchived)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var isEmpty: Bool { archivedHabits.isEmpty }

    var pendingDeletion: HabitModel? {
        archivedHabits.first { $0.id == pendingDeletionID }
    }

    var isConfirmingDelete: Bool { pendingDeletion != nil }

    func logCount(for habit: HabitModel) -> Int { habit.logs.count }

    /// Simétrico ao `HabitDetailProvider.archiveHabit()` do MCHome.
    func unarchive(_ habit: HabitModel) {
        habit.isArchived = false
        habit.updatedAt = Date.now
        try? modelContext.save()
    }

    func requestDelete(_ habit: HabitModel) { pendingDeletionID = habit.id }

    func cancelDelete() { pendingDeletionID = nil }

    /// `HabitModel.logs` tem `deleteRule: .cascade`, então isto apaga os check-ins junto — daí a
    /// confirmação obrigatória. O `save()` acontece na mesma ação porque as outras abas estão
    /// montadas e podem reavaliar `body` na mesma volta do run loop.
    func confirmDelete() {
        guard let habit = pendingDeletion else { return }
        modelContext.delete(habit)
        pendingDeletionID = nil
        try? modelContext.save()
    }
}
