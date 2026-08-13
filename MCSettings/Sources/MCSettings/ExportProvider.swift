import MCDomain
import MCMacros
import MCShared
import SwiftData
import SwiftUI

@Mockable
struct ExportProvider: MCProvider {

    @Query var allCategories: [CategoryModel]
    @Query var allHabits: [HabitModel]
    @Query var allLogs: [HabitLogModel]

    @State var document: HabitExportDocument? = nil
    @State var errorMessage: String? = nil

    // Read-only: sem modelContext e sem navigator, igual ao StatsProvider.

    var categoryCount: Int { allCategories.count }
    var habitCount: Int { allHabits.count }
    var logCount: Int { exportableLogDTOs.count }

    var isReady: Bool { document != nil }

    var sizeDetail: String {
        guard let document else { return "—" }
        return document.data.count.formatted(.byteCount(style: .file))
    }

    /// Log órfão fica de fora: `HabitLogModel.toDTO()` faz `habitID: habit?.id ?? UUID()`, então
    /// um log sem hábito exportaria um `habitID` inventado — diferente a cada export, e apontando
    /// pra nada.
    private var exportableLogDTOs: [HabitLogDTO] {
        allLogs.compactMap { $0.habit == nil ? nil : $0.toDTO() }
    }

    /// Chamada no `.task` da View, nunca no `body`: com 91 dias de histórico o encode é centenas
    /// de KB, e refazer isso a cada invalidação seria desperdício visível.
    func build() {
        let envelope = HabitExportBuilder.makeEnvelope(
            categories: allCategories.map { $0.toDTO() },
            habits: allHabits.map { $0.toDTO() },
            logs: exportableLogDTOs,
            exportedAt: .now,
            appVersion: AppVersion.display()
        )

        do {
            document = HabitExportDocument(data: try HabitExportBuilder.encode(envelope))
            errorMessage = nil
        } catch {
            document = nil
            errorMessage = "Could not build the export file."
        }
    }
}
