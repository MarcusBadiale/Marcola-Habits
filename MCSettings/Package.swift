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
