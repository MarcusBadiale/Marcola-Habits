import XCTest

struct EditCategoryPage {
    let app: XCUIApplication

    // MARK: - Elements

    var nameField: XCUIElement { app.textFields["edit-category-name-field"] }
    var saveButton: XCUIElement { app.buttons["edit-category-save-button"] }
    var cancelButton: XCUIElement { app.buttons["edit-category-cancel-button"] }

    // MARK: - Actions

    @discardableResult
    func typeName(_ name: String) -> Self {
        nameField.tap()
        nameField.typeText(name)
        return self
    }

    @discardableResult
    func clearName() -> Self {
        nameField.tap()
        let text = nameField.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count)
        nameField.typeText(deleteString)
        return self
    }

    @discardableResult
    func tapSave() -> CategoriesPage {
        saveButton.tap()
        return CategoriesPage(app: app)
    }

    @discardableResult
    func tapCancel() -> CategoriesPage {
        cancelButton.tap()
        return CategoriesPage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Edit category sheet not visible")
        return self
    }

    @discardableResult
    func assertSaveDisabled() -> Self {
        XCTAssertFalse(saveButton.isEnabled)
        return self
    }

    @discardableResult
    func assertSaveEnabled() -> Self {
        XCTAssertTrue(saveButton.isEnabled)
        return self
    }

    @discardableResult
    func assertTitle(_ title: String) -> Self {
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 3))
        return self
    }
}
