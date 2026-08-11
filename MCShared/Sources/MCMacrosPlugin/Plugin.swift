import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MCMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MockableMacro.self,
    ]
}
