import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin
#endif

final class MockableTests: XCTestCase {

    // MARK: - Basic: @State properties

    func testStatePropertiesBecomePlainVarsWithDefaults() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct SettingsProvider {
                @State var isDarkMode: Bool = false
                @State var fontSize: Double = 14.0
            }
            """,
            expandedSource: """
            struct SettingsProvider {
                @State var isDarkMode: Bool = false
                @State var fontSize: Double = 14.0

                struct Mock {
                    var isDarkMode: Bool

                    var fontSize: Double

                    init(isDarkMode: Bool = false, fontSize: Double = 14.0) {
                        self.isDarkMode = isDarkMode
                        self.fontSize = fontSize
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @AppStorage properties

    /// @AppStorage é tratado como @State: estado local com default. A persistência no UserDefaults
    /// não existe no Mock, que é lógica pura. Sem isso ele cairia em `.regular` — parâmetro
    /// obrigatório com o default descartado.
    func testAppStoragePropertiesBehaveLikeState() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct AppearanceProvider {
                @AppStorage("mcSettingsTheme") var themeRawValue: String = "system"
                @AppStorage("mcSettingsAccentHex") var accentHex: String = AppearanceDefaults.accentHex
            }
            """,
            expandedSource: """
            struct AppearanceProvider {
                @AppStorage("mcSettingsTheme") var themeRawValue: String = "system"
                @AppStorage("mcSettingsAccentHex") var accentHex: String = AppearanceDefaults.accentHex

                struct Mock {
                    var themeRawValue: String

                    var accentHex: String

                    init(themeRawValue: String = "system", accentHex: String = AppearanceDefaults.accentHex) {
                        self.themeRawValue = themeRawValue
                        self.accentHex = accentHex
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Isolation

    /// Tipo aninhado não herda isolação de global actor, então um provider `@MainActor` deixaria
    /// o Mock nonisolated — e ele não conseguiria ler os serviços `@MainActor` que o provider lê.
    func testMainActorProviderProducesMainActorMock() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @MainActor
            @Mockable
            struct SyncProvider {
                @State var isBusy: Bool = false
            }
            """,
            expandedSource: """
            @MainActor
            struct SyncProvider {
                @State var isBusy: Bool = false

                @MainActor
                struct Mock {
                    var isBusy: Bool

                    init(isBusy: Bool = false) {
                        self.isBusy = isBusy
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @Query properties

    func testQueryPropertiesAreRequiredInInit() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct ListProvider {
                @Query var items: [Item]
                @State var searchText: String = ""
            }
            """,
            expandedSource: """
            struct ListProvider {
                @Query var items: [Item]
                @State var searchText: String = ""

                struct Mock {
                    var items: [Item]

                    var searchText: String

                    init(items: [Item], searchText: String = "") {
                        self.items = items
                        self.searchText = searchText
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @Environment excluded

    func testEnvironmentPropertiesAreExcluded() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                @State var name: String = ""
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator
            }
            """,
            expandedSource: """
            struct DetailProvider {
                @State var name: String = ""
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator

                struct Mock {
                    var name: String

                    init(name: String = "") {
                        self.name = name
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @Environment with type annotation included

    func testEnvironmentWithTypeAnnotationIsIncluded() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                @State var name: String = ""
                @Environment(\\.modelContext) var modelContext: ModelContext
                @Environment(\\.navigator) var navigator: NavigatorAPI
            }
            """,
            expandedSource: """
            struct DetailProvider {
                @State var name: String = ""
                @Environment(\\.modelContext) var modelContext: ModelContext
                @Environment(\\.navigator) var navigator: NavigatorAPI

                struct Mock {
                    var name: String

                    var modelContext: ModelContext

                    var navigator: NavigatorAPI

                    init(modelContext: ModelContext, navigator: NavigatorAPI, name: String = "") {
                        self.name = name
                        self.modelContext = modelContext
                        self.navigator = navigator
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Regular properties (dependencies)

    func testRegularPropertiesAreRequiredInInit() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                let repository = TodoRepository()
                @State var todos: [Todo] = []
            }
            """,
            expandedSource: """
            struct HomeProvider {
                let repository = TodoRepository()
                @State var todos: [Todo] = []

                struct Mock {
                    var repository: TodoRepository

                    var todos: [Todo]

                    init(repository: TodoRepository, todos: [Todo] = []) {
                        self.repository = repository
                        self.todos = todos
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Computed properties copied

    func testComputedPropertiesCopiedAsIs() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct StatsProvider {
                @State var items: [Item] = []

                var total: Int {
                    items.count
                }
            }
            """,
            expandedSource: """
            struct StatsProvider {
                @State var items: [Item] = []

                var total: Int {
                    items.count
                }

                struct Mock {
                    var items: [Item]

                    var total: Int {
                        items.count
                    }

                    init(items: [Item] = []) {
                        self.items = items
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Functions become mutating

    func testFunctionsBecomeMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct CounterProvider {
                @State var count: Int = 0

                func increment() {
                    count += 1
                }

                func reset() {
                    count = 0
                }
            }
            """,
            expandedSource: """
            struct CounterProvider {
                @State var count: Int = 0

                func increment() {
                    count += 1
                }

                func reset() {
                    count = 0
                }

                struct Mock {
                    var count: Int

                    mutating func increment() {
                        count += 1
                    }

                    mutating func reset() {
                        count = 0
                    }

                    init(count: Int = 0) {
                        self.count = count
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Functions referencing untyped @Environment are excluded

    func testFunctionsReferencingUntypedEnvironmentAreExcluded() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct TestProvider {
                @State var count: Int = 0
                @Environment(\\.modelContext) var modelContext

                func pureFunction() {
                    count += 1
                }

                func sideEffect() {
                    modelContext.insert(count)
                }
            }
            """,
            expandedSource: """
            struct TestProvider {
                @State var count: Int = 0
                @Environment(\\.modelContext) var modelContext

                func pureFunction() {
                    count += 1
                }

                func sideEffect() {
                    modelContext.insert(count)
                }

                struct Mock {
                    var count: Int

                    mutating func pureFunction() {
                        count += 1
                    }

                    init(count: Int = 0) {
                        self.count = count
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Functions referencing typed @Environment are included

    func testFunctionsReferencingTypedEnvironmentAreIncluded() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct TestProvider {
                @State var count: Int = 0
                @Environment(\\.modelContext) var modelContext: ModelContext

                func pureFunction() {
                    count += 1
                }

                func sideEffect() {
                    modelContext.insert(count)
                }
            }
            """,
            expandedSource: """
            struct TestProvider {
                @State var count: Int = 0
                @Environment(\\.modelContext) var modelContext: ModelContext

                func pureFunction() {
                    count += 1
                }

                func sideEffect() {
                    modelContext.insert(count)
                }

                struct Mock {
                    var count: Int

                    var modelContext: ModelContext

                    mutating func pureFunction() {
                        count += 1
                    }

                    mutating func sideEffect() {
                        modelContext.insert(count)
                    }

                    init(modelContext: ModelContext, count: Int = 0) {
                        self.count = count
                        self.modelContext = modelContext
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @Bindable property

    func testBindablePropertyIsRequired() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                @Bindable var item: Item

                func save() {
                    item.name = "Updated"
                }
            }
            """,
            expandedSource: """
            struct DetailProvider {
                @Bindable var item: Item

                func save() {
                    item.name = "Updated"
                }

                struct Mock {
                    var item: Item

                    mutating func save() {
                        item.name = "Updated"
                    }

                    init(item: Item) {
                        self.item = item
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Rejects class

    func testRejectsClass() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            class NotAStruct {
                @State var x: Int = 0
            }
            """,
            expandedSource: """
            class NotAStruct {
                @State var x: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Mockable can only be applied to a struct", line: 1, column: 1),
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Empty struct

    func testEmptyStructGeneratesEmptyMock() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct EmptyProvider {
            }
            """,
            expandedSource: """
            struct EmptyProvider {

                struct Mock {

                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Let with explicit type

    func testLetWithExplicitType() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                let habitID: UUID
            }
            """,
            expandedSource: """
            struct DetailProvider {
                let habitID: UUID

                struct Mock {
                    var habitID: UUID

                    init(habitID: UUID) {
                        self.habitID = habitID
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Type inference

    func testInfersLiteralTypes() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct ConfigProvider {
                let timeout = 30
                let ratio = 0.5
                let label = "Hello"
                let verbose = true
            }
            """,
            expandedSource: """
            struct ConfigProvider {
                let timeout = 30
                let ratio = 0.5
                let label = "Hello"
                let verbose = true

                struct Mock {
                    var timeout: Int

                    var ratio: Double

                    var label: String

                    var verbose: Bool

                    init(timeout: Int, ratio: Double, label: String, verbose: Bool) {
                        self.timeout = timeout
                        self.ratio = ratio
                        self.label = label
                        self.verbose = verbose
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Let with initializer (inferred type from constructor)

    func testLetWithConstructorInferredType() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                let repository = TodoRepository()
            }
            """,
            expandedSource: """
            struct HomeProvider {
                let repository = TodoRepository()

                struct Mock {
                    var repository: TodoRepository

                    init(repository: TodoRepository) {
                        self.repository = repository
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Full Provider with function exclusion

    func testFullProviderExcludesEnvironmentFunctions() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                @Query var habits: [Habit]
                @State var selectedDate: Date = Date.now
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator

                var filteredHabits: [Habit] {
                    habits.filter { $0.isScheduled(for: selectedDate) }
                }

                func toggleCompletion(_ habit: Habit) {
                    modelContext.insert(habit)
                }

                func goToDetail(_ habit: Habit) {
                    navigator.push(habit.id)
                }
            }
            """,
            expandedSource: """
            struct HomeProvider {
                @Query var habits: [Habit]
                @State var selectedDate: Date = Date.now
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator

                var filteredHabits: [Habit] {
                    habits.filter { $0.isScheduled(for: selectedDate) }
                }

                func toggleCompletion(_ habit: Habit) {
                    modelContext.insert(habit)
                }

                func goToDetail(_ habit: Habit) {
                    navigator.push(habit.id)
                }

                struct Mock {
                    var habits: [Habit]

                    var selectedDate: Date

                    var filteredHabits: [Habit] {
                        habits.filter {
                            $0.isScheduled(for: selectedDate)
                        }
                    }

                    init(habits: [Habit], selectedDate: Date = Date.now) {
                        self.habits = habits
                        self.selectedDate = selectedDate
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
