import Foundation

/// Janela de tempo do seletor das telas de Stats.
///
/// Vive no target Impl (e não no `MCStatsAPI`) porque nenhum módulo de fora precisa dele: o contrato
/// do domínio é `days: Int` e o de rota é `["id": UUID]`. É UI state, pela mesma lógica que põe
/// `selectedDate` em `@State` no `HomeProvider`.
///
/// `rawValue == days` de propósito: se um dia surgir deep link, promover isso pro target API é
/// trivial e não-breaking.
enum StatsPeriod: Int, CaseIterable, Identifiable, Hashable {
    case week = 7
    case month = 30
    case quarter = 90

    var id: Int { rawValue }

    var days: Int { rawValue }

    /// Label do segmented.
    var shortLabel: String { "\(rawValue)d" }

    /// Caption das seções.
    var sectionTitle: String { "Last \(rawValue) days" }
}
