import SwiftSyntax

/// Varre o corpo de UMA função procurando escrita em propriedade armazenada do `Mock`, e coleta as
/// chamadas a outras funções do mesmo provider (pro fecho transitivo do `MutationAnalyzer`).
///
/// A análise é sintática — o macro não tem sistema de tipos. Em cada ponto onde falta informação,
/// o desempate é pelo lado seguro: marcar de menos faz o `Mock` não compilar; marcar demais só
/// devolve o incômodo do `mutating` naquela função.
final class MutationScanner: SyntaxVisitor {

    /// Nome → tipo declarado das props que viram `var` armazenada no Mock.
    /// O tipo é o que separa `selectedDays.insert(day)` de `modelContext.insert(habit)`.
    private let stored: [String: TypeSyntax]
    private let functionNames: Set<String>

    private(set) var mutates = false
    private(set) var calledFunctions: Set<String> = []

    init(stored: [String: TypeSyntax], functionNames: Set<String>) {
        self.stored = stored
        self.functionNames = functionNames
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: - Atribuição

    /// No corpo cru de um macro o *operator folding* ainda não rodou (é do SwiftOperators, e o
    /// compilador só o chama depois), então `count += 1` NÃO é um `InfixOperatorExprSyntax`: é um
    /// `SequenceExprSyntax` de três elementos. Toda a leitura de atribuição acontece aqui.
    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        let elements = Array(node.elements)
        for (index, element) in elements.enumerated() where index > 0 && isWriteOperator(element) {
            // Atribuição é o operador de menor precedência, então o LHS é sempre o elemento
            // imediatamente anterior. Pegar o anterior (e não o primeiro) trata `a = b = c`.
            markWrite(to: elements[index - 1])
        }
        return .visitChildren
    }

    // MARK: - inout

    override func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
        markWrite(to: node.expression)
        return .visitChildren
    }

    // MARK: - Método mutante da stdlib

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
           let base = member.base,
           Self.mutatingMethods.contains(member.declName.baseName.text),
           let root = Self.rootName(of: base),
           let type = stored[root],
           Self.looksLikeValueType(type) {
            mutates = true
        }
        return .visitChildren
    }

    // MARK: - Grafo de chamadas

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.baseName.text
        guard functionNames.contains(name) else { return .visitChildren }

        // `log.count` também produz um DeclReferenceExpr (é o `declName` do MemberAccess). Só
        // interessa referência solta (`logFor(h)`, `map(logFor)`) ou qualificada por `self`.
        if let member = node.parent?.as(MemberAccessExprSyntax.self), member.declName.id == node.id {
            guard let base = member.base, Self.isSelfReference(base) else { return .visitChildren }
        }

        calledFunctions.insert(name)
        return .visitChildren
    }

    // MARK: - Helpers

    private func isWriteOperator(_ expr: ExprSyntax) -> Bool {
        if expr.is(AssignmentExprSyntax.self) { return true }
        guard let binary = expr.as(BinaryOperatorExprSyntax.self) else { return false }
        let text = binary.operator.text
        // `+=`, `-=`, `*=` são escrita. `==`, `>=`, `~=` não são — e aparecem de verdade
        // (`AppearanceProvider.isSelected`, `CategoryDetailProvider.isCompleted`).
        return text.hasSuffix("=") && !Self.comparisonOperators.contains(text)
    }

    private func markWrite(to expr: ExprSyntax) {
        if let tuple = expr.as(TupleExprSyntax.self), tuple.elements.count > 1 {
            for element in tuple.elements { markWrite(to: element.expression) }
            return
        }
        guard let root = Self.rootName(of: expr) else { return }
        if root == "self" || stored[root] != nil { mutates = true }
    }

    /// Desce uma cadeia de member access / subscript / call até o identificador da base.
    ///
    /// `self.x` e `x` colapsam no mesmo nome — é o mesmo caso. Devolve `nil` pra membro implícito
    /// (`.foo`), que é estático e nunca é alvo de escrita em `self`.
    private static func rootName(of expr: ExprSyntax) -> String? {
        if let member = expr.as(MemberAccessExprSyntax.self) {
            guard let base = member.base else { return nil }
            if isSelfReference(base) { return member.declName.baseName.text }
            return rootName(of: base)
        }
        if let subscriptCall = expr.as(SubscriptCallExprSyntax.self) {
            return rootName(of: subscriptCall.calledExpression)
        }
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return rootName(of: call.calledExpression)
        }
        if let force = expr.as(ForceUnwrapExprSyntax.self) {
            return rootName(of: force.expression)
        }
        if let optional = expr.as(OptionalChainingExprSyntax.self) {
            return rootName(of: optional.expression)
        }
        if let tryExpr = expr.as(TryExprSyntax.self) {
            return rootName(of: tryExpr.expression)
        }
        if let awaitExpr = expr.as(AwaitExprSyntax.self) {
            return rootName(of: awaitExpr.expression)
        }
        if let tuple = expr.as(TupleExprSyntax.self), tuple.elements.count == 1,
           let only = tuple.elements.first {
            return rootName(of: only.expression)
        }
        if let ref = expr.as(DeclReferenceExprSyntax.self) {
            return ref.baseName.text
        }
        return nil
    }

    private static func isSelfReference(_ expr: ExprSyntax) -> Bool {
        expr.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)
    }

    /// Heurística de "tipo declarado parece value type". Nominal desconhecido (`ModelContext`,
    /// `NavigatorAPI`, `HabitModel`) é tratado como referência — é o que impede
    /// `modelContext.insert(habit)` de virar mutação.
    private static func looksLikeValueType(_ type: TypeSyntax) -> Bool {
        if type.is(ArrayTypeSyntax.self) || type.is(DictionaryTypeSyntax.self) { return true }
        if type.is(TupleTypeSyntax.self) { return true }
        if let optional = type.as(OptionalTypeSyntax.self) {
            return looksLikeValueType(optional.wrappedType)
        }
        if let implicitlyUnwrapped = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return looksLikeValueType(implicitlyUnwrapped.wrappedType)
        }
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return valueTypeNames.contains(identifier.name.text)
        }
        return false
    }

    private static let comparisonOperators: Set<String> = ["==", "!=", "<=", ">=", "~=", "===", "!=="]

    private static let mutatingMethods: Set<String> = [
        "append", "insert", "remove", "removeAll", "removeFirst", "removeLast", "removeValue",
        "updateValue", "sort", "reverse", "shuffle", "swapAt", "popLast", "toggle", "negate",
        "formUnion", "formIntersection", "formSymmetricDifference", "subtract", "reserveCapacity",
    ]

    private static let valueTypeNames: Set<String> = [
        "Array", "Set", "Dictionary", "Bool", "Int", "Double", "Float", "String", "Character",
        "Date", "UUID", "Data", "URL", "Decimal", "IndexSet", "Range", "ClosedRange",
    ]
}
