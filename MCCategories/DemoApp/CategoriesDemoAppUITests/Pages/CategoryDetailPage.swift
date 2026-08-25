import XCTest

struct CategoryDetailPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// Sem assumir o tipo do elemento: um container com `.combine` nem sempre aparece como
    /// `otherElements`, e `firstMatch` resolve container + filho.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var editButton: XCUIElement { app.buttons["category-detail-edit-button"] }
    var backButton: XCUIElement { app.navigationBars.buttons.firstMatch }

    func habitRow(at index: Int) -> XCUIElement {
        element("category-detail-habit-\(index)")
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
