import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin
#endif

/// Como o `mutating` é emitido.
///
/// O modificador entra na lista de modificadores do nó, e não concatenado na string: concatenar
/// gerava `mutating static func` (que não compila) e `mutating @discardableResult func` (que nem
/// parseia).
final class MockableMutationEmissionTests: XCTestCase {

    // MARK: - static nunca é mutating

    func testStaticFunctionIsNeverMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct FactoryProvider {
                @State var count: Int = 0

                static func makeDefault() -> Int {
                    0
                }

                func bump() {
                    count += 1
                }
            }
            """,
            expandedSource: """
            struct FactoryProvider {
                @State var count: Int = 0

                static func makeDefault() -> Int {
                    0
                }

                func bump() {
                    count += 1
                }

                struct Mock {
                    var count: Int

                    static func makeDefault() -> Int {
                        0
                    }

                    mutating func bump() {
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

    // MARK: - private mutating func, nessa ordem

    func testPrivateFunctionKeepsModifierOrder() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct PrivateProvider {
                @State var count: Int = 0

                private func bump() {
                    count += 1
                }
            }
            """,
            expandedSource: """
            struct PrivateProvider {
                @State var count: Int = 0

                private func bump() {
                    count += 1
                }

                struct Mock {
                    var count: Int

                    private mutating func bump() {
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

    // MARK: - atributo vem antes do modificador

    func testAttributedFunctionKeepsAttributeBeforeMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct ResultProvider {
                @State var count: Int = 0

                @discardableResult
                func bump() -> Int {
                    count += 1
                    return count
                }
            }
            """,
            expandedSource: """
            struct ResultProvider {
                @State var count: Int = 0

                @discardableResult
                func bump() -> Int {
                    count += 1
                    return count
                }

                struct Mock {
                    var count: Int

                    @discardableResult
                    mutating func bump() -> Int {
                        count += 1
                        return count
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
