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
