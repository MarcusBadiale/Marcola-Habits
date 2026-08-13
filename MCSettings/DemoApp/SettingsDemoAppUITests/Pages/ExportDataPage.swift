import XCTest

struct ExportDataPage {
    let app: XCUIApplication

    // MARK: - Elements

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var summary: XCUIElement { element("settings-export-summary") }
    var shareButton: XCUIElement { element("settings-export-share-button") }
    var sizeRow: XCUIElement { element("settings-export-size") }
    var disclaimer: XCUIElement { element("settings-export-disclaimer") }
    var errorLabel: XCUIElement { element("settings-export-error") }

    // MARK: - Actions

    @discardableResult
    func goBack() -> SettingsPage {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        return SettingsPage(app: app)
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(summary.waitForExistence(timeout: 5), "Export screen not visible")
        return self
    }

    /// Só existência. Tocar no `ShareLink` abriria o share sheet do sistema, que é lento e flaky.
    @discardableResult
    func assertShareAvailable() -> Self {
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share button never appeared")
        return self
    }

    /// O tamanho sai de "—" quando o encode termina — é o que prova que o build rodou de verdade.
    @discardableResult
    func assertSizeComputed() -> Self {
        XCTAssertTrue(sizeRow.waitForExistence(timeout: 5))
        let gone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: gone, object: app.staticTexts["—"])
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                       "File size never got computed")
        return self
    }

    @discardableResult
    func assertNoError() -> Self {
        XCTAssertFalse(errorLabel.exists, "Export reported an error")
        return self
    }

    @discardableResult
    func assertDisclaimerVisible() -> Self {
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 3))
        return self
    }
}
