# Marcola Habits — Arquitetura Modular com Mini Apps

Guia completo de como modularizar o projeto seguindo o padrão Spotify
(slides "Preparing for Growth" do Bruno Rocha), com package por feature,
APIs separadas, demo apps isolados e UI tests por módulo — sem Tuist.

---

## 1. O Padrão Spotify

### Níveis de evolução (dos slides)

- **Level 1:** Monolith — tudo num módulo, MVC, sem testes.
- **Level 2:** Monolith melhor — protocolos, composição, unit tests, mas tudo junto.
- **Level 3:** Modularizado — features em módulos, mas build lento porque módulos dependem de implementações concretas uns dos outros.
- **Level 4:** API + Implementação — cada feature é dividida em `FeatureAPI` (protocolos, modelos públicos) e `Feature` (implementação). Features dependem só de APIs de outras features, nunca da implementação.
- **Level 5:** DI dinâmico com ServiceOrchestrator — serviços organizados como DAG com scopes (LaunchScope, LoggedInScope, etc). Lazy loading, ativação/desativação de scopes.

### Mini Apps (slide chave)

No padrão Spotify, cada feature tem um **Demo App** (mini app) que contém:

- **FeatureAAPI** — a API da feature sendo testada
- **FeatureA** — a implementação da feature sendo testada
- **FeatureBAPI** — APIs de outras features que A depende (só protocolos/rotas)
- **FakeFeatureB** — mocks/fakes das implementações de outras features

**Regra fundamental: o Demo App NUNCA importa a implementação de outra feature.**

Se FeatureA depende de FeatureBAPI, o demo app fornece um `FakeFeatureB` que
satisfaz a API. Isso garante isolamento total e build rápido.

---

## 2. Estrutura Final do Projeto

```
Marcola-Habits/
├── Marcola-Habits.xcodeproj        ← app principal
├── Marcola-Habits.xcworkspace      ← workspace com tudo
│
│   ── Foundation ──────────────────────────────
├── MCShared/                        ← MCProvider, Provider<T>, @Mockable, extensions
│   └── Package.swift                   (targets: MCShared, MCMacros, MCMacrosPlugin)
├── MCDomain/                        ← models, DTOs, protocols, SwiftData, EnvironmentKeys
│   └── Package.swift
├── MCCore/                          ← NavigationAPI, Navigation, DesignSystem
│   └── Package.swift
├── MCInfrastructure/                ← Persistence, SyncAPI, Sync, Networking
│   └── Package.swift
│
│   ── Features (API + Impl como targets do mesmo package) ──
├── MCHome/
│   ├── Package.swift                ← expõe MCHomeAPI e MCHome
│   ├── Sources/MCHomeAPI/           ← [API] HomeRoutes (zero dependências)
│   ├── Sources/MCHome/              ← [IMPL] views, providers, route registry
│   ├── Tests/MCHomeTests/           ← unit tests (+ Helpers/SpyNavigator, TestHelpers)
│   └── DemoApp/                     ← mini app dentro do package
│       ├── HomeDemoApp.xcodeproj    ← criado manualmente no Xcode, commitado
│       ├── HomeDemoApp/
│       │   └── HomeDemoApp.swift
│       └── HomeDemoAppUITests/
│           ├── HomeDemoAppUITests.swift
│           └── Pages/               ← HomePage, AddHabitPage, HabitDetailPage
│
├── MCCategories/                    ← mesma estrutura
├── MCStats/
├── MCSettings/
│
│   ── Demo infrastructure ──
├── DemoShared/
│   ├── Package.swift
│   └── Sources/DemoShared/
│       ├── FakeNavigator.swift      ← implementa NavigatorAPI + RouteRegistryAPI
│       ├── FakeSyncService.swift    ← implementa SyncServiceAPI
│       ├── DemoSeedData.swift       ← popula SwiftData com dados fake
│       └── DemoRootView.swift       ← shell genérico com setup no task
│
│   ── Test plans ──
├── AllUnitTests.xctestplan          ← agrega os testTargets dos packages
└── AllUITests.xctestplan            ← agrega os UI tests dos 4 Demo Apps
```

---

## 3. Grafo de Dependências

