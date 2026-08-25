import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public struct MockableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.as(StructDeclSyntax.self) != nil else {
            throw MockableError.message("@Mockable can only be applied to a struct")
        }

        // Tipo aninhado NÃO herda isolação de global actor do tipo que o contém, então um
        // `@MainActor` no provider deixaria o Mock nonisolated — e ele não conseguiria ler os
        // serviços @MainActor que o provider lê. Propagar explicitamente.
        let isMainActorIsolated = declaration.attributes.contains { attribute in
            attribute.as(AttributeSyntax.self)?
                .attributeName.as(IdentifierTypeSyntax.self)?
                .name.trimmedDescription == "MainActor"
        }

        var properties: [MockProperty] = []
        var functionDecls: [FunctionDeclSyntax] = []

        // Collect excluded @Environment property names
        let excludedNames: Set<String> = Set(
            declaration.memberBlock.members.compactMap { member -> String? in
                guard let prop = MockClassifier.classifyProperty(member: member),
                      prop.kind == .environment else { return nil }
                return prop.name
            }
        )

        for member in declaration.memberBlock.members {
            if let prop = MockClassifier.classifyProperty(member: member) {
                properties.append(prop)
            }
            if let funcDecl = MockClassifier.classifyFunction(member: member) {
                // Skip functions that reference excluded @Environment properties
                if !MockClassifier.functionReferencesExcluded(member: member, excludedNames: excludedNames) {
                    functionDecls.append(funcDecl)
                }
            }
        }

        // Só escrita em propriedade ARMAZENADA exige `mutating`. `.computed` fica de fora de
        // propósito: `HabitDetailProvider.archiveHabit` religa a computed `habit` num `guard let`
        // e escreve nela — o alvo é o objeto, não o `self` do Mock.
        let storedProperties: [String: TypeSyntax] = properties.reduce(into: [:]) { acc, prop in
            switch prop.kind {
            case .state, .query, .bindable, .regular: acc[prop.name] = prop.type
            case .computed, .environment: break
            }
        }

        let mutatingNames = MutationAnalyzer.mutatingFunctionNames(
            functions: functionDecls,
            storedProperties: storedProperties
        )

        let functions = functionDecls.map { decl in
            MockFunction(
                name: decl.name.trimmedDescription,
                decl: decl,
                mutatesState: mutatingNames.contains(decl.name.trimmedDescription)
            )
        }

        let mock = generateMock(
            properties: properties,
            functions: functions,
            isMainActorIsolated: isMainActorIsolated
        )
        return [mock]
    }

    private static func generateMock(
        properties: [MockProperty],
        functions: [MockFunction],
        isMainActorIsolated: Bool
    ) -> DeclSyntax {
        var members: [String] = []
        var requiredParams: [String] = []
        var optionalParams: [String] = []
        var initBody: [String] = []

        // Properties
        for prop in properties {
            let typeStr = prop.type.trimmedDescription

            switch prop.kind {
            case .computed:
                members.append("    \(prop.originalSource)")
                // No init param for computed properties

            case .state:
                members.append("    var \(prop.name): \(typeStr)")
                if let defaultValue = prop.defaultValue {
                    optionalParams.append("\(prop.name): \(typeStr) = \(defaultValue.trimmedDescription)")
                } else {
                    requiredParams.append("\(prop.name): \(typeStr)")
                }
                initBody.append("        self.\(prop.name) = \(prop.name)")

            case .query, .bindable:
                members.append("    var \(prop.name): \(typeStr)")
                requiredParams.append("\(prop.name): \(typeStr)")
                initBody.append("        self.\(prop.name) = \(prop.name)")

            case .regular:
                members.append("    var \(prop.name): \(typeStr)")
                requiredParams.append("\(prop.name): \(typeStr)")
                initBody.append("        self.\(prop.name) = \(prop.name)")

            case .environment:
                break // Excluded
            }
        }

        // Functions
        for func_ in functions {
            members.append("    \(func_.emittedSource)")
        }

        // Init
        let allParams = requiredParams + optionalParams
        if !allParams.isEmpty {
            members.append("""
                init(\(allParams.joined(separator: ", "))) {
            \(initBody.joined(separator: "\n"))
                }
            """)
        }

        let body = members.joined(separator: "\n\n")
        let isolation = isMainActorIsolated ? "@MainActor\n" : ""

        return """
        \(raw: isolation)struct Mock {
        \(raw: body)
        }
        """
    }
}

// MARK: - Error

enum MockableError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let text): return text
        }
    }
}
