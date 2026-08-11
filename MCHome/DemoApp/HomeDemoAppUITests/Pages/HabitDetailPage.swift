import XCTest

struct HabitDetailPage {
    let app: XCUIApplication

    // MARK: - Elements

    var archiveButton: XCUIElement { app.buttons["habit-detail-archive-button"] }
    var backButton: XCUIElement { app.navigationBars.buttons.firstMatch }

    // MARK: - Actions

    @discardableResult
    func tapArchive() -> HomePage {
        archiveButton.tap()
        return HomePage(app: app)
    }

    @discardableResult
    func tapBack() -> HomePage {
        backButton.tap()
        return HomePage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(archiveButton.waitForExistence(timeout: 5), "Habit detail not visible")
        return self
    }
}