```
MCHomeAPI          MCCategoriesAPI      MCStatsAPI      MCSettingsAPI
(zero deps)        (zero deps)          (zero deps)     (zero deps)
    │                    │                   │               │
    ▼                    ▼                   ▼               ▼
 MCHome              MCCategories         MCStats        MCSettings
    │                    │                   │               │
    ├─ MCHomeAPI         ├─ MCCategoriesAPI  ├─ MCStatsAPI   ├─ MCSettingsAPI
    ├─ MCCore            ├─ MCHomeAPI        ├─ MCCore       ├─ MCSyncAPI
    ├─ MCDomain          ├─ MCCore           ├─ MCDomain     ├─ MCCore
    ├─ MCShared          ├─ MCDomain         └─ MCShared     ├─ MCDomain
    └─ MCMacros          ├─ MCShared                         └─ MCShared
                         └─ MCMacros
```

**Nenhuma feature depende da implementação de outra feature.** Só de APIs.
MCCategories depende de MCHomeAPI (pra navegar pro detalhe de hábito) sem nunca
importar MCHome.

MCStats e MCSettings não puxam MCMacros porque ainda não têm provider.

### Onde ficam as APIs: targets, não packages

O desenho inicial deste guia colocava cada API num **package solo** (`MCHomeAPI/Package.swift`),
pra evitar que dois packages de feature se referenciassem mutuamente. Na prática isso virou
4 Package.swift extras pra 4 arquivos de constantes.

A decisão final foi consolidar: cada feature tem **um** Package.swift que expõe dois targets,
`FeatureAPI` e `Feature`.

```swift
// MCHome/Package.swift
products: [
    .library(name: "MCHomeAPI", targets: ["MCHomeAPI"]),
    .library(name: "MCHome", targets: ["MCHome"]),
],
targets: [
    .target(name: "MCHomeAPI"),          // zero dependências
    .target(name: "MCHome", dependencies: ["MCHomeAPI", ...]),
]
```

O risco original — referência cruzada entre packages — não se materializou. `MCCategories`
lista `.package(path: "../MCHome")` e consome só o produto `MCHomeAPI`; o SPM resolve sem
reclamar porque o grafo de **targets** não é circular (`MCCategories → MCHomeAPI`, e
`MCHomeAPI` não depende de nada).

O limite: se algum dia MCHome precisar de `MCCategoriesAPI` **e** MCCategories continuar
precisando de `MCHomeAPI`, os dois packages se referenciam mutuamente. Aí, ou o SPM aceita
(targets seguem acíclicos), ou a saída é extrair as route keys pra um package comum — não
voltar aos 4 packages solo.

Ganhos da consolidação:
- 4 Package.swift a menos, 4 entradas a menos no workspace
- `Package.resolved` único por feature
- API e Impl versionam juntos, que é como eles mudam na prática

---

## 4. Package.swift — Features (API + Impl)

Cada feature tem um Package.swift que expõe os dois targets. O target API não tem
dependência nenhuma.

