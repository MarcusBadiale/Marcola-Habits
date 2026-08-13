import XCTest

struct ArchivedHabitsPage {
    let app: XCUIApplication

    // MARK: - Elements

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var list: XCUIElement { element("settings-archived-list") }
    var emptyState: XCUIElement { element("settings-archived-empty") }
    /// `.firstMatch`: o `confirmationDialog` duplica o botão na árvore (o Sheet e o botão de
    /// dentro carregam o mesmo identifier), então a query crua encontra 2 e falha.
    var deleteConfirmButton: XCUIElement {
        app.buttons.matching(identifier: "settings-archived-delete-confirm").firstMatch
    }

    // Não há acessor pro botão de Cancel: neste iOS o `confirmationDialog` vira popover e o
    // `role: .cancel` não aparece na árvore de acessibilidade. O cancelamento é testado no
    // ArchivedHabitsProviderTests.

    func row(at index: Int) -> XCUIElement { element("settings-archived-row-\(index)") }

    /// O swipe tem que ser na `Cell` do `List`: swipe no conteúdo da linha não revela as
    /// swipe actions.
    private func cell(at index: Int) -> XCUIElement { app.cells.element(boundBy: index) }

    // MARK: - Actions

    @discardableResult
    func unarchive(at index: Int) -> Self {
        cell(at: index).swipeLeft()
        let button = app.buttons["settings-archived-unarchive-\(index)"]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Unarchive action never appeared")
        button.tap()
        return self
    }

    @discardableResult
    func requestDelete(at index: Int) -> Self {
        cell(at: index).swipeLeft()
        let button = app.buttons["settings-archived-delete-\(index)"]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Delete action never appeared")
        button.tap()
        return self
    }

    @discardableResult
    func confirmDelete() -> Self {
        deleteConfirmButton.tap()
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
        XCTAssertTrue(
            list.waitForExistence(timeout: 5) || emptyState.waitForExistence(timeout: 5),
            "Archived habits screen not visible"
        )
        return self
    }

    @discardableResult
    func assertEmpty() -> Self {
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5), "Expected the empty state")
        return self
    }

    /// A row é `.combine`, então o label dela é "Correr 5km, 0 check-ins" — não existe um
    /// `staticText` só com o nome.
    @discardableResult
    func assertHabitExists(_ name: String) -> Self {
        let matches = NSPredicate(format: "label CONTAINS %@", name)
        let expectation = XCTNSPredicateExpectation(predicate: matches, object: row(at: 0))
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                       "Missing habit: \(name)")
        return self
    }

    @discardableResult
    func assertHabitGone(_ name: String) -> Self {
        let gone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: gone, object: row(at: 0))
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                       "Habit still listed: \(name)")
        return self
    }

    @discardableResult
    func assertConfirmationVisible() -> Self {
        XCTAssertTrue(deleteConfirmButton.waitForExistence(timeout: 3),
                      "Delete confirmation did not appear")
        return self
    }
}
