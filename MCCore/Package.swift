// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCNavigationAPI", targets: ["MCNavigationAPI"]),
        .library(name: "MCNavigation", targets: ["MCNavigation"]),
        .library(name: "MCDesignSystem", targets: ["MCDesignSystem"]),
    ],
    dependencies: [
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(
            name: "MCNavigationAPI",
            dependencies: [
                .product(name: "MCShared", package: "MCShared"),
            ]
        ),
        .target(
            name: "MCNavigation",
            dependencies: [
                "MCNavigationAPI",
                .product(name: "MCShared", package: "MCShared"),
            ]
        ),
        .target(
            name: "MCDesignSystem",
            dependencies: [
                .product(name: "MCShared", package: "MCShared"),
            ]
        ),
    ]
)
