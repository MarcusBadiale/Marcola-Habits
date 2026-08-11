import Foundation

public extension SeedDataProvider {

    /// Quantos dias de histórico o seed cobre. Precisa ser maior que o maior recorte da tela de
    /// Stats (90 dias), senão o período abre com a maior parte dos dias vazia.
    static var historyDays: Int { 91 }

    /// Logs de exemplo cobrindo `historyDays` dias.
    ///
    /// Os 21 dias mais recentes vêm de um pattern fixo por hábito — é o que dá os streaks e o estado
    /// de hoje que a Home mostra. O resto do histórico é gerado por um LCG semeado pelo índice do
    /// hábito: determinístico de propósito, porque os UI tests dependem de a tela abrir sempre igual.
    static func defaultLogs(for habits: [HabitModel]) -> [HabitLogModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var logs: [HabitLogModel] = []

        for (index, habit) in habits.enumerated() {
            let profile = logProfiles[index % logProfiles.count]
            var generator = SeededGenerator(seed: UInt64(index + 1))

            for dayOffset in 0..<historyDays {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                guard habit.isScheduled(for: date) else { continue }

                let completed = profile.completed(dayOffset: dayOffset, generator: &generator)
                let count = completed
                    ? profile.countRange.lowerBound + (dayOffset % profile.countRange.count)
                    : 0

                logs.append(HabitLogModel(date: date, completed: completed, count: count, habit: habit))
            }
        }

        return logs
    }
}

// MARK: - Perfis

private struct LogProfile {
    /// Índice 0 = hoje, 1 = ontem… `1` = feito, `0` = não feito.
    let recentPattern: String
    /// Probabilidade de conclusão nos dias além do `recentPattern`.
    let adherence: Double
    let countRange: ClosedRange<Int>

    func completed(dayOffset: Int, generator: inout SeededGenerator) -> Bool {
        guard dayOffset >= recentPattern.count else {
            let index = recentPattern.index(recentPattern.startIndex, offsetBy: dayOffset)
            return recentPattern[index] == "1"
        }
        return generator.next() < adherence
    }
}

private extension SeedDataProvider {
    static var logProfiles: [LogProfile] {
        [
            // Beber água: streak 11, hoje pendente
            LogProfile(recentPattern: "011111111111011011101", adherence: 0.85, countRange: 5...8),
            // Meditar: streak 4 + hoje
            LogProfile(recentPattern: "111110111111101110110", adherence: 0.70, countRange: 1...1),
            // Exercício: sempre (pula fins de semana pela frequência)
            LogProfile(recentPattern: "111111111111111111111", adherence: 0.92, countRange: 1...1),
            // Ler: esporádico
            LogProfile(recentPattern: "001010110100101011010", adherence: 0.40, countRange: 15...30),
            // Journaling: streak 12 + hoje
            LogProfile(recentPattern: "111111111111100111011", adherence: 0.80, countRange: 1...1),
            // Sem redes sociais: ~50%
            LogProfile(recentPattern: "010110100101011011010", adherence: 0.50, countRange: 1...1),
        ]
    }
}

// MARK: - Gerador

/// LCG de 64 bits. Existe para o seed ser reproduzível — `Bool.random()` faria o Demo App e os
/// UI tests abrirem diferentes a cada execução.
private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 2_654_435_761 | 1
    }

    /// Próximo valor em `[0, 1)`.
    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}
