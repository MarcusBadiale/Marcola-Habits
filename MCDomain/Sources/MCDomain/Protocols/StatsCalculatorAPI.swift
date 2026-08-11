import Foundation

public protocol StatsCalculatorAPI: Sendable {

    /// Dias consecutivos completados para trás a partir de hoje (ou de ontem, se hoje ainda não foi).
    func currentStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int

    /// Maior sequência consecutiva de dias completados em todo o histórico — não recortado por período.
    func bestStreak(habitID: UUID, logs: [HabitLogDTO]) -> Int

    /// Taxa de conclusão do período, medida semana a semana. 0.0 quando nada estava agendado.
    ///
    /// A semana é a unidade de medida para todos os tipos de frequência: o `target` de cada semana é
    /// o número de dias agendados (`.daily`, `.specificDays`) ou `n` (`.timesPerWeek(n)`).
    /// É uma razão agregada (Σdone / Σtarget), **não** a média das taxas por hábito.
    func completionRate(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> Double

    /// Mesma métrica de `completionRate`, quebrada por hábito. Todo hábito recebido é chave.
    func completionRates(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [UUID: Double]

    /// Matriz hábito × dia do período. Uma entrada por hábito recebido, na ordem recebida.
    func activity(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [HabitActivityDTO]
}
