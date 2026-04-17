// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCFeatures",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCFeatures", targets: ["MCFeatures"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCDomain"),
        .package(path: "../MCInfrastructure"),
    ],
    targets: [
        .target(
            name: "MCFeatures",
            dependencies: [
                .product(name: "MCCore", package: "MCCore"),
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCInfrastructure", package: "MCInfrastructure"),
            ]
        ),
    ]
)
