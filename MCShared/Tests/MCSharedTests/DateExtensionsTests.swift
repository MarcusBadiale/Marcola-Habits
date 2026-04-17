import Testing
import Foundation
@testable import MCShared

extension Tag {
    @Tag static var extensions: Self
}

@Suite("Date Extensions")
struct DateExtensionsTests {

    // MARK: - startOfDay

    @Test("startOfDay zera hora, minuto e segundo", .tags(.extensions))
    func startOfDay() {
        let date = Date(timeIntervalSince1970: 1_745_000_000)
        let start = date.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    // MARK: - isToday

    @Test("isToday retorna true pra hoje", .tags(.extensions))
    func isTodayTrue() {
        #expect(Date.now.isToday)
    }

    @Test("isToday retorna false pra ontem", .tags(.extensions))
    func isTodayFalse() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        #expect(!yesterday.isToday)
    }

    // MARK: - isInSameDay

    @Test("isInSameDay retorna true pra mesma data", .tags(.extensions))
    func isInSameDayTrue() {
        let date = Date.now
        #expect(date.isInSameDay(date))
    }

    @Test("isInSameDay retorna false pra dias diferentes", .tags(.extensions))
    func isInSameDayFalse() {
        let today = Date.now
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        #expect(!today.isInSameDay(tomorrow))
    }

    // MARK: - daysBetween

    @Test("daysBetween retorna 0 pra mesmo dia", .tags(.extensions))
    func daysBetweenSameDay() {
        let date = Date.now
        #expect(date.daysBetween(date) == 0)
    }

    @Test("daysBetween conta dias corretamente", .tags(.extensions))
    func daysBetweenCount() {
        let today = Date.now
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: today)!
        #expect(fiveDaysAgo.daysBetween(today) == 5)
    }

    @Test("daysBetween é simétrico", .tags(.extensions))
    func daysBetweenSymmetric() {
        let today = Date.now.startOfDay
        let inFiveDays = Calendar.current.date(byAdding: .day, value: 5, to: today)!
        #expect(today.daysBetween(inFiveDays) == inFiveDays.daysBetween(today))
    }

    // MARK: - Display helpers

    @Test("weekdayShortName não é vazio", .tags(.extensions))
    func weekdayShortNameNotEmpty() {
        #expect(!Date.now.weekdayShortName.isEmpty)
    }

    @Test("shortMonthDay não é vazio", .tags(.extensions))
    func shortMonthDayNotEmpty() {
        #expect(!Date.now.shortMonthDay.isEmpty)
    }
}
