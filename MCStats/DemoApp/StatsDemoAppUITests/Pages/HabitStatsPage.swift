import XCTest

struct HabitStatsPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// Ver a nota em `StatsPage.element(_:)` — o tipo do elemento não é garantido.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var periodPicker: XCUIElement { app.segmentedControls["habit-stats-period-picker"] }
    var completionRate: XCUIElement { element("habit-stats-completion-rate") }
    var bestStreak: XCUIElement { element("habit-stats-best-streak") }
    var currentStreak: XCUIElement { element("habit-stats-current-streak") }
    var calendar: XCUIElement { element("habit-stats-calendar") }
    var backButton: XCUIElement { app.navigationBars.buttons.firstMatch }

    func calendarCell(at index: Int) -> XCUIElement {
        element("habit-stats-calendar-cell-\(index)")
    }

    // MARK: - Actions

    @discardableResult
    func selectPeriod(_ days: Int) -> Self {
        let byLabel = periodPicker.buttons["\(days)d"]
        if byLabel.waitForExistence(timeout: 3) {
            byLabel.tap()
        } else {
            app.buttons["habit-stats-period-option-\(days)"].tap()
        }
        return self
    }

    @discardableResult
    func tapBack() -> StatsPage {
        backButton.tap()
        return StatsPage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(periodPicker.waitForExistence(timeout: 5), "Habit stats screen not visible")
        return self
    }

    @discardableResult
    func assertSummaryVisible() -> Self {
        XCTAssertTrue(completionRate.waitForExistence(timeout: 3))
        XCTAssertTrue(bestStreak.waitForExistence(timeout: 3))
        XCTAssertTrue(currentStreak.waitForExistence(timeout: 3))
        return self
    }

    @discardableResult
    func assertCalendarVisible() -> Self {
        XCTAssertTrue(calendar.waitForExistence(timeout: 3))
        return self
    }
}
