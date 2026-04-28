import XCTest

final class HomeFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Home screen

    @MainActor
    func testHomeShowsSeedHabits() {
        HomePage(app: app)
            .assertVisible()
            .assertHabitCardExists(at: 0)
    }

    @MainActor
    func testFilterByCategoryShowsSubset() {
        HomePage(app: app)
            .assertVisible()
            .tapCategory(at: 0)
            .assertHabitCardExists(at: 0)
            .tapCategoryAll()
            .assertHabitCardExists(at: 0)
    }

    // MARK: - Habit detail

    @MainActor
    func testTapHabitCardOpensDetail() {
        HomePage(app: app)
            .assertVisible()
            .tapHabitCard(at: 0)
            .assertVisible()
    }

    @MainActor
    func testBackFromDetailReturnsToHome() {
        HomePage(app: app)
            .assertVisible()
            .tapHabitCard(at: 0)
            .assertVisible()
            .tapBack()
            .assertVisible()
    }

    @MainActor
    func testArchiveHabitFromDetail() {
        HomePage(app: app)
            .assertVisible()
            .tapHabitCard(at: 0)
            .assertVisible()
            .tapArchive()
            .assertVisible()
    }

    // MARK: - Add habit

    @MainActor
    func testAddHabitFlowSave() {
        HomePage(app: app)
            .assertVisible()
            .tapAddButton()
            .assertVisible()
            .assertSaveDisabled()
            .typeName("Test habit")
            .assertSaveEnabled()
            .tapSave()
            .assertVisible()
    }

    @MainActor
    func testAddHabitFlowCancel() {
        HomePage(app: app)
            .assertVisible()
            .tapAddButton()
            .assertVisible()
            .tapCancel()
            .assertVisible()
    }
}
