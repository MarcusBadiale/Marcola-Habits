// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCStats",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCStatsAPI", targets: ["MCStatsAPI"]),
        .library(name: "MCStats", targets: ["MCStats"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(name: "MCStatsAPI"),
        .target(
            name: "MCStats",
            dependencies: [
                "MCStatsAPI",
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
