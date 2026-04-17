import Testing
import Foundation
@testable import MCDomain

@Suite("HabitFrequency")
struct HabitFrequencyTests {

    // MARK: - isScheduled parametrizado

    @Test("daily é agendado para qualquer dia da semana", .tags(.domain), arguments: Weekday.allCases)
    func dailyScheduledAllDays(weekday: Weekday) {
        let date = dateForWeekday(weekday)
        #expect(HabitFrequency.daily.isScheduled(for: date))
    }

    @Test("specificDays agenda nos dias corretos", .tags(.domain), arguments: [
        (Set<Weekday>([.monday, .wednesday, .friday]), Weekday.monday, true),
        (Set<Weekday>([.monday, .wednesday, .friday]), Weekday.tuesday, false),
        (Set<Weekday>([.monday, .wednesday, .friday]), Weekday.wednesday, true),
        (Set<Weekday>([.sunday, .saturday]), Weekday.sunday, true),
        (Set<Weekday>([.sunday, .saturday]), Weekday.saturday, true),
        (Set<Weekday>([.sunday, .saturday]), Weekday.tuesday, false),
    ])
    func specificDaysScheduled(days: Set<Weekday>, weekday: Weekday, expected: Bool) {
        let date = dateForWeekday(weekday)
        #expect(HabitFrequency.specificDays(days).isScheduled(for: date) == expected)
    }

    @Test("timesPerWeek é agendado para qualquer dia", .tags(.domain), arguments: [1, 3, 5, 7])
    func timesPerWeekScheduledAllDays(times: Int) {
        let date = dateForWeekday(.monday)
        #expect(HabitFrequency.timesPerWeek(times).isScheduled(for: date))
    }

    @Test("specificDays com conjunto vazio nunca agenda", .tags(.domain), arguments: Weekday.allCases)
    func specificDaysEmptyNeverScheduled(weekday: Weekday) {
        let date = dateForWeekday(weekday)
        #expect(!HabitFrequency.specificDays([]).isScheduled(for: date))
    }

    // MARK: - Helpers

    private func dateForWeekday(_ weekday: Weekday) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        components.weekday = weekday.rawValue
        return calendar.date(from: components) ?? .now
    }
}
