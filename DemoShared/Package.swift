// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DemoShared",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "DemoShared", targets: ["DemoShared"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
        .package(path: "../MCInfrastructure"),
    ],
    targets: [
        .target(
            name: "DemoShared",
            dependencies: [
                .product(name: "MCNavigationAPI", package: "MCCore"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCShared", package: "MCShared"),
                .product(name: "MCSyncAPI", package: "MCInfrastructure"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
