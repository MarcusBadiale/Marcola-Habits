import XCTest

struct AppearancePage {
    let app: XCUIApplication

    // MARK: - Elements

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var themePicker: XCUIElement { app.segmentedControls["settings-appearance-theme-picker"] }
    var accentSection: XCUIElement { element("settings-appearance-accent") }

    func accentSwatch(at index: Int) -> XCUIElement {
        element("settings-appearance-accent-\(index)")
    }

    // MARK: - Actions

    @discardableResult
    func selectTheme(_ label: String) -> Self {
        themePicker.buttons[label].tap()
        return self
    }

    @discardableResult
    func selectAccent(at index: Int) -> Self {
        accentSwatch(at: index).tap()
        return self
    }

    @discardableResult
    func goBack() -> SettingsPage {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        return SettingsPage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(themePicker.waitForExistence(timeout: 5), "Appearance screen not visible")
        XCTAssertTrue(accentSection.exists)
        return self
    }

    @discardableResult
    func assertThemeSelected(_ label: String) -> Self {
        let option = themePicker.buttons[label]
        XCTAssertTrue(option.waitForExistence(timeout: 3))
        XCTAssertTrue(option.isSelected, "Expected \(label) to be the selected theme")
        return self
    }
}
