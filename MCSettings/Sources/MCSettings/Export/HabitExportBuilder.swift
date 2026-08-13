import Foundation
import MCDomain

/// Monta e codifica o arquivo de export. Tipo puro — entra DTO, sai `Data`. Sem SwiftData e sem
/// SwiftUI, então é testável direto, sem `ModelContainer` e sem `.Mock`.
enum HabitExportBuilder {

    static func makeEnvelope(
        categories: [CategoryDTO],
        habits: [HabitDTO],
        logs: [HabitLogDTO],
        exportedAt: Date,
        appVersion: String
    ) -> HabitExportEnvelope {
        HabitExportEnvelope(
            exportedAt: exportedAt,
            appVersion: appVersion,
            categories: categories.sorted { $0.sortOrder < $1.sortOrder },
            habits: habits.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
            logs: logs.sorted { $0.date < $1.date }
        )
    }

    static func encode(_ envelope: HabitExportEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        // `sortedKeys` deixa a saída determinística: sem isso, dois exports dos mesmos dados
        // produzem bytes diferentes e o teste de estabilidade vira loteria.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    /// Usado pelos testes de round-trip. O import de verdade é trabalho da Fase 7 — os mappers
    /// `@Model → DTO` são one-way hoje, não existe `fromDTO`.
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }

    /// ISO8601 **com milissegundos**, em UTC.
    ///
    /// O `.iso8601` padrão do `JSONEncoder` trunca no segundo, e isso não é aceitável aqui:
    /// `updatedAt` é o critério de last-write-wins do sync da Fase 7, e duas edições no mesmo
    /// segundo empatariam. Milissegundo é o teto — `Date` guarda mais precisão que isso, então
    /// o round-trip é exato só até o milissegundo.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
