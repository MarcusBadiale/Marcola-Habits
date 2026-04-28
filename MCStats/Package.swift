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
