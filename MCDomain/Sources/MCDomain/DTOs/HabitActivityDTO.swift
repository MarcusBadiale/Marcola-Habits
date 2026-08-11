import Foundation

/// Estado de um hábito num dia específico.
public enum ActivityState: String, Codable, Hashable, Sendable {
    /// Foi completado nesse dia.
    case completed
    /// Havia obrigação nesse dia e não foi completado.
    case missed
    /// Nenhuma obrigação nesse dia — dia de descanso, ou hábito `.timesPerWeek`, que não tem
    /// obrigação amarrada a um dia específico.
    case notScheduled
}

public struct DayActivityDTO: Codable, Hashable, Sendable, Identifiable {
    /// Sempre `startOfDay`.
    public let date: Date
    public let state: ActivityState

    public var id: Date { date }

    public init(date: Date, state: ActivityState) {
        self.date = date
        self.state = state
    }
}

public struct HabitActivityDTO: Codable, Hashable, Sendable, Identifiable {
    public let habitID: UUID
    /// Ordenado do dia mais antigo do período até hoje. Sempre com um elemento por dia do período.
    public let days: [DayActivityDTO]

    public var id: UUID { habitID }

    public init(habitID: UUID, days: [DayActivityDTO]) {
        self.habitID = habitID
        self.days = days
    }
}
