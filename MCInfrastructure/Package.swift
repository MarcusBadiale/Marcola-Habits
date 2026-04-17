// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCInfrastructure",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCInfrastructure", targets: ["MCInfrastructure"]),
    ],
    dependencies: [
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(
            name: "MCInfrastructure",
            dependencies: [
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCShared", package: "MCShared"),
            ]
        ),
    ]
)
