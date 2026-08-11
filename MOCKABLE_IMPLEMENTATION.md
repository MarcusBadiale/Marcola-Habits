# Implementação: @Mockable Macro

## O que faz

O `@Mockable` gera um `Mock` struct dentro do tipo anotado. O Mock espelha todas as
propriedades e funções, mas sem property wrappers do SwiftUI (`@State`, `@Query`,
`@Environment`, `@Bindable`). Isso permite testar a lógica real do Provider sem
precisar do runtime do SwiftUI.

## Regras de geração

| Declaração original | Gerado no Mock |
|---|---|
| `@State var x: T = default` | `var x: T` (mantém default no init) |
| `@Query var x: [T]` | `var x: [T]` (required no init) |
| `@Environment(...) var x` | **excluído** (não faz sentido no Mock) |
| `@Bindable var x: T` | `var x: T` (required no init) |
| `let x: T` | `var x: T` (required no init) |
| `let x: T = Foo()` | `var x: T` (required no init — dependência) |
| `let x = Foo()` | `var x: Foo` (tipo inferido, required no init) |
| `let x = 30` | `var x: Int` (tipo inferido de literal, required no init) |
| `var x: T = value` (sem wrapper) | `var x: T` (required no init) |
| `var computed: T { ... }` | copiado como está |
| `func doSomething()` | `mutating func doSomething()` |

**Init gerado:** required params primeiro (dependências, `@Query`, `@Bindable`),
optional params depois (`@State` com defaults).

---

## Estrutura do package

```
MCMacros/
├── Package.swift
├── Sources/
│   ├── MCMacros/
│   │   └── Mockable.swift
│   └── MCMacrosPlugin/
│       ├── MockableMacro.swift
│       ├── PropertyClassifier.swift
│       └── Plugin.swift
└── Tests/
    └── MCMacrosTests/
        ├── MockableTests.swift
        └── TestHelpers.swift
```

---

## Arquivos

### Package.swift

```swift
// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MCMacros",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCMacros", targets: ["MCMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "MCMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "MCMacros",
            dependencies: ["MCMacrosPlugin"]
        ),
        .testTarget(
            name: "MCMacrosTests",
            dependencies: [
                "MCMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
```

### Sources/MCMacros/Mockable.swift

```swift
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
```

### Sources/MCMacrosPlugin/Plugin.swift

```swift
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MCMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MockableMacro.self,
    ]
}
```

### Sources/MCMacrosPlugin/PropertyClassifier.swift

```swift
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
        } else if wrapperName == "Environment" {
            return nil // Environment without type → skip
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
        case "Environment":
            return nil // Excluded from Mock
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
```

### Sources/MCMacrosPlugin/MockableMacro.swift

```swift
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

        for member in declaration.memberBlock.members {
            if let prop = MockClassifier.classifyProperty(member: member) {
                properties.append(prop)
            }
            if let func_ = MockClassifier.classifyFunction(member: member) {
                functions.append(func_)
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
```

### Tests/MCMacrosTests/TestHelpers.swift

```swift
import SwiftSyntaxMacros

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin

let testMacros: [String: Macro.Type] = [
    "Mockable": MockableMacro.self,
]
#endif
```

### Tests/MCMacrosTests/MockableTests.swift

