import XCTest

struct StatsPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// Sem assumir o tipo do elemento: `.accessibilityElement(children: .combine)` no SwiftUI não
    /// garante que o resultado seja `otherElements`, e `firstMatch` resolve container + filho.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var periodPicker: XCUIElement { app.segmentedControls["stats-period-picker"] }
    var completionRate: XCUIElement { element("stats-completion-rate") }
    var bestStreak: XCUIElement { element("stats-best-streak") }

    func habitRow(at index: Int) -> XCUIElement {
        element("stats-habit-row-\(index)")
    }

    func habitStrip(at index: Int) -> XCUIElement {
        element("stats-habit-row-\(index)-strip")
    }

    func habitStripCell(row: Int, cell: Int) -> XCUIElement {
        element("stats-habit-row-\(row)-strip-cell-\(cell)")
    }

    // MARK: - Actions

    /// Identifier em segmento de `Picker` é instável — tenta pelo label e cai pro identifier.
    @discardableResult
    func selectPeriod(_ days: Int) -> Self {
        let byLabel = periodPicker.buttons["\(days)d"]
        if byLabel.waitForExistence(timeout: 3) {
            byLabel.tap()
        } else {
            app.buttons["stats-period-option-\(days)"].tap()
        }
        return self
    }

    @discardableResult
    func tapHabitRow(at index: Int) -> HabitStatsPage {
        habitRow(at: index).tap()
        return HabitStatsPage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(periodPicker.waitForExistence(timeout: 5), "Stats screen not visible")
        return self
    }

    @discardableResult
    func assertSummaryVisible() -> Self {
        XCTAssertTrue(completionRate.waitForExistence(timeout: 3))
        XCTAssertTrue(bestStreak.waitForExistence(timeout: 3))
        return self
    }

    @discardableResult
    func assertHabitRowExists(at index: Int) -> Self {
        XCTAssertTrue(habitRow(at: index).waitForExistence(timeout: 3))
        return self
    }

    /// Só existência — o Demo App usa o `StatsCalculator` real sobre o seed, então nenhum assert
    /// olha valor de célula, percentual ou streak: esses números mudam com o dia da semana.
    @discardableResult
    func assertStripVisible(at index: Int) -> Self {
        XCTAssertTrue(habitStrip(at: index).waitForExistence(timeout: 3))
        XCTAssertTrue(habitStripCell(row: index, cell: 0).exists)
        return self
    }

    @discardableResult
    func assertHabitExists(_ name: String) -> Self {
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 3))
        return self
    }
}
