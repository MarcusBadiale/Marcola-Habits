// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCFeatures",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCHomeAPI", targets: ["MCHomeAPI"]),
        .library(name: "MCHome", targets: ["MCHome"]),
        .library(name: "MCCategoriesAPI", targets: ["MCCategoriesAPI"]),
        .library(name: "MCCategories", targets: ["MCCategories"]),
        .library(name: "MCStatsAPI", targets: ["MCStatsAPI"]),
        .library(name: "MCStats", targets: ["MCStats"]),
        .library(name: "MCSettingsAPI", targets: ["MCSettingsAPI"]),
        .library(name: "MCSettings", targets: ["MCSettings"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(path: "../MCInfrastructure"),
        .package(url: "https://github.com/MarcusBadiale/MarcolasPattern.git", exact: "1.2.3"),
    ],
    targets: [
        // MARK: - Home
        .target(name: "MCHomeAPI"),
        .target(
            name: "MCHome",
            dependencies: [
                "MCHomeAPI",
                "MCCategoriesAPI",
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),

        // MARK: - Categories
        .target(name: "MCCategoriesAPI"),
        .target(
            name: "MCCategories",
            dependencies: [
                "MCCategoriesAPI",
                "MCHomeAPI",
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),

        // MARK: - Stats
        .target(name: "MCStatsAPI"),
        .target(
            name: "MCStats",
            dependencies: [
                "MCStatsAPI",
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),

        // MARK: - Settings
        .target(name: "MCSettingsAPI"),
        .target(
            name: "MCSettings",
            dependencies: [
                "MCSettingsAPI",
                .product(name: "MarcolasPattern", package: "MarcolasPattern"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCSyncAPI", package: "MCInfrastructure"),
                .product(name: "MCDesignSystem", package: "MCCore"),
                .product(name: "MCNavigationAPI", package: "MCCore"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
