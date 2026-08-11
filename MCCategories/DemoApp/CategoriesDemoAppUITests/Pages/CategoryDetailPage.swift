import XCTest

struct CategoryDetailPage {
    let app: XCUIApplication

    // MARK: - Elements

    var editButton: XCUIElement { app.buttons["category-detail-edit-button"] }
    var backButton: XCUIElement { app.navigationBars.buttons.firstMatch }

    func habitRow(at index: Int) -> XCUIElement {
        app.otherElements["category-detail-habit-\(index)"]
    }

    // MARK: - Actions

    @discardableResult
    func tapEditButton() -> EditCategoryPage {
        editButton.tap()
        return EditCategoryPage(app: app)
    }

    @discardableResult
    func tapBack() -> CategoriesPage {
        backButton.tap()
        return CategoriesPage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Category detail not visible")
        return self
    }

    @discardableResult
    func assertHabitRowExists(at index: Int) -> Self {
        XCTAssertTrue(habitRow(at: index).waitForExistence(timeout: 3))
        return self
    }

    @discardableResult
    func assertEmptyState() -> Self {
        let emptyLabel = app.staticTexts["No habits in this category"]
        XCTAssertTrue(emptyLabel.waitForExistence(timeout: 3))
        return self
    }
}
