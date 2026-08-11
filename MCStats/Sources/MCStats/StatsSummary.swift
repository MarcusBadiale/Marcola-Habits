import Foundation
import MCDomain

/// Uma linha da lista de hábitos da tela agregada.
struct StatsHabitSummary: Identifiable {
    let habit: HabitModel
    let streak: Int
    let rate: Double
    let days: [DayActivityDTO]

    var id: UUID { habit.id }
}

/// Tudo o que a tela agregada precisa, calculado numa passada só.
///
/// Existe como um tipo em vez de várias computed properties no provider porque cada acesso a uma
/// computed property remapearia todos os logs pra DTO e chamaria o calculator de novo — e o SwiftUI
/// acessa várias vezes por frame.
struct StatsSummary {
    /// Razão agregada do período (feitos ÷ agendados), não a média das taxas por hábito.
    let rate: Double
    /// Melhor streak entre os hábitos ativos, no histórico inteiro.
    let bestStreak: Int
    let habits: [StatsHabitSummary]

    static let empty = StatsSummary(rate: 0, bestStreak: 0, habits: [])
}

/// O equivalente para a tela de detalhe de um hábito. Mesma razão de existir: uma passada só.
struct HabitStatsSummary {
    let currentStreak: Int
    let bestStreak: Int
    let rate: Double
    let days: [DayActivityDTO]

    static let empty = HabitStatsSummary(currentStreak: 0, bestStreak: 0, rate: 0, days: [])
}
