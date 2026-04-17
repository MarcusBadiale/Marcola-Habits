import Testing
@testable import MCShared

@Suite("DependencyContainer")
struct DependencyContainerTests {

    @Test("register + resolve retorna instância do tipo correto")
    func registerAndResolve() {
        let container = DependencyContainer()
        container.register(String.self) { "marcola" }
        #expect(container.resolve(String.self) == "marcola")
    }

    @Test("factory é chamada a cada resolve — não é cached")
    func factoryCalledEachResolve() {
        let container = DependencyContainer()
        var callCount = 0
        container.register(Int.self) {
            callCount += 1
            return callCount
        }
        _ = container.resolve(Int.self)
        _ = container.resolve(Int.self)
        #expect(callCount == 2)
    }

    @Test("re-registro sobrescreve factory anterior")
    func reregistrationOverwrites() {
        let container = DependencyContainer()
        container.register(String.self) { "primeiro" }
        container.register(String.self) { "segundo" }
        #expect(container.resolve(String.self) == "segundo")
    }

    @Test("resolve de tipos diferentes são independentes")
    func differentTypesAreIndependent() {
        let container = DependencyContainer()
        container.register(String.self) { "texto" }
        container.register(Int.self) { 42 }
        #expect(container.resolve(String.self) == "texto")
        #expect(container.resolve(Int.self) == 42)
    }
}
