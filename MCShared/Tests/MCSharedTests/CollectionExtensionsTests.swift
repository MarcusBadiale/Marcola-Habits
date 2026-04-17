import Testing
@testable import MCShared

@Suite("Collection Extensions")
struct CollectionExtensionsTests {

    // MARK: - Array safe subscript

    @Test("subscript(safe:) retorna elemento em índice válido", .tags(.extensions))
    func safeSubscriptValidIndex() {
        let array = ["a", "b", "c"]
        #expect(array[safe: 0] == "a")
        #expect(array[safe: 2] == "c")
    }

    @Test("subscript(safe:) retorna nil em índice fora dos limites", .tags(.extensions))
    func safeSubscriptOutOfBounds() {
        let array = ["a", "b", "c"]
        #expect(array[safe: 3] == nil)
        #expect(array[safe: 10] == nil)
    }

    @Test("subscript(safe:) retorna nil em coleção vazia", .tags(.extensions))
    func safeSubscriptEmptyCollection() {
        let empty: [Int] = []
        #expect(empty[safe: 0] == nil)
    }

    @Test("subscript(safe:) retorna nil em índice negativo", .tags(.extensions))
    func safeSubscriptNegativeIndex() {
        let array = [1, 2, 3]
        #expect(array[safe: -1] == nil)
    }

    // MARK: - String (Collection de Characters)

    @Test("subscript(safe:) funciona em String via startIndex", .tags(.extensions))
    func safeSubscriptString() {
        let word = "ABC"
        #expect(word[safe: word.startIndex] == "A")
    }
}
