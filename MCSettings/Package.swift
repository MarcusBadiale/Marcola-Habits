// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCSettings",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCSettingsAPI", targets: ["MCSettingsAPI"]),
        .library(name: "MCSettings", targets: ["MCSettings"]),
    ],
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
        .testTarget(
            name: "MCSettingsTests",
            dependencies: ["MCSettings"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
