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
