import Foundation
import MCDomain

/// Formato do arquivo de export.
///
/// Enquanto o sync da Fase 7 não existe, este é o **único** caminho de saída dos dados — não há
/// backup nenhum além dele.
///
/// `schemaVersion` existe desde a v1 porque a forma do JSON vai mudar: `HabitFrequency` é enum com
/// valores associados, então o `Codable` sintetizado emite `{"specificDays":{"_0":[3,5]}}`, que
/// funciona em round-trip mas não é o que o Postgres vai querer na Fase 7. Quando mudar, é o
/// `schemaVersion` que diz se um arquivo antigo ainda é legível.
struct HabitExportEnvelope: Codable, Hashable, Sendable {

    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportedAt: Date
    let appVersion: String
    let categories: [CategoryDTO]
    let habits: [HabitDTO]
    let logs: [HabitLogDTO]

    init(
        schemaVersion: Int = HabitExportEnvelope.currentSchemaVersion,
        exportedAt: Date,
        appVersion: String,
        categories: [CategoryDTO],
        habits: [HabitDTO],
        logs: [HabitLogDTO]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.categories = categories
        self.habits = habits
        self.logs = logs
    }
}
