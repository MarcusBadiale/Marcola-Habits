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
├── MCShared/                        ← utilities, DI container, extensions
│   └── Package.swift
├── MCDomain/                        ← models, DTOs, protocols, SwiftData
│   └── Package.swift
├── MCCore/                          ← NavigationAPI, Navigation, DesignSystem
│   └── Package.swift
├── MCInfrastructure/                ← Persistence, SyncAPI, Sync, Networking
│   └── Package.swift
│
│   ── Feature APIs (packages solo, zero dependências pesadas) ──
├── MCHomeAPI/
│   ├── Package.swift
│   └── Sources/MCHomeAPI/HomeRoutes.swift
├── MCCategoriesAPI/
│   ├── Package.swift
│   └── Sources/MCCategoriesAPI/CategoriesRoutes.swift
├── MCStatsAPI/
│   ├── Package.swift
│   └── Sources/MCStatsAPI/StatsRoutes.swift
├── MCSettingsAPI/
│   ├── Package.swift
│   └── Sources/MCSettingsAPI/SettingsRoutes.swift
│
│   ── Features (cada uma é um package independente) ──
├── MCHome/
│   ├── Package.swift
│   ├── Sources/MCHome/              ← implementação
│   ├── Tests/MCHomeTests/           ← unit tests
│   └── DemoApp/                     ← mini app dentro do package
│       ├── HomeDemoApp.xcodeproj    ← criado manualmente no Xcode, commitado
│       ├── Sources/
│       │   └── HomeDemoApp.swift
│       └── UITests/
│           └── HomeUITests.swift
│
├── MCCategories/                    ← mesma estrutura
├── MCStats/
├── MCSettings/
│
│   ── Demo infrastructure ──
└── DemoShared/
    ├── Package.swift
    └── Sources/DemoShared/
        ├── FakeNavigator.swift      ← implementa NavigatorAPI + RouteRegistryAPI
        ├── FakeSyncService.swift    ← implementa SyncServiceAPI
        ├── DemoDependencies.swift   ← registro de deps compartilhadas
        ├── DemoSeedData.swift       ← popula SwiftData com dados fake
        └── DemoRootView.swift       ← shell genérico com setup no task
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
    ├─ MCCategoriesAPI   ├─ MCHomeAPI        ├─ MCCore       ├─ MCSyncAPI
    ├─ MCCore            ├─ MCCore           ├─ MCDomain     ├─ MCCore
    ├─ MCDomain          ├─ MCDomain         └─ MCShared     ├─ MCDomain
    └─ MCShared          └─ MCShared                         └─ MCShared
```

**Nenhuma feature depende de outra feature.** Só de APIs.
MCHome e MCCategories podem depender de MCCategoriesAPI e MCHomeAPI
respectivamente, sem referência cruzada entre packages.

### Por que APIs em packages separados?

Se as APIs ficassem dentro dos packages de feature (ex: MCHomeAPI como target
dentro de MCHome), teríamos referência cruzada:
- MCHome (package) lista MCCategories (package) como dependency
- MCCategories (package) lista MCHome (package) como dependency

Mesmo que os **targets** não sejam circulares, os **packages** se referenciam
mutuamente e o SPM pode reclamar.

Com APIs em packages separados, não existe nenhuma referência cruzada.

---

## 4. Package.swift — APIs

Cada API é um package ultra-leve sem dependências:

### MCHomeAPI/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCHomeAPI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCHomeAPI", targets: ["MCHomeAPI"]),
    ],
    targets: [
        .target(name: "MCHomeAPI"),
    ]
)
```

### MCCategoriesAPI/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCCategoriesAPI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCCategoriesAPI", targets: ["MCCategoriesAPI"]),
    ],
    targets: [
        .target(name: "MCCategoriesAPI"),
    ]
)
```

MCStatsAPI e MCSettingsAPI seguem o mesmo padrão.

---

## 5. Package.swift — Features

### MCHome/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCHome",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCHome", targets: ["MCHome"]),
    ],
    dependencies: [
        .package(path: "../MCHomeAPI"),
        .package(path: "../MCCategoriesAPI"),
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(url: "https://github.com/MarcusBadiale/MarcolasPattern.git", exact: "1.2.3"),
    ],
    targets: [
        .target(
            name: "MCHome",
            dependencies: [
                .product(name: "MCHomeAPI", package: "MCHomeAPI"),
                .product(name: "MCCategoriesAPI", package: "MCCategoriesAPI"),
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
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

### MCCategories/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCCategories",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCCategories", targets: ["MCCategories"]),
    ],
    dependencies: [
        .package(path: "../MCCategoriesAPI"),
        .package(path: "../MCHomeAPI"),
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(url: "https://github.com/MarcusBadiale/MarcolasPattern.git", exact: "1.2.3"),
    ],
    targets: [
        .target(
            name: "MCCategories",
            dependencies: [
                .product(name: "MCCategoriesAPI", package: "MCCategoriesAPI"),
                .product(name: "MCHomeAPI", package: "MCHomeAPI"),
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),
        .testTarget(
            name: "MCCategoriesTests",
            dependencies: ["MCCategories"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
```