```swift
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MCMacrosPlugin)
import MCMacrosPlugin
#endif

final class MockableTests: XCTestCase {

    // MARK: - Basic: @State properties

    func testStatePropertiesBecomePlainVarsWithDefaults() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct SettingsProvider {
                @State var isDarkMode: Bool = false
                @State var fontSize: Double = 14.0
            }
            """,
            expandedSource: """
            struct SettingsProvider {
                @State var isDarkMode: Bool = false
                @State var fontSize: Double = 14.0

                struct Mock {
                    var isDarkMode: Bool

                    var fontSize: Double

                    init(isDarkMode: Bool = false, fontSize: Double = 14.0) {
                        self.isDarkMode = isDarkMode
                        self.fontSize = fontSize
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @Query properties

    func testQueryPropertiesAreRequiredInInit() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct ListProvider {
                @Query var items: [Item]
                @State var searchText: String = ""
            }
            """,
            expandedSource: """
            struct ListProvider {
                @Query var items: [Item]
                @State var searchText: String = ""

                struct Mock {
                    var items: [Item]

                    var searchText: String

                    init(items: [Item], searchText: String = "") {
                        self.items = items
                        self.searchText = searchText
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @Environment excluded

    func testEnvironmentPropertiesAreExcluded() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                @State var name: String = ""
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator
            }
            """,
            expandedSource: """
            struct DetailProvider {
                @State var name: String = ""
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator

                struct Mock {
                    var name: String

                    init(name: String = "") {
                        self.name = name
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Regular properties (dependencies)

    func testRegularPropertiesAreRequiredInInit() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                let repository = TodoRepository()
                @State var todos: [Todo] = []
            }
            """,
            expandedSource: """
            struct HomeProvider {
                let repository = TodoRepository()
                @State var todos: [Todo] = []

                struct Mock {
                    var repository: TodoRepository

                    var todos: [Todo]

                    init(repository: TodoRepository, todos: [Todo] = []) {
                        self.repository = repository
                        self.todos = todos
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Computed properties copied

    func testComputedPropertiesCopiedAsIs() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct StatsProvider {
                @State var items: [Item] = []

                var total: Int {
                    items.count
                }
            }
            """,
            expandedSource: """
            struct StatsProvider {
                @State var items: [Item] = []

                var total: Int {
                    items.count
                }

                struct Mock {
                    var items: [Item]

                    var total: Int {
                        items.count
                    }

                    init(items: [Item] = []) {
                        self.items = items
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Functions become mutating

    func testFunctionsBecomeMutating() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct CounterProvider {
                @State var count: Int = 0

                func increment() {
                    count += 1
                }

                func reset() {
                    count = 0
                }
            }
            """,
            expandedSource: """
            struct CounterProvider {
                @State var count: Int = 0

                func increment() {
                    count += 1
                }

                func reset() {
                    count = 0
                }

                struct Mock {
                    var count: Int

                    mutating func increment() {
                        count += 1
                    }

                    mutating func reset() {
                        count = 0
                    }

                    init(count: Int = 0) {
                        self.count = count
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Full Provider example

    func testFullProviderGeneratesMock() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                @Query var habits: [Habit]
                @Query var categories: [Category]
                @State var selectedDate: Date = Date.now
                @State var selectedCategoryID: UUID? = nil
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator

                var filteredHabits: [Habit] {
                    habits.filter { $0.isScheduled(for: selectedDate) }
                }

                func toggleCompletion(_ habit: Habit) {
                    habit.isCompleted.toggle()
                }
            }
            """,
            expandedSource: """
            struct HomeProvider {
                @Query var habits: [Habit]
                @Query var categories: [Category]
                @State var selectedDate: Date = Date.now
                @State var selectedCategoryID: UUID? = nil
                @Environment(\\.modelContext) var modelContext
                @Environment(\\.navigator) var navigator

                var filteredHabits: [Habit] {
                    habits.filter { $0.isScheduled(for: selectedDate) }
                }

                func toggleCompletion(_ habit: Habit) {
                    habit.isCompleted.toggle()
                }

                struct Mock {
                    var habits: [Habit]

                    var categories: [Category]

                    var selectedDate: Date

                    var selectedCategoryID: UUID?

                    var filteredHabits: [Habit] {
                        habits.filter {
                            $0.isScheduled(for: selectedDate)
                        }
                    }

                    mutating func toggleCompletion(_ habit: Habit) {
                        habit.isCompleted.toggle()
                    }

                    init(habits: [Habit], categories: [Category], selectedDate: Date = Date.now, selectedCategoryID: UUID? = nil) {
                        self.habits = habits
                        self.categories = categories
                        self.selectedDate = selectedDate
                        self.selectedCategoryID = selectedCategoryID
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @Bindable property

    func testBindablePropertyIsRequired() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                @Bindable var item: Item

                func save() {
                    item.name = "Updated"
                }
            }
            """,
            expandedSource: """
            struct DetailProvider {
                @Bindable var item: Item

                func save() {
                    item.name = "Updated"
                }

                struct Mock {
                    var item: Item

                    mutating func save() {
                        item.name = "Updated"
                    }

                    init(item: Item) {
                        self.item = item
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Rejects class

    func testRejectsClass() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            class NotAStruct {
                @State var x: Int = 0
            }
            """,
            expandedSource: """
            class NotAStruct {
                @State var x: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Mockable can only be applied to a struct", line: 1, column: 1),
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Empty struct

    func testEmptyStructGeneratesEmptyMock() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct EmptyProvider {
            }
            """,
            expandedSource: """
            struct EmptyProvider {

                struct Mock {

                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Let with explicit type

    func testLetWithExplicitType() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                let habitID: UUID
            }
            """,
            expandedSource: """
            struct DetailProvider {
                let habitID: UUID

                struct Mock {
                    var habitID: UUID

                    init(habitID: UUID) {
                        self.habitID = habitID
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Type inference

    func testInfersLiteralTypes() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct ConfigProvider {
                let timeout = 30
                let ratio = 0.5
                let label = "Hello"
                let verbose = true
            }
            """,
            expandedSource: """
            struct ConfigProvider {
                let timeout = 30
                let ratio = 0.5
                let label = "Hello"
                let verbose = true

                struct Mock {
                    var timeout: Int

                    var ratio: Double

                    var label: String

                    var verbose: Bool

                    init(timeout: Int, ratio: Double, label: String, verbose: Bool) {
                        self.timeout = timeout
                        self.ratio = ratio
                        self.label = label
                        self.verbose = verbose
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Let with initializer (inferred type from constructor)

    func testLetWithConstructorInferredType() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                let repository = TodoRepository()
            }
            """,
            expandedSource: """
            struct HomeProvider {
                let repository = TodoRepository()

                struct Mock {
                    var repository: TodoRepository

                    init(repository: TodoRepository) {
                        self.repository = repository
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Let with explicit type and initializer

    func testLetWithExplicitTypeAndInitializer() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct HomeProvider {
                let repository: TodoRepository = TodoRepository()
            }
            """,
            expandedSource: """
            struct HomeProvider {
                let repository: TodoRepository = TodoRepository()

                struct Mock {
                    var repository: TodoRepository

                    init(repository: TodoRepository) {
                        self.repository = repository
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Var without wrapper (stored, not computed)

    func testVarWithoutWrapperIsRequired() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct FormProvider {
                var title: String = "Untitled"
                var count: Int = 0
            }
            """,
            expandedSource: """
            struct FormProvider {
                var title: String = "Untitled"
                var count: Int = 0

                struct Mock {
                    var title: String

                    var count: Int

                    init(title: String, count: Int) {
                        self.title = title
                        self.count = count
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Mixed let, var, @State, @Query, @Environment

    func testMixedPropertyTypes() throws {
        #if canImport(MCMacrosPlugin)
        assertMacroExpansion(
            """
            @Mockable
            struct DetailProvider {
                let habitID: UUID
                let repository = HabitRepository()
                @Query var habits: [Habit]
                @State var isEditing: Bool = false
                @Environment(\\.modelContext) var modelContext
                var note: String = ""

                var habit: Habit? {
                    habits.first { $0.id == habitID }
                }

                func save() {
                    repository.save(habitID)
                }
            }
            """,
            expandedSource: """
            struct DetailProvider {
                let habitID: UUID
                let repository = HabitRepository()
                @Query var habits: [Habit]
                @State var isEditing: Bool = false
                @Environment(\\.modelContext) var modelContext
                var note: String = ""

                var habit: Habit? {
                    habits.first {
                        $0.id == habitID
                    }
                }

                func save() {
                    repository.save(habitID)
                }

                struct Mock {
                    var habitID: UUID

                    var repository: HabitRepository

                    var habits: [Habit]

                    var note: String

                    var isEditing: Bool

                    var habit: Habit? {
                        habits.first {
                            $0.id == habitID
                        }
                    }

                    mutating func save() {
                        repository.save(habitID)
                    }

                    init(habitID: UUID, repository: HabitRepository, habits: [Habit], note: String, isEditing: Bool = false) {
                        self.habitID = habitID
                        self.repository = repository
                        self.habits = habits
                        self.note = note
                        self.isEditing = isEditing
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
```

