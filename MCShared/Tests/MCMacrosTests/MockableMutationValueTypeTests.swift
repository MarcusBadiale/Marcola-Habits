import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin
#endif

/// Método mutante da stdlib (`toggle`, `append`, `insert`…), `inout`, subscript e closure.
///
/// O nome do método sozinho não decide: `selectedDays.insert(day)` muta e
/// `modelContext.insert(habit)` não. Quem separa os dois é o **tipo declarado** da raiz — nominal
/// desconhecido é tratado como referência.
final class MockableMutationValueTypeTests: XCTestCase {

    // MARK: - allowlist + gate de tipo

    func testMutatingMethodOnStoredValueTypeIsMutatingButDependencyCallIsNot() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct PickerProvider {
                @State var selectedDays: Set<Int> = []
                @State var isOn: Bool = false
                @Environment(\\.modelContext) var modelContext: ModelContext

                func select(_ day: Int) {
                    selectedDays.insert(day)
                }

                func flip() {
                    isOn.toggle()
                }

                func store(_ item: Item) {
                    modelContext.insert(item)
                }
            }
            """,
            expandedSource: """
            struct PickerProvider {
                @State var selectedDays: Set<Int> = []
                @State var isOn: Bool = false
                @Environment(\\.modelContext) var modelContext: ModelContext

                func select(_ day: Int) {
                    selectedDays.insert(day)
                }

                func flip() {
                    isOn.toggle()
                }

                func store(_ item: Item) {
                    modelContext.insert(item)
                }

                struct Mock {
                    var selectedDays: Set<Int>

                    var isOn: Bool

                    var modelContext: ModelContext

                    mutating func select(_ day: Int) {
                        selectedDays.insert(day)
                    }

                    mutating func flip() {
                        isOn.toggle()
                    }

                    func store(_ item: Item) {
                        modelContext.insert(item)
                    }

                    init(modelContext: ModelContext, selectedDays: Set<Int> = [], isOn: Bool = false) {
                        self.selectedDays = selectedDays
                        self.isOn = isOn
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

    // MARK: - toggle em local não conta

    /// `HomeProvider.toggleCompletion` faz exatamente isto: `log` é local e `@Model` é classe.
    func testMutatingMethodOnLocalIsNotMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct ToggleProvider {
                @Query var logs: [Log]

                func toggleFirst() {
                    guard let log = logs.first else {
                        return
                    }
                    log.completed.toggle()
                }
            }
            """,
            expandedSource: """
            struct ToggleProvider {
                @Query var logs: [Log]

                func toggleFirst() {
                    guard let log = logs.first else {
                        return
                    }
                    log.completed.toggle()
                }

                struct Mock {
                    var logs: [Log]

                    func toggleFirst() {
                        guard let log = logs.first else {
                            return
                        }
                        log.completed.toggle()
                    }

                    init(logs: [Log]) {
                        self.logs = logs
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

    // MARK: - inout, subscript e closure

    func testInoutSubscriptAndClosureAreMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct BulkProvider {
                @State var names: [String] = []
                @State var count: Int = 0

                func rename() {
                    names[0] = "novo"
                }

                func sortNames() {
                    names.sort(by: <)
                }

                func tally() {
                    names.forEach { _ in
                        count += 1
                    }
                }

                func reorder() {
                    swap(&names, &names)
                }
            }
            """,
            expandedSource: """
            struct BulkProvider {
                @State var names: [String] = []
                @State var count: Int = 0

                func rename() {
                    names[0] = "novo"
                }

                func sortNames() {
                    names.sort(by: <)
                }

                func tally() {
                    names.forEach { _ in
                        count += 1
                    }
                }

                func reorder() {
                    swap(&names, &names)
                }

                struct Mock {
                    var names: [String]

                    var count: Int

                    mutating func rename() {
                        names[0] = "novo"
                    }

                    mutating func sortNames() {
                        names.sort(by: <)
                    }

                    mutating func tally() {
                        names.forEach { _ in
                            count += 1
                        }
                    }

                    mutating func reorder() {
                        swap(&names, &names)
                    }

                    init(names: [String] = [], count: Int = 0) {
                        self.names = names
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
}
