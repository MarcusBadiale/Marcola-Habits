import XCTest

struct HomePage {
    let app: XCUIApplication

    // MARK: - Elements

    /// Sem assumir o tipo do elemento: um container com `.combine`/`.contain` nem sempre aparece
    /// como `otherElements`, e `firstMatch` resolve container + filho.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var dateCarousel: XCUIElement { element("home-date-carousel") }
    var addButton: XCUIElement { app.buttons["home-add-button"] }
    var categoryAllChip: XCUIElement { element("home-category-all") }

    func categoryChip(at index: Int) -> XCUIElement {
        element("home-category-chip-\(index)")
    }

    func habitCard(at index: Int) -> XCUIElement {
        element("home-habit-card-\(index)")
    }

    func habitToggle(at index: Int) -> XCUIElement {
        element("home-habit-toggle-\(index)")
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
    func toggleHabit(at index: Int) -> Self {
        habitToggle(at: index).tap()
        return self
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

    /// O estado do check-in vem do `accessibilityValue` do botão ("completed"/"not completed"),
    /// não da label — a label é o nome do hábito e não muda com o toggle.
    @discardableResult
    func assertHabitToggleValue(at index: Int, equals expected: String) -> Self {
        let toggle = habitToggle(at: index)
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))

        let matches = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: matches, object: toggle)
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: 5),
            .completed,
            "Esperava value '\(expected)', veio '\(String(describing: toggle.value))'"
        )
        return self
    }
}