### MCStats/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCStats",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCStats", targets: ["MCStats"]),
    ],
    dependencies: [
        .package(path: "../MCStatsAPI"),
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(url: "https://github.com/MarcusBadiale/MarcolasPattern.git", exact: "1.2.3"),
    ],
    targets: [
        .target(
            name: "MCStats",
            dependencies: [
                .product(name: "MCStatsAPI", package: "MCStatsAPI"),
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),
        .testTarget(
            name: "MCStatsTests",
            dependencies: ["MCStats"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
```

### MCSettings/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCSettings",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCSettings", targets: ["MCSettings"]),
    ],
    dependencies: [
        .package(path: "../MCSettingsAPI"),
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(path: "../MCInfrastructure"),
        .package(url: "https://github.com/MarcusBadiale/MarcolasPattern.git", exact: "1.2.3"),
    ],
    targets: [
        .target(
            name: "MCSettings",
            dependencies: [
                .product(name: "MCSettingsAPI", package: "MCSettingsAPI"),
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCSyncAPI", package: "MCInfrastructure"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),
        .testTarget(
            name: "MCSettingsTests",
            dependencies: ["MCSettings"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
```

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

### DemoShared/Sources/DemoShared/DemoDependencies.swift

```swift
import MCDomain
import MCShared

/// Registra dependências compartilhadas entre todos os Demo Apps.
enum DemoDependencies {
    static func registerAll() {
        let container = DependencyContainer.shared

        container.register(StatsCalculatorAPI.self) {
            StatsCalculator()
        }
    }
}
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

### MCHome/DemoApp/Sources/HomeDemoApp.swift

```swift
import DemoShared
import MCHome
import MCHomeAPI
import MCDomain
import SwiftData
import SwiftUI

@main
struct HomeDemoApp: App {
    @State private var navigator = FakeNavigator()

    init() {
        DemoDependencies.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .today) { nav in
                HomeRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(Self.makeContainer())
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            DemoSeedData.populate(container.mainContext)
            return container
        } catch {
            fatalError("Failed to create demo container: \(error)")
        }
    }
}
```

### MCCategories/DemoApp/Sources/CategoriesDemoApp.swift

```swift
import DemoShared
import MCCategories
import MCCategoriesAPI
import MCDomain
import SwiftData
import SwiftUI

@main
struct CategoriesDemoApp: App {
    @State private var navigator = FakeNavigator()

    init() {
        DemoDependencies.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .categories) { nav in
                CategoriesRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(Self.makeContainer())
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            DemoSeedData.populate(container.mainContext)
            return container
        } catch {
            fatalError("Failed to create demo container: \(error)")
        }
    }
}
```

### MCStats/DemoApp/Sources/StatsDemoApp.swift

```swift
import DemoShared
import MCStats
import MCStatsAPI
import MCDomain
import SwiftData
import SwiftUI

@main
struct StatsDemoApp: App {
    @State private var navigator = FakeNavigator()

    init() {
        DemoDependencies.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .stats) { nav in
                StatsRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(Self.makeContainer())
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            DemoSeedData.populate(container.mainContext)
            return container
        } catch {
            fatalError("Failed to create demo container: \(error)")
        }
    }
}
```

### MCSettings/DemoApp/Sources/SettingsDemoApp.swift

```swift
import DemoShared
import MCSettings
import MCSettingsAPI
import MCSyncAPI
import MCDomain
import MCShared
import SwiftData
import SwiftUI

@main
struct SettingsDemoApp: App {
    @State private var navigator = FakeNavigator()

    init() {
        DemoDependencies.registerAll()
        DependencyContainer.shared.register(SyncServiceAPI.self) {
            FakeSyncService()
        }
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView(navigator: navigator, tab: .settings) { nav in
                SettingsRouteRegistry.register(in: nav)
            }
        }
        .modelContainer(Self.makeContainer())
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            CategoryModel.self, HabitModel.self,
            HabitLogModel.self, HabitTemplateModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create demo container: \(error)")
        }
    }
}
```

---

## 8. UI Tests

### Por que precisa de Demo App pra UI Tests?

Swift Packages não suportam UI tests nativamente. `XCUIApplication()` precisa
de um app host real (um `.app` bundle) pra ser lançado. O Demo App é esse host.

Unit tests rodam direto via `swift test` ou pelo scheme do package — sem problemas.
UI tests precisam do `.xcodeproj` com um app target + UI test target.

### MCHome/DemoApp/UITests/HomeUITests.swift

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

### MCCategories/DemoApp/UITests/CategoriesUITests.swift

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
- MCHome → MCHomeAPI, MCCategoriesAPI, MCDesignSystem, MCNavigationAPI, MCDomain, MCShared, MarcolasPattern
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
6. Arraste `MCHome/DemoApp/Sources/HomeDemoApp.swift` para o target
7. **Project → Package Dependencies → + → Add Local:**
   - Selecione `MCHome/` → adicione `MCHome` ao target
   - Selecione `MCHomeAPI/` → adicione `MCHomeAPI` ao target
   - Selecione `DemoShared/` → adicione `DemoShared` ao target
8. Build Settings: DEVELOPMENT_TEAM = `SJTT4SW9L7`, SWIFT_VERSION = `5.0`
9. **Cmd+B** — deve compilar
10. Para UI tests: **+** na lista de targets → UI Testing Bundle
    - Target to be Tested: `HomeDemoApp`
    - Delete boilerplate, arraste `UITests/HomeUITests.swift`
11. Commite o `.xcodeproj`

Repita para MCCategories, MCStats e MCSettings.

---

## 11. Migração do MCFeatures atual

### Mover sources

```bash
# APIs
mkdir -p MCHomeAPI/Sources/MCHomeAPI
mv MCFeatures/Sources/MCHomeAPI/* MCHomeAPI/Sources/MCHomeAPI/

mkdir -p MCCategoriesAPI/Sources/MCCategoriesAPI
mv MCFeatures/Sources/MCCategoriesAPI/* MCCategoriesAPI/Sources/MCCategoriesAPI/

mkdir -p MCStatsAPI/Sources/MCStatsAPI
mv MCFeatures/Sources/MCStatsAPI/* MCStatsAPI/Sources/MCStatsAPI/

mkdir -p MCSettingsAPI/Sources/MCSettingsAPI
mv MCFeatures/Sources/MCSettingsAPI/* MCSettingsAPI/Sources/MCSettingsAPI/

# Implementações
mkdir -p MCHome/Sources/MCHome MCHome/Tests/MCHomeTests
mv MCFeatures/Sources/MCHome/* MCHome/Sources/MCHome/

mkdir -p MCCategories/Sources/MCCategories MCCategories/Tests/MCCategoriesTests
mv MCFeatures/Sources/MCCategories/* MCCategories/Sources/MCCategories/

mkdir -p MCStats/Sources/MCStats MCStats/Tests/MCStatsTests
mv MCFeatures/Sources/MCStats/* MCStats/Sources/MCStats/

mkdir -p MCSettings/Sources/MCSettings MCSettings/Tests/MCSettingsTests
mv MCFeatures/Sources/MCSettings/* MCSettings/Sources/MCSettings/
```

### Atualizar workspace

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "group:MCHomeAPI" />
   <FileRef location = "group:MCCategoriesAPI" />
   <FileRef location = "group:MCStatsAPI" />
   <FileRef location = "group:MCSettingsAPI" />
   <FileRef location = "group:MCHome" />
   <FileRef location = "group:MCCategories" />
   <FileRef location = "group:MCStats" />
   <FileRef location = "group:MCSettings" />
   <FileRef location = "group:MCInfrastructure" />
   <FileRef location = "group:MCCore" />
   <FileRef location = "group:MCDomain" />
   <FileRef location = "group:MCShared" />
   <FileRef location = "group:DemoShared" />
   <FileRef location = "container:Marcola-Habits.xcodeproj" />
</Workspace>
```

### Atualizar xcodeproj principal

1. Remova referência ao package `MCFeatures`
2. Adicione local packages: MCHome, MCCategories, MCStats, MCSettings,
   MCHomeAPI, MCCategoriesAPI, MCStatsAPI, MCSettingsAPI
3. No target Marcola-Habits, frameworks: troque os products antigos

### Deletar MCFeatures

```bash
rm -rf MCFeatures/
```

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
# Cmd+U → todos os tests
```
