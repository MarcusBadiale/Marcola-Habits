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

        var properties: [MockProperty] = []
        var functions: [MockFunction] = []

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
            if let func_ = MockClassifier.classifyFunction(member: member) {
                // Skip functions that reference excluded @Environment properties
                if !MockClassifier.functionReferencesExcluded(member: member, excludedNames: excludedNames) {
                    functions.append(func_)
                }
            }
        }

        let mock = generateMock(properties: properties, functions: functions)
        return [mock]
    }

    private static func generateMock(
        properties: [MockProperty],
        functions: [MockFunction]
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
            members.append("    mutating \(func_.originalSource)")
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

        return """
        struct Mock {
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
