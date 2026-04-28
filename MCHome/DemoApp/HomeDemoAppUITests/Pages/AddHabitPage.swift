import XCTest

struct AddHabitPage {
    let app: XCUIApplication

    // MARK: - Elements

    var nameField: XCUIElement { app.textFields["add-habit-name-field"] }
    var saveButton: XCUIElement { app.buttons["add-habit-save-button"] }
    var cancelButton: XCUIElement { app.buttons["add-habit-cancel-button"] }
    var templateButton: XCUIElement { app.buttons["add-habit-template-button"] }

    // MARK: - Actions

    @discardableResult
    func typeName(_ name: String) -> Self {
        nameField.tap()
        nameField.typeText(name)
        return self
    }

    @discardableResult
    func tapSave() -> HomePage {
        saveButton.tap()
        return HomePage(app: app)
    }

    @discardableResult
    func tapCancel() -> HomePage {
        cancelButton.tap()
        return HomePage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add habit sheet not visible")
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
}
