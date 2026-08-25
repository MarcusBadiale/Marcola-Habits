import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin
#endif

/// Fecho transitivo: quem chama função mutante também é `mutating`.
///
/// Sem isso, `HomeProvider.isCompleted` → `logFor(_:)` só acerta por sorte (o `logFor` é puro) e
/// quebraria no primeiro helper que passasse a mutar.
final class MockableMutationPropagationTests: XCTestCase {

    // MARK: - Propagação por 2 saltos

    /// `a` chama `b` chama `c`, e só `c` muta. As três viram `mutating`. Repare que `a` é declarada
    /// ANTES de `b` e `c` — a análise não pode depender da ordem de declaração.
    func testMutationPropagatesTwoHops() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct ChainProvider {
                @State var count: Int = 0

                func a() {
                    b()
                }

                func b() {
                    c()
                }

                func c() {
                    count += 1
                }
            }
            """,
            expandedSource: """
            struct ChainProvider {
                @State var count: Int = 0

                func a() {
                    b()
                }

                func b() {
                    c()
                }

                func c() {
                    count += 1
                }

                struct Mock {
                    var count: Int

                    mutating func a() {
                        b()
                    }

                    mutating func b() {
                        c()
                    }

                    mutating func c() {
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

    // MARK: - Callee puro não infecta

    /// O shape do `HomeProvider`: `isCompleted` chama `logFor`, que só lê. Nenhuma das duas é
    /// `mutating`.
    func testNonMutatingCalleeDoesNotInfect() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                @Query var logs: [Log]

                func isCompleted() -> Bool {
                    logFor() != nil
                }

                func logFor() -> Log? {
                    logs.first
                }
            }
            """,
            expandedSource: """
            struct HomeProvider {
                @Query var logs: [Log]

                func isCompleted() -> Bool {
                    logFor() != nil
                }

                func logFor() -> Log? {
                    logs.first
                }

                struct Mock {
                    var logs: [Log]

                    func isCompleted() -> Bool {
                        logFor() != nil
                    }

                    func logFor() -> Log? {
                        logs.first
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

    // MARK: - Recursão termina

    func testRecursiveFunctionTerminates() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct RecursiveProvider {
                @State var count: Int = 0

                func countdown(_ n: Int) {
                    if n > 0 {
                        countdown(n - 1)
                    }
                }
            }
            """,
            expandedSource: """
            struct RecursiveProvider {
                @State var count: Int = 0

                func countdown(_ n: Int) {
                    if n > 0 {
                        countdown(n - 1)
                    }
                }

                struct Mock {
                    var count: Int

                    func countdown(_ n: Int) {
                        if n > 0 {
                            countdown(n - 1)
                        }
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

    // MARK: - Computed religada num local

    /// O shape do `HabitDetailProvider.archiveHabit`. `habit` é computed — não vira `var`
    /// armazenada no Mock —, e o `guard let` a religa num local de tipo classe. Escrever nele não
    /// muta o `self`.
    func testAssignmentToRebindComputedPropertyIsNotMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                @Query var items: [Item]

                var item: Item? {
                    items.first
                }

                func archive() {
                    guard let item else {
                        return
                    }
                    item.isArchived = true
                }
            }
            """,
            expandedSource: """
            struct DetailProvider {
                @Query var items: [Item]

                var item: Item? {
                    items.first
                }

                func archive() {
                    guard let item else {
                        return
                    }
                    item.isArchived = true
                }

                struct Mock {
                    var items: [Item]

                    var item: Item? {
                        items.first
                    }

                    func archive() {
                        guard let item else {
                            return
                        }
                        item.isArchived = true
                    }

                    init(items: [Item]) {
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
}
