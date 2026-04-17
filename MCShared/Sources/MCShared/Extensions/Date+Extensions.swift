import Foundation

public extension Date {

    // MARK: - Day boundaries

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    // MARK: - Comparisons

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func isInSameDay(_ other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Número absoluto de dias entre self e other. Retorna 0 se mesmo dia.
    func daysBetween(_ other: Date) -> Int {
        let start = Calendar.current.startOfDay(for: self)
        let end = Calendar.current.startOfDay(for: other)
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        return abs(components.day ?? 0)
    }

    // MARK: - Display helpers (pt_BR)

    /// Abreviação do dia da semana em pt_BR: "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"
    var weekdayShortName: String {
        Date.weekdayFormatter.string(from: self)
    }

    /// Dia e mês abreviado em pt_BR: "17 Abr", "3 Jan"
    var shortMonthDay: String {
        Date.shortMonthDayFormatter.string(from: self)
    }
}

// MARK: - Private formatters (cached)

private extension Date {

    static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "EEE"
        return f
    }()

    static let shortMonthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "d MMM"
        return f
    }()
}
