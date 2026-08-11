import XCTest

final class CategoriesFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Categories list

    @MainActor
    func testCategoriesListShowsSeedCategories() {
        CategoriesPage(app: app)
            .assertVisible()
            .assertCategoryCount(5)
    }

    @MainActor
    func testTapCategoryOpensDetail() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapCategory(at: 0)
            .assertVisible()
    }

    // MARK: - Category detail

    @MainActor
    func testCategoryDetailShowsHabits() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapCategory(at: 0)
            .assertVisible()
            .assertHabitRowExists(at: 0)
    }

    @MainActor
    func testBackFromDetailReturnsToList() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapCategory(at: 0)
            .assertVisible()
            .tapBack()
            .assertVisible()
    }

    @MainActor
    func testEditButtonFromDetailOpensSheet() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapCategory(at: 0)
            .assertVisible()
            .tapEditButton()
            .assertVisible()
            .assertTitle("Edit category")
            .assertSaveEnabled()
    }

    // MARK: - Add category

    @MainActor
    func testAddCategoryFlowSave() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapAddButton()
            .assertVisible()
            .assertTitle("New category")
            .assertSaveDisabled()
            .typeName("Test Category")
            .assertSaveEnabled()
            .tapSave()
            .assertVisible()
    }

    @MainActor
    func testAddCategoryFlowCancel() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapAddButton()
            .assertVisible()
            .tapCancel()
            .assertVisible()
    }

    // MARK: - Edit category

    @MainActor
    func testEditCategorySaveFromDetail() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapCategory(at: 0)
            .assertVisible()
            .tapEditButton()
            .assertVisible()
            .assertSaveEnabled()
            .tapSave()
    }

    @MainActor
    func testEditCategoryCancelFromDetail() {
        CategoriesPage(app: app)
            .assertVisible()
            .tapCategory(at: 0)
            .assertVisible()
            .tapEditButton()
            .assertVisible()
            .tapCancel()
    }
}
