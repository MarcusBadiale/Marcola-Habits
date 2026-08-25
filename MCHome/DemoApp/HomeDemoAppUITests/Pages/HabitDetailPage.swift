import XCTest

struct HabitDetailPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// Sem assumir o tipo do elemento: um container com `.combine`/`.contain` nem sempre aparece
    /// como `otherElements`, e `firstMatch` resolve container + filho.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var list: XCUIElement { element("habit-detail-list") }
    var archiveButton: XCUIElement { element("habit-detail-archive-button") }
    var backButton: XCUIElement { app.navigationBars.buttons.firstMatch }

    // MARK: - Actions

    @discardableResult
    func tapArchive() -> HomePage {
        scrollToArchive()
        archiveButton.tap()
        return HomePage(app: app)
    }

    @discardableResult
    func tapBack() -> HomePage {
        backButton.tap()
        return HomePage(app: app)
    }

    /// A seção de arquivar fica no fim da `List`, depois dos ~13 logs recentes — fora da tela no
    /// primeiro frame. A árvore do XCUITest só tem o que a `List` renderizou, então é preciso
    /// rolar até lá antes de procurar o botão.
    private func scrollToArchive() {
        var attempts = 0
        while !archiveButton.exists && attempts < 10 {
            app.swipeUp()
            attempts += 1
        }
    }

    // MARK: - Assertions

    /// Assere pela `List` e não pelo botão de arquivar: aquele exige rolagem, e "a tela abriu" não
    /// deveria depender de scroll.
    @discardableResult
    func assertVisible() -> Self {
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Habit detail not visible")
        return self
    }
}
