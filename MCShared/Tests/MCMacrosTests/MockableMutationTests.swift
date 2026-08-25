import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin
#endif

/// O núcleo da detecção: o que é escrita em propriedade armazenada e o que só parece ser.
///
/// Só o que escreve numa prop que vira `var` armazenada no `Mock` exige `mutating`. Escrever num
/// local ou num parâmetro de tipo classe (`@Model` é classe) não muta o `self` do Mock.
final class MockableMutationTests: XCTestCase {

    // MARK: - Função pura

    func testPureFunctionIsNotMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct NavProvider {
                @State var count: Int = 0
                @Environment(\\.navigator) var navigator: NavigatorAPI

                func goToDetail() {
                    navigator.push("route")
                }
            }
            """,
            expandedSource: """
            struct NavProvider {
                @State var count: Int = 0
                @Environment(\\.navigator) var navigator: NavigatorAPI

                func goToDetail() {
                    navigator.push("route")
                }

                struct Mock {
                    var count: Int

                    var navigator: NavigatorAPI

                    func goToDetail() {
                        navigator.push("route")
                    }

                    init(navigator: NavigatorAPI, count: Int = 0) {
                        self.count = count
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

    // MARK: - Atribuição qualificada por self

    func testSelfQualifiedAssignmentIsMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct CounterProvider {
                @State var count: Int = 0

                func reset() {
                    self.count = 0
                }
            }
            """,
            expandedSource: """
            struct CounterProvider {
                @State var count: Int = 0

                func reset() {
                    self.count = 0
                }

                struct Mock {
                    var count: Int

                    mutating func reset() {
                        self.count = 0
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

    // MARK: - Atribuição composta vs comparação

    /// `*=` é escrita, `>=` não é. O macro só vê a sequência de tokens, então a distinção é uma
    /// lista de operadores de comparação — sem ela, todo predicado do provider viraria `mutating`.
    func testCompoundAssignmentIsMutatingButComparisonIsNot() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct TotalProvider {
                @State var total: Int = 1

                func double() {
                    total *= 2
                }

                func isBig() -> Bool {
                    total >= 10
                }
            }
            """,
            expandedSource: """
            struct TotalProvider {
                @State var total: Int = 1

                func double() {
                    total *= 2
                }

                func isBig() -> Bool {
                    total >= 10
                }

                struct Mock {
                    var total: Int

                    mutating func double() {
                        total *= 2
                    }

                    func isBig() -> Bool {
                        total >= 10
                    }

                    init(total: Int = 1) {
                        self.total = total
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

    // MARK: - Escrita em parâmetro (tipo classe)

    /// O shape de `ArchivedHabitsProvider.unarchive`: escreve no parâmetro, que é `@Model` — classe.
    func testAssignmentToParameterMemberIsNotMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct EditProvider {
                @State var count: Int = 0

                func touch(_ item: Item) {
                    item.name = "x"
                }
            }
            """,
            expandedSource: """
            struct EditProvider {
                @State var count: Int = 0

                func touch(_ item: Item) {
                    item.name = "x"
                }

                struct Mock {
                    var count: Int

                    func touch(_ item: Item) {
                        item.name = "x"
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
}
