import XCTest

final class StatsFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Tela agregada

    @MainActor
    func testStatsShowsSummaryAndHabitRows() {
        StatsPage(app: app)
            .assertVisible()
            .assertSummaryVisible()
            .assertHabitRowExists(at: 0)
            .assertStripVisible(at: 0)
    }

    @MainActor
    func testStatsShowsSeededHabit() {
        // `activeHabits` ordena por nome, e "Beber água" é o primeiro dos hábitos do seed.
        StatsPage(app: app)
            .assertVisible()
            .assertHabitExists("Beber água")
    }

    @MainActor
    func testChangePeriodKeepsRowsVisible() {
        StatsPage(app: app)
            .assertVisible()
            .selectPeriod(7)
            .assertStripVisible(at: 0)
            .selectPeriod(90)
            .assertStripVisible(at: 0)
            .selectPeriod(30)
            .assertSummaryVisible()
    }

    // MARK: - Detalhe por hábito

    @MainActor
    func testTapHabitRowOpensHabitStats() {
        StatsPage(app: app)
            .assertVisible()
            .tapHabitRow(at: 0)
            .assertVisible()
            .assertSummaryVisible()
            .assertCalendarVisible()
    }

    @MainActor
    func testBackFromHabitStatsReturnsToStats() {
        StatsPage(app: app)
            .assertVisible()
            .tapHabitRow(at: 0)
            .assertVisible()
            .tapBack()
            .assertVisible()
            .assertHabitRowExists(at: 0)
    }

    @MainActor
    func testHabitStatsPeriodSwitchKeepsCalendar() {
        StatsPage(app: app)
            .assertVisible()
            .tapHabitRow(at: 0)
            .assertVisible()
            .selectPeriod(90)
            .assertCalendarVisible()
            .selectPeriod(7)
            .assertCalendarVisible()
    }
}
