// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCCategoriesAPI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCCategoriesAPI", targets: ["MCCategoriesAPI"]),
    ],
    targets: [
        .target(name: "MCCategoriesAPI"),
    ]
)
