import SwiftSyntax

/// Função do provider, já com o veredito do `MutationAnalyzer`.
struct MockFunction {
    let name: String
    let decl: FunctionDeclSyntax
    let mutatesState: Bool

    /// Fonte emitida no `Mock`.
    ///
    /// O `mutating` entra na lista de modificadores do nó, e não concatenado na string: concatenar
    /// quebra com atributo (`mutating @discardableResult func` não parseia) e com `static`
    /// (`mutating static func` não compila).
    var emittedSource: String {
        guard mutatesState, !MutationAnalyzer.isStatic(decl) else { return decl.trimmedDescription }

        var marked = decl.trimmed
        var modifier = DeclModifierSyntax(name: .keyword(.mutating), trailingTrivia: .space)

        if marked.modifiers.isEmpty {
            // Sem modificadores, a trivia de liderança mora no `func`. Transferir pro `mutating`,
            // senão a quebra de linha sai no meio da declaração.
            modifier.leadingTrivia = marked.funcKeyword.leadingTrivia
            marked.funcKeyword.leadingTrivia = []
        }

        marked.modifiers.append(modifier) // `private func` → `private mutating func`
        return marked.trimmedDescription
    }
}
