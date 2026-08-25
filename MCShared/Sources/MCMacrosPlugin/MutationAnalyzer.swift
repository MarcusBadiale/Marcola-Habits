import SwiftSyntax

/// Decide quais funções do provider precisam de `mutating` no `Mock`.
///
/// Só escrita em propriedade **armazenada** conta. `.computed` fica de fora de propósito:
/// `HabitDetailProvider.archiveHabit` religa a computed `habit` num `guard let` e escreve nela — o
/// alvo é o objeto (`@Model` é classe), não o `self` do Mock.
enum MutationAnalyzer {

    static func mutatingFunctionNames(
        functions: [FunctionDeclSyntax],
        storedProperties: [String: TypeSyntax]
    ) -> Set<String> {
        let allNames = Set(functions.map { $0.name.trimmedDescription })

        var direct: Set<String> = []
        var callees: [String: Set<String>] = [:]

        for decl in functions {
            let name = decl.name.trimmedDescription
            // `static func` não toca estado de instância — e `mutating static func` nem compila.
            guard !isStatic(decl), let body = decl.body else { continue }

            let scanner = MutationScanner(stored: storedProperties, functionNames: allNames)
            scanner.walk(body)

            if scanner.mutates { direct.insert(name) }
            // Sobrecargas colapsam por nome: se uma muta, todas as homônimas viram `mutating`.
            callees[name, default: []].formUnion(scanner.calledFunctions)
        }

        return propagate(seed: direct, callees: callees, allNames: allNames)
    }

    static func isStatic(_ decl: FunctionDeclSyntax) -> Bool {
        decl.modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }
    }

    /// Fecho transitivo: se `a()` chama `b()` e `b()` muta, `a()` também é `mutating`.
    ///
    /// Termina sempre — `result` só cresce e é limitado por `allNames`. Recursão direta (`f`→`f`)
    /// e mútua (`a`↔`b`) não travam: um ciclo sem semente mutante nunca entra.
    private static func propagate(
        seed: Set<String>,
        callees: [String: Set<String>],
        allNames: Set<String>
    ) -> Set<String> {
        var result = seed
        var changed = true
        while changed {
            changed = false
            for name in allNames where !result.contains(name) {
                guard let called = callees[name], !called.isDisjoint(with: result) else { continue }
                result.insert(name)
                changed = true
            }
        }
        return result
    }
}
