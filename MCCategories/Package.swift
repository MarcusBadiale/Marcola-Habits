// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCCategories",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCCategoriesAPI", targets: ["MCCategoriesAPI"]),
        .library(name: "MCCategories", targets: ["MCCategories"]),
    ],
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
                .product(name: "MCHomeAPI", package: "MCHome"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCMacros", package: "MCShared"),
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
