/// Gera um `Mock` struct interno que espelha propriedades e funções
/// do tipo anotado sem property wrappers do SwiftUI.
///
/// Uso:
/// ```swift
/// @Mockable
/// struct HomeProvider: MCProvider {
///     @State var count: Int = 0
///     @Query var items: [Item]
///     @Environment(\.modelContext) var modelContext
///     let repository: ItemRepository
///
///     var total: Int { items.count }
///     func increment() { count += 1 }
/// }
///
/// // Gerado:
/// // extension HomeProvider {
/// //     struct Mock {
/// //         var items: [Item]
/// //         var repository: ItemRepository
/// //         var count: Int = 0
/// //         var total: Int { items.count }
/// //         mutating func increment() { count += 1 }
/// //     }
/// // }
/// ```
@attached(member, names: named(Mock))
public macro Mockable() = #externalMacro(
    module: "MCMacrosPlugin",
    type: "MockableMacro"
)
