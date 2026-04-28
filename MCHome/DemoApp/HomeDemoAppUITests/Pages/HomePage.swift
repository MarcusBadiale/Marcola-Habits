import XCTest

struct HomePage {
    let app: XCUIApplication

    // MARK: - Elements

    var dateCarousel: XCUIElement { app.otherElements["home-date-carousel"] }
    var addButton: XCUIElement { app.buttons["home-add-button"] }
    var categoryAllChip: XCUIElement { app.otherElements["home-category-all"] }

    func categoryChip(at index: Int) -> XCUIElement {
        app.otherElements["home-category-chip-\(index)"]
    }

    func habitCard(at index: Int) -> XCUIElement {
        app.otherElements["home-habit-card-\(index)"]
    }

    // MARK: - Actions

    @discardableResult
    func tapAddButton() -> AddHabitPage {
        addButton.tap()
        return AddHabitPage(app: app)
    }

    @discardableResult
    func tapHabitCard(at index: Int) -> HabitDetailPage {
        habitCard(at: index).tap()
        return HabitDetailPage(app: app)
    }

    @discardableResult
    func tapCategoryAll() -> Self {
        categoryAllChip.tap()
        return self
    }

    @discardableResult
    func tapCategory(at index: Int) -> Self {
        categoryChip(at: index).tap()
        return self
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Home screen not visible")
        return self
    }

    @discardableResult
    func assertHabitCardExists(at index: Int) -> Self {
        XCTAssertTrue(habitCard(at: index).waitForExistence(timeout: 3))
        return self
    }

    @discardableResult
    func assertHabitCardNotExists(at index: Int) -> Self {
        XCTAssertFalse(habitCard(at: index).exists)
        return self
    }
}
