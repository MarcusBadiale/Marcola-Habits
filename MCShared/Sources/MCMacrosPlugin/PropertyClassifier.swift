import SwiftSyntax

// MARK: - Property Kind

enum MockPropertyKind {
    case state       // @State → var with default in Mock init
    case query       // @Query → var, required in Mock init
    case environment // @Environment → excluded from Mock
    case bindable    // @Bindable → var, required in Mock init
    case computed    // var x: T { ... } → copied as-is
    case regular     // let x: T = Foo() → var, required in Mock init
}

// MARK: - Classified Property

struct MockProperty {
    let kind: MockPropertyKind
    let name: String
    let type: TypeSyntax
    let defaultValue: ExprSyntax?
    let originalSource: String
}

// MARK: - Classified Function

struct MockFunction {
    let name: String
    let originalSource: String
}

// MARK: - Classifier

enum MockClassifier {

    private static let knownWrappers: Set<String> = ["State", "Query", "Environment", "Bindable"]

    static func classifyProperty(member: MemberBlockItemSyntax) -> MockProperty? {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        let name = pattern.identifier.trimmedDescription
        let wrapperName = findPropertyWrapper(in: varDecl.attributes)

        // @Environment with type annotation → include in Mock as required param
        // @Environment without type annotation → exclude (can't determine type)
        if wrapperName == "Environment" {
            if let explicitType = binding.typeAnnotation?.type {
                return MockProperty(
                    kind: .regular,
                    name: name,
                    type: explicitType,
                    defaultValue: nil,
                    originalSource: varDecl.trimmedDescription
                )
            } else {
                let dummyType = TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
                return MockProperty(
                    kind: .environment,
                    name: name,
                    type: dummyType,
                    defaultValue: nil,
                    originalSource: varDecl.trimmedDescription
                )
            }
        }

        // Computed property
        if let accessorBlock = binding.accessorBlock {
            if case .getter = accessorBlock.accessors {
                guard let type = binding.typeAnnotation?.type else { return nil }
                return MockProperty(
                    kind: .computed,
                    name: name,
                    type: type,
                    defaultValue: nil,
                    originalSource: varDecl.trimmedDescription
                )
            }
            if case let .accessors(accessorList) = accessorBlock.accessors {
                let kinds = accessorList.map { $0.accessorSpecifier.trimmedDescription }
                if kinds.contains("get") && !kinds.contains("set") &&
                   !kinds.contains("willSet") && !kinds.contains("didSet") {
                    guard let type = binding.typeAnnotation?.type else { return nil }
                    return MockProperty(
                        kind: .computed,
                        name: name,
                        type: type,
                        defaultValue: nil,
                        originalSource: varDecl.trimmedDescription
                    )
                }
            }
        }

        // Resolve type
        let type: TypeSyntax
        if let explicit = binding.typeAnnotation?.type {
            type = explicit
        } else if let inferred = inferType(from: binding) {
            type = inferred
        } else {
            return nil // Can't determine type → skip
        }

        let defaultValue = binding.initializer?.value

        // Classify by wrapper
        switch wrapperName {
        case "State":
            return MockProperty(kind: .state, name: name, type: type, defaultValue: defaultValue, originalSource: varDecl.trimmedDescription)
        case "Query":
            return MockProperty(kind: .query, name: name, type: type, defaultValue: nil, originalSource: varDecl.trimmedDescription)
        case "Bindable":
            return MockProperty(kind: .bindable, name: name, type: type, defaultValue: nil, originalSource: varDecl.trimmedDescription)
        default:
            return MockProperty(kind: .regular, name: name, type: type, defaultValue: defaultValue, originalSource: varDecl.trimmedDescription)
        }
    }

    static func classifyFunction(member: MemberBlockItemSyntax) -> MockFunction? {
        guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { return nil }
        return MockFunction(
            name: funcDecl.name.trimmedDescription,
            originalSource: funcDecl.trimmedDescription
        )
    }

    /// Checks if a function body references any of the excluded property names.
    static func functionReferencesExcluded(member: MemberBlockItemSyntax, excludedNames: Set<String>) -> Bool {
        guard let funcDecl = member.decl.as(FunctionDeclSyntax.self),
              let body = funcDecl.body else { return false }
        if excludedNames.isEmpty { return false }
        for token in body.tokens(viewMode: .sourceAccurate) {
            if case .identifier(let text) = token.tokenKind, excludedNames.contains(text) {
                return true
            }
        }
        return false
    }

    // MARK: - Helpers

    private static func findPropertyWrapper(in attributes: AttributeListSyntax) -> String? {
        for attribute in attributes {
            if let attr = attribute.as(AttributeSyntax.self),
               let identType = attr.attributeName.as(IdentifierTypeSyntax.self) {
                let name = identType.name.trimmedDescription
                if knownWrappers.contains(name) { return name }
            }
        }
        return nil
    }

    private static func inferType(from binding: PatternBindingSyntax) -> TypeSyntax? {
        guard let initializer = binding.initializer?.value else { return nil }

        if initializer.is(IntegerLiteralExprSyntax.self) {
            return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Int")))
        }
        if initializer.is(FloatLiteralExprSyntax.self) {
            return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Double")))
        }
        if initializer.is(StringLiteralExprSyntax.self) {
            return TypeSyntax(IdentifierTypeSyntax(name: .identifier("String")))
        }
        if initializer.is(BooleanLiteralExprSyntax.self) {
            return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Bool")))
        }

        if let call = initializer.as(FunctionCallExprSyntax.self),
           let ref = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            let name = ref.baseName.trimmedDescription
            if name.first?.isUppercase == true {
                return TypeSyntax(IdentifierTypeSyntax(name: .identifier(name)))
            }
        }

        if let member = initializer.as(MemberAccessExprSyntax.self),
           let base = member.base?.as(DeclReferenceExprSyntax.self) {
            let name = base.baseName.trimmedDescription
            if name.first?.isUppercase == true {
                return TypeSyntax(IdentifierTypeSyntax(name: .identifier(name)))
            }
        }

        return nil
    }
}