### MCHome/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCHome",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCHomeAPI", targets: ["MCHomeAPI"]),
        .library(name: "MCHome", targets: ["MCHome"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(name: "MCHomeAPI"),
        .target(
            name: "MCHome",
            dependencies: [
                "MCHomeAPI",
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCMacros", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),
        .testTarget(
            name: "MCHomeTests",
            dependencies: ["MCHome"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
```

`MCMacros` (produto do package MCShared) é o que habilita `@Mockable` nos providers.
Feature sem provider não precisa dele.

### MCCategories/Package.swift

Igual, mais `../MCHome` pra consumir `MCHomeAPI`:

```swift
    dependencies: [
        .package(path: "../MCHome"),
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(name: "MCCategoriesAPI"),
        .target(
            name: "MCCategories",
            dependencies: [
                "MCCategoriesAPI",
                .product(name: "MCHomeAPI", package: "MCHome"),   // só a API
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCMacros", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),
        .testTarget(name: "MCCategoriesTests", dependencies: ["MCCategories"]),
    ],
```

### MCStats/Package.swift

Igual ao MCHome, sem `MCMacros` (ainda não tem provider).

### MCSettings/Package.swift

Igual, mais `../MCInfrastructure` pra consumir `MCSyncAPI`:

```swift
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(path: "../MCInfrastructure"),
    ],
    targets: [
        .target(name: "MCSettingsAPI"),
        .target(
            name: "MCSettings",
            dependencies: [
                "MCSettingsAPI",
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCSyncAPI", package: "MCInfrastructure"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),
        .testTarget(name: "MCSettingsTests", dependencies: ["MCSettings"]),
    ],
```

### MCShared/Package.swift — o package do macro

MCShared é o único com dependência externa (swift-syntax), por causa do `@Mockable`:

```swift
    products: [
        .library(name: "MCShared", targets: ["MCShared"]),
        .library(name: "MCMacros", targets: ["MCMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(name: "MCShared"),
        .macro(
            name: "MCMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .target(name: "MCMacros", dependencies: ["MCMacrosPlugin"]),
        .testTarget(name: "MCSharedTests", dependencies: ["MCShared"]),
        .testTarget(name: "MCMacrosTests", dependencies: [...]),
    ]
```

`MCMacrosPlugin` é um `.macro` target (roda no host, em build time). `MCMacros` é o que as
features importam. Ver MOCKABLE_IMPLEMENTATION.md pro detalhe do macro.

---

## 6. DemoShared — Fakes Compartilhados

### DemoShared/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DemoShared",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "DemoShared", targets: ["DemoShared"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(path: "../MCInfrastructure"),
    ],
    targets: [
        .target(
            name: "DemoShared",
            dependencies: [
                .product(name: "MCNavigationAPI", package: "MCCore"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCSyncAPI", package: "MCInfrastructure"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
```

### DemoShared/Sources/DemoShared/FakeNavigator.swift

```swift
import MCNavigationAPI
import SwiftUI

/// Implementação fake do NavigatorAPI + RouteRegistryAPI para Demo Apps.
///
/// No padrão Spotify, o Demo App nunca importa a implementação real
/// (MCNavigation). Este fake substitui ela.
///
/// O FakeNavigator resolve rotas registradas e mantém um NavigationPath
/// real, então a navegação INTERNA da feature funciona no demo app.
/// Rotas não-registradas (de outras features) mostram um placeholder.
@Observable
public final class FakeNavigator: NavigatorAPI, RouteRegistryAPI {

    // MARK: - Route resolution

    private var factories: [String: @MainActor @Sendable (RouteParams) -> AnyView] = [:]
    private var rootFactories: [TabID: @MainActor @Sendable () -> AnyView] = [:]

    // MARK: - Navigation state

    public var path: [RouteEntry] = []
    public var presentedEntry: RouteEntry?

    public struct RouteEntry: Identifiable, Hashable {
        public let id = UUID()
        public let route: String
        public let params: RouteParams

        public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
        public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    public init() {}

    // MARK: - RouteRegistryAPI

    public func register(_ route: String, factory: @escaping @MainActor @Sendable (RouteParams) -> AnyView) {
        factories[route] = factory
    }

    public func registerRoot(for tab: TabID, factory: @escaping @MainActor @Sendable () -> AnyView) {
        rootFactories[tab] = factory
    }

    // MARK: - NavigatorAPI

    public func push(_ route: String, params: RouteParams) {
        path.append(RouteEntry(route: route, params: params))
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path = []
    }

    public func present(_ route: String, params: RouteParams) {
        presentedEntry = RouteEntry(route: route, params: params)
    }

    public func dismiss() {
        presentedEntry = nil
    }

    // MARK: - View resolution

    @MainActor @ViewBuilder
    public func rootView(for tab: TabID) -> some View {
        if let factory = rootFactories[tab] {
            factory()
        } else {
            fakePlaceholder("Root not registered for tab: \(tab.rawValue)")
        }
    }

    @MainActor @ViewBuilder
    public func view(for entry: RouteEntry) -> some View {
        if let factory = factories[entry.route] {
            factory(entry.params)
        } else {
            fakePlaceholder("Route not registered: \(entry.route)\nParams: \(entry.params)")
        }
    }

    @MainActor
    private func fakePlaceholder(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Fake Route")
    }
}
```

### DemoShared/Sources/DemoShared/FakeSyncService.swift

```swift
import Foundation
import MCSyncAPI

/// Fake do SyncServiceAPI para Demo Apps.
/// MCSettings depende de MCSyncAPI — este fake evita importar MCSync.
public final class FakeSyncService: SyncServiceAPI, @unchecked Sendable {
    public init() {}
    public func syncAll() async throws {}
    public func pushPendingChanges() async throws {}
    public func pullRemoteChanges() async throws {}
    public var isSyncing: Bool { false }
    public var lastSyncDate: Date? { nil }
}
```

### ~~DemoShared/Sources/DemoShared/DemoDependencies.swift~~ (removido)

Existiu pra registrar `StatsCalculatorAPI` no `DependencyContainer`. Com a DI por
`EnvironmentKey` (default real dentro do próprio MCDomain), não há nada pra registrar — o
arquivo foi deletado e cada Demo App só sobrescreve o que quer:

```swift
.environment(\.syncService, FakeSyncService())
```

### DemoShared/Sources/DemoShared/DemoSeedData.swift

```swift
import MCDomain
import MCShared
import SwiftData
import Foundation

/// Popula o banco in-memory com dados de exemplo para os Demo Apps.
@MainActor
enum DemoSeedData {

    static func populate(_ context: ModelContext) {
        SeedDataProvider.populate(context)

        let categories = (try? context.fetch(FetchDescriptor<CategoryModel>())) ?? []
        let saude = categories.first { $0.name == "Saúde" }
        let produtividade = categories.first { $0.name == "Produtividade" }
        let bemestar = categories.first { $0.name == "Bem-estar" }

        let habits: [HabitModel] = [
            HabitModel(
                name: "Beber água", icon: "drop.fill", colorHex: "#3B82F6",
                frequency: .daily, targetCount: 8, targetUnit: "copos",
                routine: .anytime, category: saude
            ),
            HabitModel(
                name: "Meditar", icon: "brain.head.profile", colorHex: "#22C55E",
                frequency: .daily, targetCount: 1, targetUnit: "sessão",
                routine: .morning, category: bemestar
            ),
            HabitModel(
                name: "Exercício", icon: "figure.run", colorHex: "#EF4444",
                frequency: .specificDays([.monday, .wednesday, .friday]),
                targetCount: 1, targetUnit: "treino",
                routine: .morning, category: saude
            ),
            HabitModel(
                name: "Sem redes sociais", icon: "iphone.slash", colorHex: "#A855F7",
                frequency: .daily, targetCount: 1, targetUnit: "dia",
                routine: .anytime, category: produtividade
            ),
        ]

        habits.forEach { context.insert($0) }

        let calendar = Calendar.current
        for daysAgo in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            for (index, habit) in habits.enumerated() {
                guard habit.isScheduled(for: date) else { continue }
                let shouldComplete = (index + daysAgo) % 3 != 0
                let log = HabitLogModel(
                    date: date,
                    completed: shouldComplete,
                    count: shouldComplete ? habit.targetCount : 0,
                    habit: habit
                )
                context.insert(log)
            }
        }

        try? context.save()
    }
}
```

### DemoShared/Sources/DemoShared/DemoRootView.swift

```swift
import MCNavigationAPI
import SwiftUI

/// Shell genérico que todos os Demo Apps usam como root.
///
/// Faz o setup (registro de rotas) no `task` antes de mostrar a feature.
/// Isso garante que `FakeNavigator.rootView(for:)` já tem a factory
/// registrada quando o body é avaliado pela primeira vez.
struct DemoRootView: View {
    let navigator: FakeNavigator
    let tab: TabID
    let registerRoutes: (FakeNavigator) -> Void

    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                NavigationStack(path: $navigator.path) {
                    navigator.rootView(for: tab)
                        .navigationDestination(for: FakeNavigator.RouteEntry.self) { entry in
                            navigator.view(for: entry)
                        }
                }
                .sheet(item: $navigator.presentedEntry) { entry in
                    navigator.view(for: entry)
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .environment(\.navigator, navigator)
        .task {
            registerRoutes(navigator)
            isReady = true
        }
    }
}
```

---

## 7. Demo Apps

### O que cada Demo App importa (padrão Spotify)

| Demo App           | Feature (impl)  | API própria      | APIs de outras features | Fakes           |
|--------------------|------------------|------------------|-------------------------|-----------------|
| HomeDemoApp        | MCHome           | MCHomeAPI        | MCCategoriesAPI         | FakeNavigator   |
| CategoriesDemoApp  | MCCategories     | MCCategoriesAPI  | MCHomeAPI               | FakeNavigator   |
| StatsDemoApp       | MCStats          | MCStatsAPI       | —                       | FakeNavigator   |
| SettingsDemoApp    | MCSettings       | MCSettingsAPI    | —                       | FakeNavigator, FakeSyncService |

Todos importam também: MCDomain, MCShared, MCDesignSystem (transitivamente).

**Nenhum demo app importa:** MCNavigation, MCCategories (no HomeDemoApp),
MCHome (no CategoriesDemoApp), MCSync, MCPersistence, MCNetworking.

### MCHome/DemoApp/HomeDemoApp/HomeDemoApp.swift

```swift
import DemoShared
import MCHome
import MCHomeAPI
import MCNavigationAPI
import SwiftData
import SwiftUI

@main
struct HomeDemoApp: App {
    @State private var navigator = FakeNavigator()

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .today) { nav in
                HomeRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(DemoSeedData.makeContainer())
    }
}
```

É só isso. Sem `init()`, sem registro de dependências: o `DemoRootView` injeta
`\.navigator` internamente, e os defaults dos `EnvironmentKey` cobrem stats e sync.
`DemoSeedData.makeContainer()` monta o container in-memory já populado.

### MCCategories/DemoApp/CategoriesDemoApp/CategoriesDemoAppApp.swift

Idem, com `tab: .categories` e `CategoriesRouteRegistry`. Também importa `MCHomeAPI`, porque
Categories navega pro detalhe de hábito — e no demo essa rota não está registrada, então o
`FakeNavigator` cai no fallback de "rota não encontrada" em vez de crashar.

### MCStats/DemoApp/StatsDemoApp/StatsDemoAppApp.swift

Idem, com `tab: .stats` e `StatsRouteRegistry`.

### MCSettings/DemoApp/SettingsDemoApp/SettingsDemoAppApp.swift

Idem, com `tab: .settings` e `SettingsRouteRegistry`. Este sobrescreve o sync com o fake:

```swift
DemoRootView(navigator: navigator, tab: .settings) { nav in
    SettingsRouteRegistry.register(in: nav)
}
.environment(\.syncService, FakeSyncService())
```

## 8. UI Tests

### Por que precisa de Demo App pra UI Tests?

Swift Packages não suportam UI tests nativamente. `XCUIApplication()` precisa
de um app host real (um `.app` bundle) pra ser lançado. O Demo App é esse host.

Unit tests rodam direto via `swift test` ou pelo scheme do package — sem problemas.
UI tests precisam do `.xcodeproj` com um app target + UI test target.

### MCHome/DemoApp/HomeDemoAppUITests/

```swift
import XCTest

final class HomeUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    @MainActor
    func testHomeScreenShowsTitle() throws {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDateCarouselExists() throws {
        let carousel = app.otherElements["home-date-carousel"]
        XCTAssertTrue(carousel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testHabitCardsAreVisible() throws {
        let firstCard = app.otherElements["home-habit-card-0"].firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddButtonExists() throws {
        let addButton = app.buttons["home-add-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddHabitSheetOpensAndCloses() throws {
        app.buttons["home-add-button"].tap()
        XCTAssertTrue(app.navigationBars["New habit"].waitForExistence(timeout: 3))
        app.buttons["add-habit-cancel-button"].tap()
        XCTAssertFalse(app.navigationBars["New habit"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testAddHabitSaveDisabledWithEmptyName() throws {
        app.buttons["home-add-button"].tap()
        XCTAssertTrue(app.navigationBars["New habit"].waitForExistence(timeout: 3))
        let saveButton = app.buttons["add-habit-save-button"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)
    }

    @MainActor
    func testCategoryChipFiltersHabits() throws {
        let firstChip = app.otherElements["home-category-chip-0"].firstMatch
        guard firstChip.waitForExistence(timeout: 5) else { return }
        firstChip.tap()
        let allChip = app.otherElements["home-category-all"].firstMatch
        XCTAssertTrue(allChip.waitForExistence(timeout: 3))
        allChip.tap()
    }
}
```

### MCCategories/DemoApp/CategoriesDemoAppUITests/

```swift
import XCTest

final class CategoriesUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    @MainActor
    func testCategoriesScreenShowsTitle() throws {
        XCTAssertTrue(app.navigationBars["Categories"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeedCategoriesAreVisible() throws {
        let firstRow = app.otherElements["categories-row-0"].firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddCategorySheetOpensAndCloses() throws {
        app.buttons["categories-add-button"].tap()
        XCTAssertTrue(app.navigationBars["New category"].waitForExistence(timeout: 3))
        app.buttons["edit-category-cancel-button"].tap()
        XCTAssertFalse(app.navigationBars["New category"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testAddCategoryWithNameEnablesSave() throws {
        app.buttons["categories-add-button"].tap()
        XCTAssertTrue(app.navigationBars["New category"].waitForExistence(timeout: 3))
        let nameField = app.textFields["edit-category-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test Category")
        let saveButton = app.buttons["edit-category-save-button"]
        XCTAssertTrue(saveButton.isEnabled)
    }

    @MainActor
    func testTapCategoryNavigatesToDetail() throws {
        let firstRow = app.otherElements["categories-row-0"].firstMatch
        guard firstRow.waitForExistence(timeout: 5) else { return }
        firstRow.tap()
        let editButton = app.buttons["category-detail-edit-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
    }
}
```

---

## 9. O que o Demo App compila (e o que não compila)

Quando você dá Cmd+R no HomeDemoApp, o Xcode resolve o grafo transitivo completo:

**Compila:**
- HomeDemoApp (target do app)
- MCHome → MCHomeAPI, MCDesignSystem, MCNavigationAPI, MCDomain, MCShared, MCMacros (+ swift-syntax em build time)
- DemoShared → MCNavigationAPI, MCDomain, MCShared, MCSyncAPI

**Não compila:**
- MCNavigation (implementação real do navigator)
- MCCategories, MCStats, MCSettings (outras features)
- MCSync, MCPersistence, MCNetworking (implementações de infra)

DemoShared arrasta MCSyncAPI mesmo que o HomeDemoApp não precise, porque o
FakeSyncService está lá dentro. O custo é desprezível (MCSyncAPI é um protocolo).
Se um dia incomodar, dá pra quebrar DemoShared em sub-módulos.

---

## 10. Como criar o .xcodeproj do Demo App (manual, uma vez)

### HomeDemoApp

1. **File → New → Project → App (iOS)**
2. Product Name: `HomeDemoApp`
3. Bundle ID: `com.marcola.HomeDemoApp`
4. **Salve dentro de `MCHome/DemoApp/`**
5. Delete o boilerplate gerado (ContentView.swift, App.swift, Assets, Preview Content)
6. Arraste `MCHome/DemoApp/HomeDemoApp/HomeDemoApp.swift` para o target
7. **Project → Package Dependencies → + → Add Local:**
   - Selecione `MCHome/` → adicione **MCHome e MCHomeAPI** ao target
     (os dois produtos vêm do mesmo package agora)
   - Selecione `DemoShared/` → adicione `DemoShared` ao target
8. Build Settings: DEVELOPMENT_TEAM = `SJTT4SW9L7`, SWIFT_VERSION = `5.0`
9. **Cmd+B** — deve compilar
10. Para UI tests: **+** na lista de targets → UI Testing Bundle
    - Target to be Tested: `HomeDemoApp`
    - Delete boilerplate, adicione `HomeDemoAppUITests.swift` e a pasta `Pages/`
11. Commite o `.xcodeproj`
12. Adicione o target de UI test ao `AllUITests.xctestplan`

Repita para MCCategories, MCStats e MCSettings. Os 4 já estão criados e commitados.

---

## 11. Migração do MCFeatures — concluída

O package monolítico `MCFeatures` foi desmembrado e deletado. Registro do que foi feito, caso
seja útil como referência pra uma próxima quebra de módulo:

1. **Sources** movidos de `MCFeatures/Sources/<Target>/` pra `<Feature>/Sources/<Target>/`,
   com API e Impl no mesmo package (`MCHome/Sources/MCHomeAPI/` + `MCHome/Sources/MCHome/`).
2. **Package.swift** criado por feature, expondo os dois produtos (ver seção 4).
3. **Workspace** atualizado: `MCFeatures` fora, os 4 packages de feature e `DemoShared` dentro.
4. **xcodeproj principal**: referência ao package `MCFeatures` removida, dependências trocadas
   pelos produtos dos novos packages.
5. **MCFeatures/ deletado.**

Depois disso, os 4 packages solo de API (`MCHomeAPI/`, `MCCategoriesAPI/`, `MCStatsAPI/`,
`MCSettingsAPI/`) também foram absorvidos como targets — ver seção 3.

---

## 12. Workflow Diário

```bash
# Desenvolver a Home isoladamente (build rápido):
open MCHome/DemoApp/HomeDemoApp.xcodeproj
# Cmd+R → roda mini app com dados fake
# Cmd+U → roda UI tests da Home

# Rodar unit tests de um package:
cd MCHome && swift test

# Rodar o app completo:
open Marcola-Habits.xcworkspace
# Cmd+R → app inteiro
# Cmd+U → test plan ativo (AllUnitTests por padrão)
```

Pelo terminal, com os test plans:

```bash
# Todos os testes unitários (todos os packages)
xcodebuild test -scheme Marcola-Habits -testPlan AllUnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Todos os testes de UI (os 4 Demo Apps)
xcodebuild test -scheme Marcola-Habits -testPlan AllUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
