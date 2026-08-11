import SwiftSyntaxMacros

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin

let testMacros: [String: Macro.Type] = [
    "Mockable": MockableMacro.self,
]
#endif
