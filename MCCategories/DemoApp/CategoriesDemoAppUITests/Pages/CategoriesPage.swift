import XCTest

struct CategoriesPage {
    let app: XCUIApplication

    // MARK: - Elements

    var addButton: XCUIElement { app.buttons["categories-add-button"] }

    func categoryRow(at index: Int) -> XCUIElement {
        app.otherElements["categories-row-\(index)"]
    }

    // MARK: - Actions

    @discardableResult
    func tapAddButton() -> EditCategoryPage {
        addButton.tap()
        return EditCategoryPage(app: app)
    }

    @discardableResult
    func tapCategory(at index: Int) -> CategoryDetailPage {
        categoryRow(at: index).tap()
        return CategoryDetailPage(app: app)
    }

    @discardableResult
    func deleteCategory(at index: Int) -> Self {
        let row = categoryRow(at: index)
        row.swipeLeft()
        app.buttons["Delete"].tap()
        return self
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Categories screen not visible")
        return self
    }

    @discardableResult
    func assertCategoryRowExists(at index: Int) -> Self {
        XCTAssertTrue(categoryRow(at: index).waitForExistence(timeout: 3))
        return self
    }

    @discardableResult
    func assertCategoryRowNotExists(at index: Int) -> Self {
        XCTAssertFalse(categoryRow(at: index).exists)
        return self
    }

    @discardableResult
    func assertCategoryCount(_ count: Int) -> Self {
        for i in 0..<count {
            XCTAssertTrue(categoryRow(at: i).waitForExistence(timeout: 3))
        }
        XCTAssertFalse(categoryRow(at: count).exists)
        return self
    }
}