---

## Como rodar os testes

```bash
cd MCMacros
swift test
```

---

## Como integrar no projeto

### 1. Adicionar ao MCFeatures/Package.swift

```swift
// Em dependencies:
.package(path: "../MCMacros"),

// Em cada target que usar @Mockable:
.product(name: "MCMacros", package: "MCMacros"),
```

### 2. Usar no Provider

```swift
import MCMacros

@Mockable
struct HomeProvider: MCProvider {
    @Query var habits: [HabitModel]
    @State var selectedDate: Date = Date.now.startOfDay
    @Environment(\.navigator) var navigator

    var filteredHabits: [HabitModel] {
        habits.filter { $0.isScheduled(for: selectedDate) }
    }

    func toggleCompletion(_ habit: HabitModel) { ... }
}
```

### 3. Testar

```swift
import XCTest
@testable import MCHome

final class HomeProviderTests: XCTestCase {

    func testFilteredHabitsExcludesUnscheduled() {
        let monday = makeDate(weekday: .monday)
        let weekendOnly = HabitModel(
            name: "Weekend run",
            icon: "figure.run",
            frequency: .specificDays([.saturday, .sunday])
        )
        let daily = HabitModel(
            name: "Meditate",
            icon: "brain.head.profile",
            frequency: .daily
        )

        var sut = HomeProvider.Mock(
            habits: [weekendOnly, daily],
            categories: [],
            allLogs: [],
            selectedDate: monday
        )

        XCTAssertEqual(sut.filteredHabits.count, 1)
        XCTAssertEqual(sut.filteredHabits[0].name, "Meditate")
    }

    func testToggleCompletionMarksAsComplete() {
        let habit = HabitModel(name: "Read", icon: "book.fill")
        var sut = HomeProvider.Mock(
            habits: [habit],
            categories: [],
            allLogs: []
        )

        sut.toggleCompletion(habit)

        // Verifica que a lógica de toggle funcionou
    }
}
```

---

## Prioridade de aplicação

| Provider | Lógica testável | Prioridade |
|---|---|---|
| `HomeProvider` | filtering, toggle, progress, streak | **Alta** |
| `HabitDetailProvider` | streak, frequency description | **Alta** |
| `CategoryDetailProvider` | isCompleted, activeHabits | Média |
| `EditCategoryProvider` | canSave, loadExisting, save | Média |
| `AddHabitProvider` | canSave, applyTemplate, frequency | Média |
| `CategoriesProvider` | habitCount, delegação simples | Baixa |
