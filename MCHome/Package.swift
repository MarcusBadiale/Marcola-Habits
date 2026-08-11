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
