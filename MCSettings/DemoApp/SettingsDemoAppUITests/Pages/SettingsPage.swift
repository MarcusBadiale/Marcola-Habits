import XCTest

struct SettingsPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// Sem assumir o tipo do elemento: um `Button` com `.buttonStyle(.plain)` nem sempre aparece
    /// como `buttons`, e `firstMatch` resolve container + filho.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Âncora da tela: o botão do card de perfil é o único elemento que existe sempre na root.
    var accountAction: XCUIElement { element("settings-account-action") }
    var syncRow: XCUIElement { element("settings-sync-row") }
    var exportRow: XCUIElement { element("settings-export-row") }
    var archivedRow: XCUIElement { element("settings-archived-row") }
    var themeRow: XCUIElement { element("settings-theme-row") }
    var notificationsRow: XCUIElement { element("settings-notifications-row") }
    var rateRow: XCUIElement { element("settings-rate-row") }
    var versionRow: XCUIElement { element("settings-version-row") }

    // MARK: - Actions

    @discardableResult
    func tapArchived() -> ArchivedHabitsPage {
        archivedRow.tap()
        return ArchivedHabitsPage(app: app)
    }

    @discardableResult
    func tapExport() -> ExportDataPage {
        exportRow.tap()
        return ExportDataPage(app: app)
    }

    @discardableResult
    func tapTheme() -> AppearancePage {
        themeRow.tap()
        return AppearancePage(app: app)
    }

    @discardableResult
    func tapSync() -> Self {
        syncRow.tap()
        return self
    }

    @discardableResult
    func tapAccountAction() -> Self {
        accountAction.tap()
        return self
    }

    /// Tap numa row desabilitada. Não deve navegar — quem confere é `assertVisible()` depois.
    @discardableResult
    func tapDisabledRow(_ identifier: String) -> Self {
        let row = element(identifier)
        if row.isHittable { row.tap() }
        return self
    }

    // MARK: - Assertions

    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(accountAction.waitForExistence(timeout: 5), "Settings screen not visible")
        return self
    }

    @discardableResult
    func assertSectionsVisible() -> Self {
        XCTAssertTrue(syncRow.waitForExistence(timeout: 3))
        XCTAssertTrue(exportRow.exists)
        XCTAssertTrue(archivedRow.exists)
        XCTAssertTrue(themeRow.exists)
        XCTAssertTrue(versionRow.exists)
        return self
    }

    @discardableResult
    func assertDisabledRowsExist() -> Self {
        XCTAssertTrue(notificationsRow.waitForExistence(timeout: 3))
        XCTAssertTrue(rateRow.exists)
        return self
    }

    @discardableResult
    func assertTextExists(_ text: String) -> Self {
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 3), "Missing text: \(text)")
        return self
    }

    /// O título da ação de conta é o `label` do botão, não um `staticText` solto.
    @discardableResult
    func assertAccountActionTitle(_ title: String) -> Self {
        let matches = NSPredicate(format: "label == %@", title)
        let expectation = XCTNSPredicateExpectation(predicate: matches, object: accountAction)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                       "Account action is '\(accountAction.label)', expected '\(title)'")
        return self
    }

    /// Row com detail vira um elemento único de label combinada ("Theme, Dark") — não existe um
    /// `staticText` "Dark" sozinho.
    @discardableResult
    func assertRowDetail(_ identifier: String, contains detail: String) -> Self {
        let row = element(identifier)
        let matches = NSPredicate(format: "label CONTAINS %@", detail)
        let expectation = XCTNSPredicateExpectation(predicate: matches, object: row)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                       "Row '\(identifier)' is '\(row.label)', expected it to contain '\(detail)'")
        return self
    }

    @discardableResult
    func assertTextGone(_ text: String) -> Self {
        let gone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: gone, object: app.staticTexts[text])
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                       "Text still present: \(text)")
        return self
    }

    /// O `FakeSyncService` dorme ~800ms antes de gravar a data, então "Never synced" some — é essa
    /// troca que prova, ponta a ponta, que a observação atravessa o existencial `any SyncServiceAPI`.
    @discardableResult
    func assertSyncLabelChangedFromNever() -> Self {
        assertTextGone("Never synced")
    }
}
